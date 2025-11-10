@IsTest
private class PHOCSWaterSystemQueueableTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account record
        // 
        Account accParent = new Account(
            Name = 'Test Facility Parent',
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId()
        );
        insert accParent;
        Account acc = new Account(
            Name = 'Test Facility',
            WaterLicenseNumber__c = '502581',
            ParentId = accParent.Id,
            ParentAccount__c = accParent.Id,
            RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSourceIntake').getRecordTypeId(),
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001'
        );
        insert acc;
    }
    
    static Account getAccount(){
        return [Select Id, Name, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c from Account where Name = 'Test Facility' limit 1];
    }
    
    @IsTest
    static void testQueueableWithoutLicense_UsesApplicationPath() {        
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        
        Test.startTest();
        System.enqueueJob(new PHOCSWaterSystemQueueable(new List<Id>{ getAccount().Id }));
        Test.stopTest();
        
        Account updatedAcc = [
            SELECT WellTagNumber__c, AquiferNumber__c
            FROM Account
            WHERE Id = : getAccount().Id 
        ];
        
        System.assertEquals(Decimal.valueOf('49566'), updatedAcc.WellTagNumber__c);
        System.assertEquals(Decimal.valueOf('658'), updatedAcc.AquiferNumber__c);
    }
    
    @IsTest
    static void testQueueableHandlesBlankFields() {        
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        
        Test.startTest();
        System.enqueueJob(new PHOCSWaterSystemQueueable(new List<Id>{ getAccount().Id }));
        Test.stopTest();
        
        Account updatedAcc = [
            SELECT WellTagNumber__c, AquiferNumber__c
            FROM Account
            WHERE Id = :getAccount().Id
        ];
        
        System.assertEquals(49566, updatedAcc.WellTagNumber__c);
        System.assertEquals(658, updatedAcc.AquiferNumber__c);
    }
}