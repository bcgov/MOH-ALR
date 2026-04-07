@IsTest
private class PHOCSMonerisTicketTest {
    
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

    @IsTest
    static void testGenerateTicket_Success() {
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new PHOCSMonerisTicketMock());

        PHOCSMonerisConfiguration__mdt config = getMockMonerisConfig();
        String orderNo = 'ORDER-20251014-123456-98765';
        Decimal totalAmt = 100.50;

        String ticket = PHOCSMonerisTicket.generateTicket(config, orderNo, totalAmt);

        Test.stopTest();

        System.assertEquals('1760676466VKD7ZaaBL9L8MnSYLg9TiPVf6VJtRT', ticket, 'Expected mock ticket value to match');
    }

    @IsTest
    static void testGenerateTicket_HttpError() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSMonerisServerErrorMock());

        PHOCSMonerisConfiguration__mdt config = getMockMonerisConfig();
        try {
            PHOCSMonerisTicket.generateTicket(config, 'ORDER-ERR-001', 250.00);
            System.assert(false, 'Expected AuraHandledException to be thrown');
        } catch (Exception e) {
            //System.debug(e);
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }

        Test.stopTest();
    }

    @IsTest
    static void testGenerateTicket_InvalidResponse() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSMonerisInvalidResponseMock());

        PHOCSMonerisConfiguration__mdt config = getMockMonerisConfig();
        try {
            PHOCSMonerisTicket.generateTicket(config, 'ORDER-BAD-RESP', 150.00);
            System.assert(false, 'Expected AuraHandledException for unexpected response');
        } catch (AuraHandledException e) {
            //System.debug(e);
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }

        Test.stopTest();
    }
}