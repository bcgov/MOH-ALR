public with sharing class PHOCSGlobalPayHandler {
    private static final Map<string, string> healthAuthorityMapping = new Map<string, string>{
        'Island Health - Island' => 'IS',
        'Interior Health - IH' => 'IH',
        'Fraser Health - FH' => 'FH',
        'Northern Health - NH' => 'NH',
        'Vancouver Coastal Health - VCH' => 'VCH'
    };

    private static PHOCSGlobalPayEndpoints__mdt globalPaySetting = PHOCSGlobalPayEndpoints__mdt.getInstance('Default'); 
    private static String AccessTokenEndpointUrl {
        get { return globalPaySetting.AccssTokenEndpoint__c; }
    }
    private static String PaymentLinkEndpointUrl {
        get { return globalPaySetting.PaymentLinkEndpoint__c; }
    }
    private static String GlobalPayRedirectUrl {
        get { return  getPHOCSSiteDomain() + globalPaySetting.PaymentReturnEndpoint__c; }
    }
    private static String GlobalPayStatusUrl {
        get { return  getPHOCSSiteDomain() + globalPaySetting.PaymentStatusEndpoint__c; }
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

    private static string getHealthAuthorityCode(Id regulatoryTransactionFeeId) {
        string healthAuth = '';        
        if(string.isNotBlank(regulatoryTransactionFeeId)){
            RegulatoryTrxnFee[] regulatoryTrxnFees = [select Id, Account.HealthAuthority__c from RegulatoryTrxnFee where Id=:regulatoryTransactionFeeId];
            if(regulatoryTrxnFees != null && !regulatoryTrxnFees.isEmpty()){
                string ha = regulatoryTrxnFees[0].Account?.HealthAuthority__c;
                if(string.isNotBlank(ha)){
                    healthAuth = healthAuthorityMapping.get(ha);
                }
            }
        }
        return healthAuth;
    }
    
    private static string getAppSecret(string appKey, string nonce){
        return '';
    }

    @AuraEnabled(cacheable=true)
    public static String getPaymentLinkUrl(Id regulatoryTransactionFeeId) {
        GlobalPayAccessTokenResponse tokenResp = getAccessToken(regulatoryTransactionFeeId);
        if (tokenResp == null || String.isBlank(tokenResp.token)) return null;

        GlobalPayLinkResponse linkResp = createHostedPaymentLink(regulatoryTransactionFeeId, tokenResp.token);
        return linkResp != null ? linkResp.url : null;
    }

    private static GlobalPayAccessTokenResponse getAccessToken(Id regulatoryTransactionFeeId) {    
        string healthAuth = getHealthAuthorityCode(regulatoryTransactionFeeId);
        if(string.isBlank(healthAuth)) return null;

        string appId =  '{!$Credential.GlobalPay.app_id_' + healthAuth + '}'; 
        string appSecret = '{!$Credential.GlobalPay.app_secret_' + healthAuth + '}'; 

        HttpRequest req = new HttpRequest();
        req.setEndpoint(AccessTokenEndpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-GP-Version', '{!$Credential.GlobalPay.xgp_Version}');

        AccessTokenRequestBody body = new AccessTokenRequestBody(
            appId,
            appSecret,
            'client_credentials',
            '{!$Credential.GlobalPay.nonce}'
        );
        req.setBody(JSON.serialize(body));
        try {
            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() == 200) {
                return (GlobalPayAccessTokenResponse) JSON.deserialize(res.getBody(), GlobalPayAccessTokenResponse.class);
            }
            system.assert(false, res.getBody());
        } catch (Exception e) {
            System.debug('Access Token Error: ' + e.getMessage());
            system.assert(false, e);
        }
        return null;
    }

    private static GlobalPayLinkResponse createHostedPaymentLink(Id recordId, String accessToken) {

        string healthAuth = getHealthAuthorityCode(recordId);
        if(string.isBlank(healthAuth)) return null;

        string merchantId = '{!$Credential.GlobalPay.merchant_id_' + healthAuth + '}';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(PaymentLinkEndpointUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('X-GP-Version', '{!$Credential.GlobalPay.xgp_Version}');

        PaymentLinkRequestBody requestBody = new PaymentLinkRequestBody();
        requestBody.account_name = 'pay_link_hpp';
        requestBody.merchant_id = merchantId;
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
                return (GlobalPayLinkResponse) JSON.deserialize(res.getBody(), GlobalPayLinkResponse.class);
            }
        } catch (Exception e) {
            system.assert(false, e);
            System.debug('PaymentLink Error: ' + e.getMessage());
        }
        return null;
    }

    public class AccessTokenRequestBody {
        public String app_id;
        public String secret;
        public String grant_type;
        public String nonce;

        public AccessTokenRequestBody(String appId, String appSecret, String grantType, String nonceValue) {
            this.app_id = appId;
            this.secret = appSecret;
            this.grant_type = grantType;
            this.nonce = nonceValue;
        }
    }

    public class PaymentLinkRequestBody {
        public String account_name;
        public String merchant_id;
        public String type;
        public String name;
        public String description;
        public String reference;
        public PaymentLinkRequestPayerDetail payer;
        public Map<String, Object> order;
        public PaymentResponseNotifications notifications;
    }

    public class PaymentLinkRequestPayerDetail {
        public String name;
        public String language;
        public String email;
        public PaymentLinkRequestMobilePhoneDetail mobile_phone;
        public PaymentLinkRequestBillingAddressDetail billing_address;

        public PaymentLinkRequestPayerDetail(String payerName, String languageCode, String emailAddress, PaymentLinkRequestMobilePhoneDetail mobilePhone, PaymentLinkRequestBillingAddressDetail billingAddress) {
            this.name = payerName;
            this.language = languageCode;
            this.email = emailAddress;
            this.mobile_phone = mobilePhone;
            this.billing_address = billingAddress;
        }
    }

    public class PaymentLinkRequestMobilePhoneDetail {
        public String country_code;
        public String subscriber_number;

        public PaymentLinkRequestMobilePhoneDetail(String countryCode, String subscriberNumber) {
            this.country_code = countryCode;
            this.subscriber_number = subscriberNumber;
        }
    }

    public class PaymentLinkRequestBillingAddressDetail {
        public String line_1;
        public String line_2;
        public String line_3;
        public String city;
        public String postal_code;
        public String country;

        public PaymentLinkRequestBillingAddressDetail(String line1, String line2, String line3, String cityName, String postalCode, String countryCode) {
            this.line_1 = line1;
            this.line_2 = line2;
            this.line_3 = line3;
            this.city = cityName;
            this.postal_code = postalCode;
            this.country = countryCode;
        }
    }

    public class PaymentLinkRequestOrderDetail {
        public String amount;
        public String currencyCode;
        public String reference;
        public TransactionConfiguration transaction_configuration;
        public PaymentMethodConfiguration payment_method_configuration;

        public PaymentLinkRequestOrderDetail(String amount, String currencyCode, String reference,
                                            TransactionConfiguration txConfig,
                                            PaymentMethodConfiguration pmConfig) {
            this.amount = amount;
            this.currencyCode = currencyCode;
            this.reference = reference;
            this.transaction_configuration = txConfig;
            this.payment_method_configuration = pmConfig;
        }

        public Map<String, Object> toMap() {
            return new Map<String, Object>{
                'amount' => amount,
                'currency' => currencyCode,
                'reference' => reference,
                'transaction_configuration' => transaction_configuration,
                'payment_method_configuration' => payment_method_configuration
            };
        }
    }

    public class TransactionConfiguration {
        public String channel;
        public String country;
        public String capture_mode;
        public List<String> allowed_payment_methods;

        public TransactionConfiguration(String channelType, String countryCode, String captureMode, List<String> allowedPaymentMethods) {
            this.channel = channelType;
            this.country = countryCode;
            this.capture_mode = captureMode;
            this.allowed_payment_methods = allowedPaymentMethods;
        }
    }

    public class PaymentMethodConfiguration {
        public Authentications authentications;

        public PaymentMethodConfiguration(Authentications authenticationPreference) {
            this.authentications = authenticationPreference;
        }
    }

    public class Authentications {
        public String preference;

        public Authentications(String preferenceSetting) {
            this.preference = preferenceSetting;
        }
    }

    public class PaymentResponseNotifications {
        public String return_url;
        public String status_url;

        public PaymentResponseNotifications(String returnUrl, String statusCallbackUrl) {
            this.return_url = returnUrl;
            this.status_url = statusCallbackUrl;
        }
    }

    public class GlobalPayAccessTokenResponse {
        public String token;
        public String type;
        public Scope scope;
        public String app_id;
        public String app_name;
        public String time_created;
        public Integer seconds_to_expire;
        public String email;
    }

    public class Scope {
        public String merchant_id;
        public String merchant_name;
    }

    public class GlobalPayLinkResponse {
        public String id;
        public String account_name;
        public String url;
        public String status;
        public String type;
        public String usage_mode;
        public String usage_limit;
        public String name;
        public String description;
        public String expiration_date;
        public Order order;
        public Action action;
    }

    public class Order {
        public String amount;
        public String currencyTest;
        public String reference;
        public TransactionConfiguration transaction_configuration;
    }

    public class Action {
        public String id;
        public String type;
        public String time_created;
        public String result_code;
        public String app_id;
        public String app_name;
    }
}