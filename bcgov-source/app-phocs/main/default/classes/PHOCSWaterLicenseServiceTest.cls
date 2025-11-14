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
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001'
        );
        insert acc;
    }
    
    static Account getAccount(){
        return [Select Id, Name, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c from Account where Name = 'Test Facility' limit 1];
    }
    
    @IsTest
    static void testWaterWithValidLicenseValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.Assert.isNotNull(waterResp, 'Water License Service responses is not blank');
    }
    
    @IsTest
    static void testWaterWithValidPODNumberValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setCalloutType('podNumber');
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.Assert.isNotNull(waterResp, 'Water License Service responses is not blank');
    }
    
    @IsTest
    static void testWaterWithValidPurposeCodeValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setCalloutType('purposeCode');
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.Assert.isNotNull(waterResp, 'Water License Service responses is not blank');
    }
    
    @isTest
    static void testWaterWithBlankValue(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        
        Test.startTest();        
        waterResp = waterServ.mappingData(null);
        Test.stopTest();
        
        System.assert(waterResp.toString().contains('NoDataForWaterLicense'), 'Expected Error Key');
    }    
    
    @isTest
    static void testWaterWithPOD_ServerError(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setCalloutType('podNumber');
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.assert(waterResp.toString().contains('NoDataForWaterLicense'), 'Expected Error Key');
    }
    
    @isTest
    static void testWaterWithPurpose_ServerError(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setCalloutType('purposeCode');
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.assert(waterResp.toString().contains('NoDataForWaterLicense'), 'Expected Error Key');
    }
    
    @isTest
    static void testWaterWithLicense_ServerError(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());       
        Map<String, Object> waterResp;
        PHOCSWaterLicenseService waterServ = new PHOCSWaterLicenseService();
        waterServ.setCalloutType('license');
        
        Test.startTest();        
        waterResp = waterServ.mappingData('505833');
        Test.stopTest();
        
        System.assert(waterResp.toString().contains('NoDataForWaterLicense'), 'Expected Error Key');
    }
}