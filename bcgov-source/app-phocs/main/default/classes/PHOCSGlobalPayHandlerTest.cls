@IsTest
private class PHOCSGlobalPayHandlerTest {
	
     @IsTest
    static void testGetAccessToken_direct_success() {
        Test.setMock(HttpCalloutMock.class, new PaymentLinkUrlMock(200, '{"token":"abc123","type":"bearer"}'));
        Test.startTest();
        PHOCSGlobalPayHandler.GlobalPayAccessTokenResponse resp = PHOCSGlobalPayHandler.getAccessToken();
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Access token response should not be null');
        System.assertEquals('abc123', resp.token, 'Token value should match mock');
    }
    
    @IsTest
    static void testGetAccessToken_direct_error() {
        Test.setMock(HttpCalloutMock.class, new PaymentLinkUrlMock(400, '{"error":"invalid"}'));
        Test.startTest();
        PHOCSGlobalPayHandler.GlobalPayAccessTokenResponse resp = PHOCSGlobalPayHandler.getAccessToken();
        Test.stopTest();

        System.assertEquals(null, resp, 'Response should be null when status is not 200');
    }

     @IsTest
    static void testCreateHostedPaymentLink_direct_success() {
        // When calling createHostedPaymentLink directly, handler expects a valid token string
        Test.setMock(HttpCalloutMock.class, new PaymentLinkUrlMock(200, null));
        Test.startTest();
        PHOCSGlobalPayHandler.GlobalPayLinkResponse linkResp = PHOCSGlobalPayHandler.createHostedPaymentLink('dummy_token');
        Test.stopTest();

        System.assertNotEquals(null, linkResp, 'GlobalPayLinkResponse should be returned');
        System.assertEquals('https://pay.example/link/abc', linkResp.url, 'URL should match mock body');
    }

    @IsTest
    static void testCreateHostedPaymentLink_direct_error() {
        Test.setMock(HttpCalloutMock.class, new PaymentLinkUrlMock(500, '{"error":"server_error"}'));
        Test.startTest();
        PHOCSGlobalPayHandler.GlobalPayLinkResponse linkResp = PHOCSGlobalPayHandler.createHostedPaymentLink('dummy_token');
        Test.stopTest();
        System.assertEquals(null, linkResp, 'Response should be null on non-200/201 status');
    }
    
    @IsTest
    static void testGetPaymentLinkUrl_success_200() {
        // First callout: access token 200
        Test.setMock(HttpCalloutMock.class, new PaymentLinkUrlMock(200, null));
        // Start a separate context for the second callout
        Test.startTest();
        // Replace the mock to handle the second callout to the links endpoint
        Test.setMock(HttpCalloutMock.class, new PaymentLinkUrlMock(200, null));
        String url = PHOCSGlobalPayHandler.getPaymentLinkUrl();
        Test.stopTest();

        System.assertNotEquals(null, url, 'URL should be returned on success');
        System.assert(url.contains('https://'), 'URL should look like a full URL');
    }
    
     
    private class PaymentLinkUrlMock implements HttpCalloutMock {
        Integer statusCode;
        string body;   
  
        PaymentLinkUrlMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }  
        public HTTPResponse respond(HTTPRequest req) {
            if(req.getEndpoint().contains('accesstoken')){
                HttpResponse res = new HttpResponse();
                res.setStatusCode(statusCode);
                if (statusCode == 200) {
                    res.setBody(body != null ? body : '{"token":"test_access_token","type":"bearer"}');
                } else {
                    res.setBody(body != null ? body : '{"error":"invalid_client"}');
                }
                return res;
            }
            else if(req.getEndpoint().contains('links')){
                HttpResponse res = new HttpResponse();
                res.setStatusCode(statusCode);
                if (statusCode == 200 || statusCode == 201) {
                    // Return a minimal body that matches PHOCSGlobalPayHandler.GlobalPayLinkResponse shape
                    String defaultBody = '{"id":"id-1","account_name":"pay_link_hpp","url":"https://pay.example/link/abc","status":"ACTIVE","type":"HOSTED_PAYMENT_PAGE","usage_mode":"SINGLE","usage_limit":"1","name":"Bill Payment","description":"desc","expiration_date":"2029-01-01T00:00:00Z","order":{"amount":"1000","currencyTest":"CAD","reference":"order-645","transaction_configuration":{"country":"CA","channel":"CNP"}},"action":{"id":"act-1","type":"CREATE","time_created":"2024-01-01T00:00:00Z","result_code":"00","app_id":"app","app_name":"name"}}';
                    res.setBody(body != null ? body : defaultBody);
                } else {
                    res.setBody(body != null ? body : '{"error":"bad_request"}');
                }
                return res;
            }else{
                return new HttpResponse();
            }
        }
    }
}