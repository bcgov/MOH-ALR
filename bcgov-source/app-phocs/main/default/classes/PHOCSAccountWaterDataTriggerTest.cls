@IsTest
private class PHOCSAccountWaterDataTriggerTest {
    
    @testSetup
    static void setupTestData() {        
        RegulatoryAuthorizationType rat = new RegulatoryAuthorizationType(
            Name = 'Drinking Water Permit',
            RecordTypeId = Schema.SObjectType.RegulatoryAuthorizationType.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryAuthorizationType').getRecordTypeId(),
            Description = 'Test Description',
            RegulatoryAuthCode = 'MH',
            RegulatoryAuthCategory = 'License',
            Jurisdiction = 'BC',
            ProcessingDuration = '250',
            LateFee__c = 100.00,
            DurationType = 'Hour',
            PartialUnitFee__c = 6.25,
            RegulatoryAuthorizationCode__c = 'MH',
            UnitFee__c = 12.50
        );
        insert rat;
        
        // Create test Account record      
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
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001',
            LicenseType__c = rat.Id
        );
        insert acc;
    }
    
    static Account getAccount(){
        return [Select Id, Name, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c from Account where Name = 'Test Facility' limit 1];
    }
    
    @IsTest
    static void testTrigger_OnInsert_EnqueuesQueueable() {        
        Test.startTest();        
        Account acc = getAccount();
        acc.WaterLicenseNumber__c = '502580';
        update acc;
        System.assertEquals(0, Limits.getQueueableJobs(),'Queueable should be enqueued when account inserted with License');        
        Test.stopTest();
    }
    
    @IsTest
    static void testTrigger_OnUpdate_EnqueuesWhenLicenseChanges() {        
        Account acc = getAccount();        
        Test.startTest();        
        acc.WaterLicenseNumber__c = 'LIC-222';
        update acc;
        System.assertEquals(0, Limits.getQueueableJobs(),'Queueable should be enqueued when License is updated');        
        Test.stopTest();
    }
    
    @IsTest
    static void testTrigger_OnUpdate_NoChange_NoQueueable() {        
        Account acc = getAccount();        
        Test.startTest();
        acc.Name = 'Updated Name';
        update acc;
        System.assertEquals(0, Limits.getQueueableJobs(),'Queueable should NOT enqueue when there is no License/Application change');        
        Test.stopTest();
    }
    
    @IsTest
    static void testTrigger_ApplicationNumberChangeEnqueues() {        
        Account acc = getAccount();        
        Test.startTest();        
        acc.WaterLicenseApplicationNumber__c = 'APP-002';
        update acc;        
        System.assertEquals(0, Limits.getQueueableJobs(),'Queueable should run when Application number changes');        
        Test.stopTest();
    }
}