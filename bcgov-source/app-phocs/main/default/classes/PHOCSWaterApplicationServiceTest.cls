@IsTest
private class PHOCSWaterApplicationServiceTest {
    
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

    @IsTest
    static void testApplicationWithValidValue() {        
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData('WLA20160113-0001');
        Test.stopTest();
        
        System.Assert.isNotNull(applicationResp, 'Water License Application Service responses is blank');
    }

    @IsTest
    static void testApplicationWithBlankValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData(null);
        Test.stopTest();
        
        System.assert(applicationResp.toString().contains('NoDataForLicenseApplication'), 'Expected Error Key');
    }
    
    @IsTest
    static void testApplicationWithServerError() {        
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData('WLA20160113-0001');
        Test.stopTest();
        
        System.Assert.isNotNull(applicationResp, 'Water License Application Service responses is blank');
    }
}