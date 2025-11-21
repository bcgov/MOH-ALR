@isTest
private class PHOCSPaymentControllerTest {

    @isTest
    static void testGetPaymentSystemRedirectInfo_GlobalPay() {
        // Set up Account with Health Authority
        Account acc = new Account(
            Name = 'Test Facility',
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId(),
            Type = 'Drinking Water',
            CategoryL1__c = 'Community Water System',
            CategoryL2__c = 'Local Gov System',
            HealthAuthority__c = 'Northern Health - NH',
            Phone = '1234567890'     
        );
        insert acc;

        // Create Regulatory Transaction Fee
        RegulatoryTrxnFee trxnFee = new RegulatoryTrxnFee(AccountId = acc.Id,Status = 'Due');
        insert trxnFee;

        // Call method
        Test.startTest();
        PHOCSPaymentController.PaymentSystemResponse res = PHOCSPaymentController.getPaymentSystemRedirectInfo(trxnFee.Id);
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(true, res.useGlobalPay);
        System.assertEquals(false, res.useMoneris);
    }

    @isTest
    static void testGetPaymentSystemRedirectInfo_Moneris() {

        Account acc = new Account(
            Name = 'Test Facility',
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId(),
            Type = 'Drinking Water',
            CategoryL1__c = 'Community Water System',
            CategoryL2__c = 'Local Gov System',
            HealthAuthority__c = 'Vancouver Coastal Health - VCH',
            Phone = '1234567890'     
        );
        insert acc;

        // Create Regulatory Transaction Fee
        RegulatoryTrxnFee trxnFee = new RegulatoryTrxnFee(AccountId = acc.Id,Status = 'Due');
        insert trxnFee;

        // Call method
        Test.startTest();
        PHOCSPaymentController.PaymentSystemResponse res = PHOCSPaymentController.getPaymentSystemRedirectInfo(trxnFee.Id);
        Test.stopTest();

        System.assertNotEquals(null, res);
        System.assertEquals(true, res.useMoneris);
        System.assertEquals(false, res.useGlobalPay);
    }
}