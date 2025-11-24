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
    
    @isTest
    static void testUpdatePaymentStatus() {    
        RegulatoryTrxnFee rtf = [
            SELECT Id, AccountId 
            FROM RegulatoryTrxnFee 
            LIMIT 1
        ];
        rtf.GlobalPayPaymentLinkId__c = 'TEST_LINK_ID';
        update rtf;
    
        Test.setMock(HttpCalloutMock.class, new GlobalPayMock());
    
        Test.startTest();
        PHOCSGlobalPayHandler.updatePaymentStatus(rtf.Id);
        Test.stopTest();
    
        RegulatoryTrxnFee updatedRTF = [
            SELECT GlobalPayPaymentStatus__c,
                   ReferenceNumber__c
            FROM RegulatoryTrxnFee 
            WHERE Id = :rtf.Id
            LIMIT 1
        ];
    
        System.assertEquals('COMPLETED', updatedRTF.GlobalPayPaymentStatus__c, 'Status should have been updated to COMPLETED.');   
        System.assertEquals('txn001', updatedRTF.ReferenceNumber__c, 'ReferenceNumber should be taken from transaction list.');
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
            if (req.getEndpoint().contains('ucp/links') && req.getMethod() == 'POST') {
                PHOCSGlobalPayHandler.NewGlobalPayLinkResponse linkResp = new PHOCSGlobalPayHandler.NewGlobalPayLinkResponse();
                linkResp.url = 'https://mockpaymentlink.test/123';
                res.setStatusCode(201);
                res.setBody(JSON.serialize(linkResp));
                return res;
            }
			
            if (req.getEndpoint().contains('ucp/links') && req.getMethod() == 'GET') {
                PHOCSGlobalPayHandler.GlobalPayLinkDetailsResponse linkResp = new PHOCSGlobalPayHandler.GlobalPayLinkDetailsResponse();
    			linkResp.transactions = new PHOCSGlobalPayHandler.Transactions();
                linkResp.transactions.transaction_list = new List<PHOCSGlobalPayHandler.TransactionItem>();
    			PHOCSGlobalPayHandler.TransactionItem item = new PHOCSGlobalPayHandler.TransactionItem();
                item.id = 'txn001';
                item.status = 'COMPLETED';
                item.time_created = Datetime.now();
                linkResp.transactions.transaction_list.add(item);
                
                res.setStatusCode(200);
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