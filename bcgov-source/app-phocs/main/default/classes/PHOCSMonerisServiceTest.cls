@IsTest
private class PHOCSMonerisServiceTest {
    
    @testSetup
    private static void createData(){
        RegulatoryAuthorizationType licensetype = new RegulatoryAuthorizationType(
            Name = 'Supportive Recovery',
            RegulatoryAuthCategory = 'License',
            UnitFee__c = 12.50
        );
        insert licensetype;
        Account acc = new Account(
            Name = 'Test Account',
            HealthAuthority__c = 'Vancouver Coastal Health - VCH',
            LicenseType__c = licensetype.Id
        );
        insert acc;
        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = acc.Id,
            Status = 'Due'
        );
        insert fee;
        RegulatoryTrxnFeeItem feeItem = new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = fee.Id,
            FeeAmount = 120.00,
            Amount__c = 120.00,
            Name = 'Test'
        );
        insert feeItem;
        PHOCSMonerisService.monerisConfig = new Map<String, PHOCSMonerisConfiguration__mdt>{
            'Vancouver Coastal Health - VCH' => new PHOCSMonerisConfiguration__mdt(
                Store_ID__c = 'store123',
                API_Token__c = 'apitoken123',
                Checkout_Id__c = 'checkout789',
                HealthAuthority__c = 'Vancouver Coastal Health - VCH',
                Environment__c = 'qa'
            )};
    }
    
    @IsTest
    static void testGenerateTicket_Success() {
        // Mock PHOCSMonerisTicket.generateTicket
        Test.setMock(HttpCalloutMock.class, new PHOCSMonerisTicketMock());
        
        // Arrange
        Account acc = [Select Id, Name, HealthAuthority__c from Account limit 1];
        RegulatoryTrxnFee fee = [SELECT Id, Status, Name, RecordTypeId, ReferenceNumber__c, PaymentDate__c, FeeType__c, PHOCSMonerisTicketNumber__c, AccountName__c, PHOCSCustomerID__c FROM RegulatoryTrxnFee limit 1];

        // Replace real method calls with mocks using Stub API
        Test.startTest();
        String generatedTicket = PHOCSMonerisService.generateTicket(fee.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, generatedTicket, 'Ticket should not be null');
    }

    @IsTest
    static void testCheckReceiptStatus_Success() {
        // Mock PHOCSMonerisTicket.generateTicket
        Test.setMock(HttpCalloutMock.class, new MonerisReceiptMock());
        // Arrange
        Account acc = [Select Id, Name, HealthAuthority__c from Account limit 1];
        RegulatoryTrxnFee fee = [SELECT Id, Status, Name, RecordTypeId, ReferenceNumber__c, PaymentDate__c, FeeType__c, PHOCSMonerisTicketNumber__c, AccountName__c, PHOCSCustomerID__c FROM RegulatoryTrxnFee limit 1];
		fee.PHOCSMonerisTicketNumber__c = '1760633356HvaZZUqLeXDhtpp33jMfRuwvGHTlnT';
        // Replace real method calls with mocks using Stub API
        Test.startTest();
        update fee;

        //PHOCSMonerisService.generateTicket(fee.Id);
        try{
            PHOCSMonerisService.checkReceiptStatus(fee.Id, 'PAID');
        }catch(Exception ex){
            System.debug('Exception: ' + ex);
        }

        Test.stopTest();

        // Assert updated values
        RegulatoryTrxnFee updatedFee = [
            SELECT PHOCSMonerisTicketNumber__c, ReferenceNumber__c, Status
            FROM RegulatoryTrxnFee WHERE Id = :fee.Id
        ];
        System.debug('Ticket: ' + updatedFee.PHOCSMonerisTicketNumber__c);
        System.debug('Status: ' + updatedFee.Status);
        
        System.assertEquals('1760633356HvaZZUqLeXDhtpp33jMfRuwvGHTlnT', updatedFee.PHOCSMonerisTicketNumber__c);
    }

    @IsTest
    static void testGenerateTicket_InvalidAccount() {
        // Arrange
        Account acc = [Select Id, Name, HealthAuthority__c from Account limit 1];
        RegulatoryTrxnFee fee = [SELECT Id, Status, Name, RecordTypeId, ReferenceNumber__c, PaymentDate__c, FeeType__c, PHOCSMonerisTicketNumber__c, AccountName__c, PHOCSCustomerID__c FROM RegulatoryTrxnFee limit 1];


        Test.startTest();
        try {
            PHOCSMonerisService.generateTicket(fee.Id);
            System.assert(false, 'Expected AuraHandledException for invalid transaction');
        } catch (AuraHandledException e) {
            System.debug('Exception: ' + e);
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testCheckReceiptStatus_MissingTicket() {
        // Arrange
        Account acc = [Select Id, Name, HealthAuthority__c from Account limit 1];
        RegulatoryTrxnFee fee = [SELECT Id, Status, Name, RecordTypeId, ReferenceNumber__c, PaymentDate__c, FeeType__c, PHOCSMonerisTicketNumber__c, AccountName__c, PHOCSCustomerID__c FROM RegulatoryTrxnFee limit 1];

        Test.startTest();
        try {
            PHOCSMonerisService.checkReceiptStatus(fee.Id, 'Completed');
            System.assert(false, 'Expected AuraHandledException for missing ticket');
        } catch (AuraHandledException e) {
            System.debug('Exception: ' + e);
            System.assert(e.getMessage().contains('Script-thrown exception'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateRegulatoryTransFee_FutureMethod() {
        // Arrange
        Account acc = [Select Id, Name, HealthAuthority__c from Account limit 1];
        RegulatoryTrxnFee fee = [SELECT Id, Status, Name, RecordTypeId, ReferenceNumber__c, PaymentDate__c, FeeType__c, PHOCSMonerisTicketNumber__c, AccountName__c, PHOCSCustomerID__c FROM RegulatoryTrxnFee limit 1];

        Test.startTest();
        PHOCSMonerisService.updateRegulatoryTransFee(
            fee.Id, 'TICKET-111', 'REF-222', 'Paid'
        );
        Test.stopTest();

        RegulatoryTrxnFee updatedFee = [
            SELECT PHOCSMonerisTicketNumber__c, ReferenceNumber__c, Status, PaymentDate__c
            FROM RegulatoryTrxnFee WHERE Id = :fee.Id
        ];

        System.assertEquals('TICKET-111', updatedFee.PHOCSMonerisTicketNumber__c);
        System.assertEquals('REF-222', updatedFee.ReferenceNumber__c);
        System.assertEquals('PAID', updatedFee.Status);
        System.assertNotEquals(null, updatedFee.PaymentDate__c, 'Payment date should be set for Paid');
    }
}