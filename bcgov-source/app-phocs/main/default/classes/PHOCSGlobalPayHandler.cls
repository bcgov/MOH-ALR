public with sharing class PHOCSGlobalPayHandler {
    private static PHOCSGlobalPayEndpoints__mdt globalPaySetting = PHOCSGlobalPayEndpoints__mdt.getInstance('Default');
    private static String AccessTokenEndpointUrl {
        get { return globalPaySetting.BaseEndpoint__c + globalPaySetting.AccssTokenEndpoint__c; }
    }
    private static String PaymentLinkEndpointUrl {
        get { return globalPaySetting.BaseEndpoint__c + globalPaySetting.PaymentLinkEndpoint__c; }
    }
    private static String GlobalPayRedirectUrl {
        get { return  getPHOCSSiteDomain() + globalPaySetting.PaymentReturnEndpoint__c; }
    }
    private static String GlobalPayStatusUrl {
        get { return  getPHOCSSiteDomain() + globalPaySetting.PaymentStatusEndpoint__c; }
    }
    
    @AuraEnabled
    public static String getPaymentLinkUrl(Id regulatoryTransactionFeeId) {
        if (string.isBlank(regulatoryTransactionFeeId)) return null;

        AppConfig appConfig = getAccessToken(regulatoryTransactionFeeId);
        if (String.isBlank(appConfig.onetimeAccessToken)) return null;

        NewGlobalPayLinkResponse linkResp = createHostedPaymentLink(regulatoryTransactionFeeId, appConfig);
        if(string.isNotBlank(linkResp?.url)){
            RegulatoryTrxnFee regulatoryTrxnFeeRec =[select GlobalPayPaymentLink__c,GlobalPayPaymentLinkId__c From RegulatoryTrxnFee where Id=:regulatoryTransactionFeeId limit 1];
            regulatoryTrxnFeeRec.GlobalPayPaymentLinkId__c = linkResp.id;
            regulatoryTrxnFeeRec.GlobalPayPaymentLink__c = linkResp.url;
            update regulatoryTrxnFeeRec;
        }
        return linkResp != null ? linkResp.url : null;
    }
    
    @AuraEnabled
    public static void updatePaymentStatus(Id regulatoryTransactionFeeId) {
        if (string.isNotBlank(regulatoryTransactionFeeId)){
            AppConfig appConfig = getAccessToken(regulatoryTransactionFeeId);           
            if (String.isNotBlank(appConfig.onetimeAccessToken)){         
                RegulatoryTrxnFee regulatoryTrxnFeeRec =[select GlobalPayPaymentLink__c,
                                                                GlobalPayPaymentLinkId__c,
                                                                GlobalPayPaymentStatus__c
                                                         From RegulatoryTrxnFee 
                                                         where Id=:regulatoryTransactionFeeId limit 1];
                
                GlobalPayLinkDetailsResponse linkResp = getPaymentLinkStatus(regulatoryTrxnFeeRec, appConfig);
                if(linkResp.transactions != null && linkResp.transactions.transaction_list != null && !linkResp.transactions.transaction_list.isEmpty()){
                    linkResp.transactions.transaction_list.sort();
                    regulatoryTrxnFeeRec.ReferenceNumber__c = linkResp.transactions.transaction_list[0].id;
                    regulatoryTrxnFeeRec.GlobalPayPaymentStatus__c = linkResp.transactions.transaction_list[0].status;
                    update regulatoryTrxnFeeRec;
                }
            }
        }
    }
    
    private static AppConfig getGlobalPayAppConfig(Id regulatoryTransactionFeeId){
        string healthAuth = getHealthAuthority(regulatoryTransactionFeeId);
        if(string.isNotBlank(healthAuth)){
            PHOCSHealthAuthorityPaymentSetting__mdt config = [SELECT Id, PaymentSystem__c, HealthAuthority__c,AppId__c,AppKey__c,MerchantId__c
                                                                        FROM PHOCSHealthAuthorityPaymentSetting__mdt 
                                                                        WHERE HealthAuthority__c = :healthAuth LIMIT 1];
            if(config != null){                                                   
                AppConfig accessTokenRequestBody = new AppConfig();
                accessTokenRequestBody.appId = config.AppId__c;
                accessTokenRequestBody.appToken = config.AppKey__c;
                accessTokenRequestBody.merchantId = config.MerchantId__c;
                accessTokenRequestBody.nonce = Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
                accessTokenRequestBody.secret = getAppSecret(accessTokenRequestBody.nonce,config.AppKey__c);
                return accessTokenRequestBody;
            }
        }
        return null;
    }

    private static string getAppSecret(string nonce, string appToken) {
        Blob dataToHashBlob = Blob.valueOf(nonce + appToken);
        Blob sha512Hash = Crypto.generateDigest('SHA-512', dataToHashBlob);
        return EncodingUtil.convertToHex(sha512Hash);
    }

    private static string getHealthAuthority(Id regulatoryTransactionFeeId) {
        string healthAuth = '';        
        if(string.isNotBlank(regulatoryTransactionFeeId)){
            RegulatoryTrxnFee[] regulatoryTrxnFees = [select Id, Account.HealthAuthority__c from RegulatoryTrxnFee where Id=:regulatoryTransactionFeeId];
            if(regulatoryTrxnFees != null && !regulatoryTrxnFees.isEmpty()){
               return regulatoryTrxnFees[0].Account?.HealthAuthority__c;
            }
        }
        return healthAuth;
    }
    
    private static String getPHOCSSiteDomain() {
        DomainSite ds = [
            SELECT Domain.Domain
            FROM DomainSite
            WHERE Site.Name = 'phocsportal'
            LIMIT 1
        ];
        return 'https://' + ds?.Domain?.Domain;
    }
   
    private static AppConfig getAccessToken(Id regulatoryTransactionFeeId) {        
        AppConfig appConfig = getGlobalPayAppConfig(regulatoryTransactionFeeId);
        if(appConfig == null) return null;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(AccessTokenEndpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-GP-Version', '2021-03-22');

        AccessTokenRequestBody body = new AccessTokenRequestBody();
        body.app_id = appConfig.appId;
        body.secret = appConfig.secret;
        body.grant_type = 'client_credentials';
        body.nonce = appConfig.nonce;

        req.setBody(JSON.serialize(body));
        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                 GlobalPayAccessTokenResponse tokenResp = (GlobalPayAccessTokenResponse) JSON.deserialize(res.getBody(), GlobalPayAccessTokenResponse.class);
                 appConfig.onetimeAccessToken = tokenResp.token;
                 return appConfig;
            }
        } catch (Exception e) {
            System.debug('Access Token Error: ' + e.getMessage());
        } 
        return appConfig;
    }

    private static NewGlobalPayLinkResponse createHostedPaymentLink(Id recordId, AppConfig appConfig) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PaymentLinkEndpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + appConfig.onetimeAccessToken);
        req.setHeader('X-GP-Version', '2021-03-22');

        PaymentLinkRequestBody requestBody = new PaymentLinkRequestBody();
        requestBody.account_name = 'pay_link_hpp';
        requestBody.merchant_id = appConfig.merchantId;
        requestBody.type = 'HOSTED_PAYMENT_PAGE';
        requestBody.name = recordId;
        requestBody.description = 'Regulatory Transaction Fee details';
        requestBody.reference = String.valueOf(recordId);

        requestBody.payer = new PaymentLinkRequestPayerDetail(
            'James Mason', //to be replaced
            'en',
            'jamesmason@example.com', //to be replaced
            new PaymentLinkRequestMobilePhoneDetail('44', '1801555888'), //to be replaced
            new PaymentLinkRequestBillingAddressDetail('Flat 456', 'House 456', 'Unit 4', 'Halifax', 'k2s 0v1', 'CA')
        );

        PaymentLinkRequestOrderDetail orderDetail = new PaymentLinkRequestOrderDetail(
            '1000',
            'CAD', 
            recordId,
            new TransactionConfiguration('CNP', 'CA', 'AUTO', new List<String>{ 'CARD' }),
            new PaymentMethodConfiguration(new Authentications('CHALLENGE_PREFERRED'))
        );
        requestBody.order = orderDetail.toMap();

        requestBody.notifications = new PaymentResponseNotifications(
           GlobalPayRedirectUrl + recordId,
           GlobalPayStatusUrl
        );
        req.setBody(JSON.serialize(requestBody));

        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                return (NewGlobalPayLinkResponse) JSON.deserialize(res.getBody(), NewGlobalPayLinkResponse.class);
            }
        } catch (Exception e) {
            system.assert(false, e);
            System.debug('PaymentLink Error: ' + e.getMessage());
        }
        return null;
    }
    
    private static GlobalPayLinkDetailsResponse getPaymentLinkStatus(RegulatoryTrxnFee regulatoryTrxnFeeRec, AppConfig appConfig) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(PaymentLinkEndpointUrl + '/' + regulatoryTrxnFeeRec.GlobalPayPaymentLinkId__c);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + appConfig.onetimeAccessToken);
        req.setHeader('X-GP-Version', '2021-03-22');
        
        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException('GlobalPay callout failed: ' + res.getStatus() + ' - ' + res.getBody());
        }
   
    	return (GlobalPayLinkDetailsResponse)JSON.deserialize(res.getBody(), GlobalPayLinkDetailsResponse.class);
    }
    
    public class TransactionItemSortByTime implements Comparator<TransactionItem> {
        public Integer compare(TransactionItem a, TransactionItem b) { 
            DateTime aDateTime = (a != null && a.time_created != null) ? a.time_created: null;
            DateTime bDateTime = (b != null && b.time_created != null) ? b.time_created : null;

            if (aDateTime == null && bDateTime == null) return 0;
            if (aDateTime == null) return -1;
            if (bDateTime == null) return 1;

            if (aDateTime == bDateTime) return 0;
            return aDateTime > bDateTime ? 1 : -1;
        }
	}

    private class AppConfig {
        private String appId;
        private String appToken;
        private string onetimeAccessToken;
        private String secret;
        private String nonce;
        private String merchantId;
    }
    
    private class AccessTokenRequestBody {
        private String app_id ;
        private String secret;
        private String nonce;
        private String grant_type;
    }

    private class PaymentLinkRequestBody {
        private String account_name;
        private String merchant_id;
        private String type;
        private String name;
        private String description;
        private String reference;
        private PaymentLinkRequestPayerDetail payer;
        private Map<String, Object> order;
        private PaymentResponseNotifications notifications;
    }

    private class PaymentLinkRequestPayerDetail {
        private String name;
        private String language;
        private String email;
        private PaymentLinkRequestMobilePhoneDetail mobile_phone;
        private PaymentLinkRequestBillingAddressDetail billing_address;

        private PaymentLinkRequestPayerDetail(String payerName, String languageCode, String emailAddress, PaymentLinkRequestMobilePhoneDetail mobilePhone, PaymentLinkRequestBillingAddressDetail billingAddress) {
            this.name = payerName;
            this.language = languageCode;
            this.email = emailAddress;
            this.mobile_phone = mobilePhone;
            this.billing_address = billingAddress;
        }
    }

    private class PaymentLinkRequestMobilePhoneDetail {
        private String country_code;
        private String subscriber_number;

        private PaymentLinkRequestMobilePhoneDetail(String countryCode, String subscriberNumber) {
            this.country_code = countryCode;
            this.subscriber_number = subscriberNumber;
        }
    }

    private class PaymentLinkRequestBillingAddressDetail {
        private String line_1;
        private String line_2;
        private String line_3;
        private String city;
        private String postal_code;
        private String country;

        private PaymentLinkRequestBillingAddressDetail(String line1, String line2, String line3, String cityName, String postalCode, String countryCode) {
            this.line_1 = line1;
            this.line_2 = line2;
            this.line_3 = line3;
            this.city = cityName;
            this.postal_code = postalCode;
            this.country = countryCode;
        }
    }

    private class PaymentLinkRequestOrderDetail {
        private String amount;
        private String currencyCode;
        private String reference;
        private TransactionConfiguration transaction_configuration;
        private PaymentMethodConfiguration payment_method_configuration;

        private PaymentLinkRequestOrderDetail(String amount, String currencyCode, String reference,
                                            TransactionConfiguration txConfig,
                                            PaymentMethodConfiguration pmConfig) {
            this.amount = amount;
            this.currencyCode = currencyCode;
            this.reference = reference;
            this.transaction_configuration = txConfig;
            this.payment_method_configuration = pmConfig;
        }

        private Map<String, Object> toMap() {
            return new Map<String, Object>{
                'amount' => amount,
                'currency' => currencyCode,
                'reference' => reference,
                'transaction_configuration' => transaction_configuration,
                'payment_method_configuration' => payment_method_configuration
            };
        }
    }

    private class TransactionConfiguration {
        private String channel;
        private String country;
        private String capture_mode;
        private List<String> allowed_payment_methods;

        private TransactionConfiguration(String channelType, String countryCode, String captureMode, List<String> allowedPaymentMethods) {
            this.channel = channelType;
            this.country = countryCode;
            this.capture_mode = captureMode;
            this.allowed_payment_methods = allowedPaymentMethods;
        }
    }

    private class PaymentMethodConfiguration {
        private Authentications authentications;

        private PaymentMethodConfiguration(Authentications authenticationPreference) {
            this.authentications = authenticationPreference;
        }
    }

    private class Authentications {
        private String preference;

        private Authentications(String preferenceSetting) {
            this.preference = preferenceSetting;
        }
    }

    private class PaymentResponseNotifications {
        private String return_url;
        private String status_url;

        private PaymentResponseNotifications(String returnUrl, String statusCallbackUrl) {
            this.return_url = returnUrl;
            this.status_url = statusCallbackUrl;
        }
    }
   
    @TestVisible
    private class GlobalPayAccessTokenResponse {
       @TestVisible 
       private String token;
       private String type;
       private Scope scope;
       private String app_id;
       private String app_name;
       private String time_created;
       private Integer seconds_to_expire;
       private String email;
    }

   private class Scope {
       private String merchant_id;
       private String merchant_name;
    }
    
   @TestVisible
   private class NewGlobalPayLinkResponse {
       @TestVisible
       private String id;
       private String account_name;
       
       @TestVisible
       private String url;
       private String status;
       private String type;
       private String usage_mode;
       private String usage_limit;
       private String name;
       private String description;
       private String expiration_date;
       private Order order;
       private Action action;
    }

   private class Order {
       private String amount;
       private String currencyTest;
       private String reference;
       private TransactionConfiguration transaction_configuration;
    }

   private class Action {
       private String id;
       private String type;
       private String time_created;
       private String result_code;
       private String app_id;
       private String app_name;
    }
    
    public class GlobalPayLinkDetailsResponse {
        public String merchant_id;
        public String merchant_name;
        public String account_id;
        public String account_name;
        public String id;
        public String url;
        public String status;
        public String type;
        public String usage_mode;
        public String usage_limit;
        public String reference;
        public String name;
        public String description;
        public String shippable;
        public String shipping_amount;
        public String usage_count;
        public String viewed_count;
        public Datetime expiration_date;
        public List<Object> images;
        public Notifications notifications;
        public Transactions transactions;
        public Action action;
    }

    public class Notifications {
        public String return_url;
        public String status_url;
        public String cancel_url;
    }

    public class Transactions {
        public String amount;
        public String channel;
        public String country;
        public String transactionCurrency;
        public List<String> allowed_payment_methods;
        public List<TransactionItem> transaction_list;
    }
    
	public class TransactionItem {
        public String id;
        public Datetime time_created;
        public String status;
        public String type;
        public String channel;
        public String amount;
        public String transactionCurrency;
        public String reference;
   }
}