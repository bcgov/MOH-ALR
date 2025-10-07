public with sharing class GlobalPayService {
      // Endpoint URL
    private static final String ACCESSTOKEN_ENDPOINT_URL = 'https://apis.sandbox.globalpay.com/ucp/accesstoken';
    private static final String PAYMENT_LINK_ENDPOINT_URL = 'https://apis.sandbox.globalpay.com/ucp/links';

    @AuraEnabled(cacheable=true) 
    public static string getPaymentLinkUrl() {
        GlobalPayAccessTokenResponse accessTokenResponse = getAccessToken();
        if (accessTokenResponse != null && accessTokenResponse.token != null) {
            GlobalPayLinkResponse globalPayLinkResponse = createHostedPaymentLink(accessTokenResponse.token);
            if(globalPayLinkResponse != null && globalPayLinkResponse.url != null){
                return globalPayLinkResponse.url;
            }
            return null;
        }
        return null;
    }

    // Method to get access token
    public static GlobalPayAccessTokenResponse getAccessToken() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        // Set headers
        request.setEndpoint(ACCESSTOKEN_ENDPOINT_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('X-GP-Version', '2023-01-01');

        // Prepare request body
        Map<String, Object> requestBody = new Map<String, Object>{
            'app_id' => '1dPAIy90MLVyENnVGMdBLbiSiN4ifoKn',
            'secret' => '5267726712636df6ca537cea3e284f5ca9281c81d438a20dd70f3063c2fee3dad6edc586593b0a71148a50c1259ab3361905668881e731fb99621668342b8fdf',
            'grant_type' => 'client_credentials',
            'nonce' => '2029-03-14T13:24:10.832Z'
        };

        String body = JSON.serialize(requestBody);
        request.setBody(body);

        try {
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                return (GlobalPayAccessTokenResponse) JSON.deserialize(response.getBody(), GlobalPayAccessTokenResponse.class);
            } else {
                System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
    }

    public static GlobalPayLinkResponse createHostedPaymentLink(String accessToken) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();

        request.setEndpoint(PAYMENT_LINK_ENDPOINT_URL);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', 'Bearer ' + accessToken);
		 request.setHeader('X-GP-Version', '2023-01-01');
        
        // Build Request Body
        Map<String, Object> requestBody = new Map<String, Object>{
            'account_name' => 'pay_link_hpp',
            'merchant_id' => 'MER_7e3e2c7df34f42819b3edee31022ee3f',
            'type' => 'HOSTED_PAYMENT_PAGE',
            'name' => 'Bill Payment',
            'description' => 'February and March Invoice',
            'reference' => 'MER_7e3e2c7df34f42819b3edee31022ee3f',
            'payer' => new Map<String, Object>{
                'name' => 'James Mason',
                'language' => 'en',
                'email' => 'jamesmason@example.com',
                'mobile_phone' => new Map<String, Object>{
                    'country_code' => '44',
                    'subscriber_number' => '1801555888'
                },
                'billing_address' => new Map<String, Object>{
                    'line_1' => 'Flat 456',
                    'line_2' => 'House 456',
                    'line_3' => 'Unit 4',
                    'city' => 'Halifax',
                    'postal_code' => '44',
                    'country' => 'GB'
                }
            },
            'order' => new Map<String, Object>{
                'amount' => '1000',
                'currency' => 'CAD',
                'reference' => 'order-645',
                'transaction_configuration' => new Map<String, Object>{
                    'channel' => 'CNP',
                    'country' => 'CA',
                    'capture_mode' => 'AUTO',
                    'allowed_payment_methods' => new List<String>{ 'CARD' }
                },
                'payment_method_configuration' => new Map<String, Object>{
                    'authentications' => new Map<String, Object>{
                        'preference' => 'CHALLENGE_PREFERRED'
                    }
                }
            },
            'notifications' => new Map<String, Object>{
                'return_url' => 'https://www.example.com/return_url',
                'status_url' => 'https://www.example.com/status_url'
            }
        };

        request.setBody(JSON.serialize(requestBody));

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                return (GlobalPayLinkResponse) JSON.deserialize(response.getBody(), GlobalPayLinkResponse.class);
            } else {
                System.debug('Error: ' + response.getStatusCode() + ' - ' + response.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception during callout: ' + e.getMessage());
            return null;
        }
    }




    // Response wrapper class
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

    // Nested scope object
    public class Scope {
        public String merchant_id;
        public String merchant_name;
    }

     // Response Wrapper
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

    public class TransactionConfiguration {
        public String country;
        public String channel;
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