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
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001',
            PODNumber__c = 'PW200605',
            PurposeUseCode__c = 'WSA08'
        );
        insert acc;
    }
    
    static Account getAccount(){
        return [SELECT Id,
                WaterLicenseNumber__c,
                WaterLicenseApplicationNumber__c,
                WellTagNumber__c,
                AquiferNumber__c,
                PODNumber__c,
                PurposeUseCode__c,
                PHOCSWaterLicenseJSONRespnose__c,
                PHOCSWaterApplicationJSONResponse__c,
                PHOCSWellTagJSONResponse__c,
                PHOCSAquiferJSONResponse__c 
                FROM Account
                where Name = 'Test Facility' limit 1];
    }

    @IsTest
    static void testApplicationWithValidValue() {        
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Account acc = getAccount();
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        applicationServ.setValues(acc.WaterLicenseNumber__c, acc.PODNumber__c, acc.PurposeUseCode__c);
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData('WLA20160113-0001');
        Test.stopTest();
        
        System.Assert.isNotNull(applicationResp, 'Water License Application Service responses is blank');
    }
    
    @IsTest
    static void testApplicationWithBlankResponse() {     
        PHOCSWLSWaterHttpMock waterMock = new PHOCSWLSWaterHttpMock();
        waterMock.isBlankResponse = true;
        Test.setMock(HttpCalloutMock.class, waterMock);
        
        Account acc = getAccount();
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        applicationServ.setValues(acc.WaterLicenseNumber__c, acc.PODNumber__c, acc.PurposeUseCode__c);
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData('WLA20160113-0001');
        applicationServ.runIntegration(null);
        Test.stopTest();
        
        System.Assert.isNotNull(applicationResp, 'Water License Application Service responses is blank');
    }

    @IsTest
    static void testApplicationWithBlankValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        Account acc = getAccount();
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        applicationServ.setValues(null, null, null);
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData(null);
        Test.stopTest();
        
        System.assert(applicationResp.toString().contains('NoDataForLicenseApplication'), 'Expected Error Key');
    }
    
    @IsTest
    static void testApplicationWithServerError() {        
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());
        
        Account acc = getAccount();
        
        Map<String, Object> applicationResp;
        PHOCSWaterApplicationService applicationServ = new PHOCSWaterApplicationService();
        applicationServ.setValues(acc.WaterLicenseNumber__c, acc.PODNumber__c, acc.PurposeUseCode__c);
        
        Test.startTest();        
        applicationResp = applicationServ.mappingData('WLA20160113-0001');
        Test.stopTest();
        
        System.Assert.isNotNull(applicationResp, 'Water License Application Service responses is blank');
    }
}