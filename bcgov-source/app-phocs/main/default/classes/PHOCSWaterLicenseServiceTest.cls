@isTest
public class PHOCSWaterLicenseServiceTest {
    
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
    static void testWaterWithValidLicenseValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        
        Account acc = getAccount();
        
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setValues(acc.WaterLicenseNumber__c, acc.PODNumber__c, acc.PurposeUseCode__c);
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.Assert.isNotNull(waterResp, 'Water License Service responses is not blank');
    }
    
    @IsTest
    static void testWaterWithBlankResponse() {
        PHOCSWaterRightsCommonMock commonMock = new PHOCSWaterRightsCommonMock();
        commonMock.isBlankResponse = true;
        
        Test.setMock(HttpCalloutMock.class, commonMock);
        
        Account acc = getAccount();
        
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setValues(acc.WaterLicenseNumber__c, acc.PODNumber__c, acc.PurposeUseCode__c);
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.Assert.isNotNull(waterResp, 'Water License Service responses is not blank');
    }
    
    @isTest
    static void testWaterWithBlankValue(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());       
        
        Account acc = getAccount();
        
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setValues(null, null, null);
        
        Test.startTest();        
        waterResp = waterServ.mappingData(null);
        waterServ.runIntegration(null);
        Test.stopTest();
        
        System.assert(waterResp.toString().contains('NoDataForWaterLicense'), 'Expected Error Key');
    }
    
    @isTest
    static void testWaterWithLicense_ServerError(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());
        
        Account acc = getAccount();
        
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setValues(acc.WaterLicenseNumber__c, acc.PODNumber__c, acc.PurposeUseCode__c);
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.assert(waterResp.toString().contains('NoDataForWaterLicense'), 'Expected Error Key');
    }
}