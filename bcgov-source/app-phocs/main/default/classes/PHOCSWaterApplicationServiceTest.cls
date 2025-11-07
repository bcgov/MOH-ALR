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
    static void testMappingData_success() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Test.startTest();
            PHOCSWaterApplicationService service = new PHOCSWaterApplicationService();
            Map<String, Object> result = service.mappingData('WLA20160113-0001');
        Test.stopTest();

        System.assertEquals('Active Application', result.get('Application_WaterLicenceApplicationStatus'));
        System.assertEquals(18010, result.get('Application_WellTagNumber'));
    }

    @IsTest
    static void testMappingData_blankInput() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Test.startTest();
            PHOCSWaterApplicationService service = new PHOCSWaterApplicationService();
            Map<String, Object> result = service.mappingData(null);
        Test.stopTest();

        System.assertEquals(
            PHOCSWaterApplicationService.errorMsg, 
            result.get(PHOCSWaterApplicationService.errorKey)
        );
    }

    @IsTest
    static void testCheckValidation_nullResponse() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Test.startTest();
            PHOCSWaterApplicationService service = new PHOCSWaterApplicationService();
            Boolean isValid = service.checkValidation(null);
        Test.stopTest();

        System.assertEquals(false, isValid);
    }
}