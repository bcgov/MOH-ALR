@IsTest
public class PHOCSWellsServiceTest {
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
    
    @isTest
    static void testGWellWithValidValue(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWellMock());       
        Map<String, Object> wellResp;
        PHOCSWellsService wellServ = new PHOCSWellsService();
        
        Test.startTest();        
        wellResp = wellServ.mappingData('129877');
        Test.stopTest();
        
        System.Assert.isNotNull(wellResp, 'Well Service responses is not blank');
    }
    
    @isTest
    static void testGWellWithBlankResponse(){
        PHOCSWellMock wellMock = new PHOCSWellMock();
        wellMock.isBlankResponse = true;
        Test.setMock(HttpCalloutMock.class, wellMock);       
        Map<String, Object> wellResp;
        PHOCSWellsService wellServ = new PHOCSWellsService();
        
        Test.startTest();        
        wellResp = wellServ.mappingData('129877');
        Test.stopTest();
        
        System.Assert.isNotNull(wellResp, 'Well Service responses is not blank');
    }
    
    @isTest
    static void testGWellWithBlankValue(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWellMock());       
        Map<String, Object> wellResp;
        PHOCSWellsService wellServ = new PHOCSWellsService();
        
        Test.startTest();        
        wellResp = wellServ.mappingData(null);
        Test.stopTest();
        
        System.assert(wellResp.toString().contains('NoDataForGWell'), 'Expected Error Key');
    }
    
    @isTest
    static void testGWellWithServerError(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());       
        Map<String, Object> wellResp;
        PHOCSWellsService wellServ = new PHOCSWellsService();
        
        Test.startTest();        
        wellResp = wellServ.mappingData('129877');
        Test.stopTest();
        
        System.Assert.isNotNull(wellResp, 'Well Service responses is not blank');
    }
}