@isTest
public with sharing class PHOCSGlobalPayResponseHandlerTest {

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

    private static String computeSignature(String body, String appKey) {
        Blob raw = Blob.valueOf(body + appKey);
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-512', raw)).toLowerCase();
    }

    @isTest
    static void testValidWebhook() {

        // Retrieve test RTF record
        RegulatoryTrxnFee fee = [
            SELECT Id, AccountId FROM RegulatoryTrxnFee LIMIT 1
        ];

        // Build mock JSON matching handler fields
        String bodyJson = JSON.serialize(new Map<String, Object>{
            'id' => 'GP-123',
            'reference' => fee.Id,
            'payment_method' => new Map<String, Object>{
                'message' => 'CAPTURED'
            }
        });

        // Compute expected signature
        String appKey = '4yAtqdjSokiV3qwK';
        String signature = computeSignature(bodyJson, appKey);

        // Prepare RestContext
        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bodyJson);
        req.addHeader('X-GP-Signature', signature);
        req.requestURI = '/services/apexrest/phocs/globalPay/status/';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PHOCSGlobalPayResponseHandler.handleWebhook();
        Test.stopTest();

        // Get updated fee
        RegulatoryTrxnFee updatedFee = [
            SELECT PaymentResponse__c, ReferenceNumber__c, Status
            FROM RegulatoryTrxnFee WHERE Id = :fee.Id
        ];

        System.assertEquals('GP-123', updatedFee.ReferenceNumber__c, 'ID should be saved');
        System.assertEquals('PAID', updatedFee.Status, 'Status should match payment message');
        System.assertEquals(200, RestContext.response.statusCode, 'Should return 200');
    }
    
    @isTest
    static void testInvalidSignature() {

         // Retrieve test RTF record
        RegulatoryTrxnFee fee = [
            SELECT Id, AccountId FROM RegulatoryTrxnFee LIMIT 1
        ];

        String bodyJson = JSON.serialize(new Map<String, Object>{
            'id' => 'GP-INVALID',
            'reference' => fee.Id,
            'payment_method' => new Map<String, Object>{ 'message' => 'DECLINED' }
        });

        // WRONG signature
        String invalidSignature = 'abc123';

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bodyJson);
        req.addHeader('X-GP-Signature', invalidSignature);
        req.requestURI = '/services/apexrest/phocs/globalPay/status/';

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        PHOCSGlobalPayResponseHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Should return 400');

        // Verify record was NOT updated
        RegulatoryTrxnFee unchanged = [
            SELECT PaymentResponse__c, ReferenceNumber__c, Status
            FROM RegulatoryTrxnFee WHERE Id = :fee.Id
        ];

        System.assertEquals(null, unchanged.PaymentResponse__c, 'Should not update when signature is invalid');
        System.assertEquals(null, unchanged.ReferenceNumber__c, 'Should not update when signature invalid');
    }
}