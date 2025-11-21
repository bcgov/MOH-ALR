@IsTest
private class PHOCSGlobalPayHandlerTest {
   
    @testSetup
    static void setup() { 
        Account facility = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId(),
            Name = 'Test Facility',
            BillingCity = 'TT',
            BillingCountry = 'YY',
            BillingPostalCode = '225522',
            BillingState = 'TT',
            BillingStreet = 'YT',
			HealthAuthority__c = 'Interior Health - IH'
        );
        insert facility;
		
        RegulatoryTrxnFee fee1 = new RegulatoryTrxnFee(AccountId = facility.Id, FeeType__c = 'Renewal Unit Fee', Status = 'Paid');
        insert fee1;
    }

    @isTest
    static void testGetPaymentLinkUrl() {

        // Retrieve test RTF record
        RegulatoryTrxnFee rtf = [
            SELECT Id, AccountId FROM RegulatoryTrxnFee LIMIT 1
        ];

        // Register mock class
        Test.setMock(HttpCalloutMock.class, new GlobalPayMock());

        Test.startTest();
        String url = PHOCSGlobalPayHandler.getPaymentLinkUrl(rtf.Id);
        Test.stopTest();

        System.assertNotEquals(null, url, 'Payment URL should be returned');
        System.assert(url.contains('https://mockpaymentlink.test'), 'Mock URL must be returned');
    }

    @isTest
    static void testNullId() {

        Test.setMock(HttpCalloutMock.class, new GlobalPayMock());

        Test.startTest();
        String url = PHOCSGlobalPayHandler.getPaymentLinkUrl(null);
        Test.stopTest();

        System.assertEquals(null, url, 'Should return null for null Id');
    }
    
    private class GlobalPayMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // Mock Access Token endpoint
            if (req.getEndpoint().contains('accesstoken')) {
                PHOCSGlobalPayHandler.GlobalPayAccessTokenResponse tokenResp = new PHOCSGlobalPayHandler.GlobalPayAccessTokenResponse();
                tokenResp.token = 'mockAccessToken123';
                res.setStatusCode(200);
                res.setBody(JSON.serialize(tokenResp));
                return res;
            }

            // Mock Payment Link endpoint
            if (req.getEndpoint().contains('ucp/links')) {
                PHOCSGlobalPayHandler.GlobalPayLinkResponse linkResp = new PHOCSGlobalPayHandler.GlobalPayLinkResponse();
                linkResp.url = 'https://mockpaymentlink.test/123';
                res.setStatusCode(201);
                res.setBody(JSON.serialize(linkResp));
                return res;
            }

            // Default fail response
            res.setStatusCode(400);
            res.setBody('Unexpected endpoint');
            return res;
        }
    }
}