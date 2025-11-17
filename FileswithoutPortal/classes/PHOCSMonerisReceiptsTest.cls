@IsTest
private class PHOCSMonerisReceiptsTest {
    
    /**
* Creates a mock PHOCSMonerisConfiguration__mdt record in-memory.
* (Note: Custom metadata cannot be inserted, so we simulate the record.)
*/
    private static PHOCSMonerisConfiguration__mdt getMockMonerisConfig() {
        PHOCSMonerisConfiguration__mdt config = new PHOCSMonerisConfiguration__mdt(
            Store_ID__c = 'store123',
            API_Token__c = 'apitoken123',
            Checkout_Id__c = 'checkout789',
            Environment__c = 'qa'
        );
        return config;
    }
    
    // ---- Test: Successful Receipt Retrieval ----
    @IsTest
    static void testCaptureReceiptStatus_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MonerisReceiptMock());
        
        PHOCSMonerisConfiguration__mdt config = getMockMonerisConfig();
        MonerisReceiptWrapper wrapper =
            PHOCSMonerisReceipts.captureReceiptStatus(config, '1760633356HvaZZUqLeXDhtpp33jMfRuwvGHTlnT', 'Completed');
        
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals(
            '660191690010010300',
            wrapper.response.receipt.cc.reference_no,
            'Reference number should match the mock data'
        );
        System.assertEquals('T42938', wrapper.response.receipt.cc.approval_code);
    }
    
    // ---- Test: HTTP Error (500) Handling ----
    @IsTest
    static void testCaptureReceiptStatus_HttpError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSMonerisServerErrorMock());
        
        Boolean caught = false;
        PHOCSMonerisConfiguration__mdt config = getMockMonerisConfig();
        
        try {
            PHOCSMonerisReceipts.captureReceiptStatus(config, 'ERR-TICKET', 'Completed');
        } catch (Exception e) {
            caught = true;
            System.debug('Exception: ' + e);
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        
        System.assert(caught, 'Expected an exception for HTTP error');
        Test.stopTest();
    }
    
    // ---- Test: Invalid JSON Response Handling ----
    @IsTest
    static void testCaptureReceiptStatus_InvalidResponse() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSMonerisInvalidResponseMock());
        
        Boolean caught = false;
        PHOCSMonerisConfiguration__mdt config = getMockMonerisConfig();
        
        try {
            PHOCSMonerisReceipts.captureReceiptStatus(config, 'BAD-RESP', 'Completed');
        } catch (Exception e) {
            caught = true;
            System.debug('Exception: ' + e);
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }
}