@IsTest
private class PHOCSPortalPaymentFeeItemServiceTest {
    @TestSetup
    static void setupData() {
        Account facility = new Account(
            Name = 'Portal Payment Test Facility',
            RecordTypeId = Schema.SObjectType.Account
                .getRecordTypeInfosByDeveloperName()
                .get('Facility')
                .getRecordTypeId()
        );
        insert facility;

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = facility.Id,
            Status = 'Due',
            RecordTypeId = Schema.SObjectType.RegulatoryTrxnFee
                .getRecordTypeInfosByDeveloperName()
                .get('PHOCSNonDairyTransactionFee')
                .getRecordTypeId()
        );
        insert fee;

        insert new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = fee.Id,
            RecordTypeId = Schema.SObjectType.RegulatoryTrxnFeeItem
                .getRecordTypeInfosByDeveloperName()
                .get('PHOCSNonDairyTransactionFeeItem')
                .getRecordTypeId(),
            Name = 'Portal Payment Test Item',
            FeeAmount = 100,
            Amount__c = 100,
            Status__c = 'Due'
        );
    }

    @IsTest
    static void failedAttemptThenSuccessfulRetryUpdatesSameItem() {
        RegulatoryTrxnFee fee = [SELECT Id FROM RegulatoryTrxnFee LIMIT 1];

        Test.startTest();
        PHOCSPortalPaymentFeeItemService.updatePaymentAttempt(
            fee.Id, false, 'Credit', 'Visa', null, null
        );
        PHOCSPortalPaymentFeeItemService.updatePaymentAttempt(
            fee.Id, true, 'Debit', 'MasterCard', 'RETRY-REFERENCE', Date.today()
        );
        Test.stopTest();

        RegulatoryTrxnFeeItem feeItem = [
            SELECT Status__c, Payment_Method__c, Payment_Type__c,
                   PaymentChannel__c, PaidBy__c, PaymentDate__c,
                   ReferenceNumber__c, PortalPaymentStatus__c
            FROM RegulatoryTrxnFeeItem
            LIMIT 1
        ];
        System.assertEquals('Paid', feeItem.Status__c);
        System.assertEquals('Debit', feeItem.Payment_Method__c);
        System.assertEquals('MasterCard', feeItem.Payment_Type__c);
        System.assertEquals('Portal', feeItem.PaymentChannel__c);
        System.assertEquals(Date.today(), feeItem.PaymentDate__c);
        System.assertEquals('RETRY-REFERENCE', feeItem.ReferenceNumber__c);
        System.assertEquals(null, feeItem.PortalPaymentStatus__c);
    }

    @IsTest
    static void normalizesGatewayCardValues() {
        System.assertEquals(
            'Debit',
            PHOCSPortalPaymentFeeItemService.normalizePaymentMethod(true)
        );
        System.assertEquals(
            'Credit',
            PHOCSPortalPaymentFeeItemService.normalizePaymentMethod(false)
        );
        System.assertEquals(
            'Visa',
            PHOCSPortalPaymentFeeItemService.normalizeCardType('V')
        );
        System.assertEquals(
            'MasterCard',
            PHOCSPortalPaymentFeeItemService.normalizeCardType('M')
        );
        System.assertEquals(
            'American Express',
            PHOCSPortalPaymentFeeItemService.normalizeCardType('AMEX')
        );
    }
}
