@IsTest
public class PHOCSAquiferServiceTest {
    
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
    static void testAquifierWithValidValue(){
        Test.setMock(HttpCalloutMock.class, new PHOCSAquiferMock());       
        Map<String, Object> aquiferResp;
        PHOCSAquiferService aquiferServ = new PHOCSAquiferService();
        
        Test.startTest();        
        aquiferResp = aquiferServ.mappingData('658');
        Test.stopTest();
        
        System.Assert.isNotNull(aquiferResp, 'Aquifer responses is not blank');
    }
    
    @isTest
    static void testAquifierWithBlankResponse(){
        PHOCSAquiferMock aquiferMock = new PHOCSAquiferMock();
        aquiferMock.isBlankResponse = true;
        Test.setMock(HttpCalloutMock.class, aquiferMock);       
        Map<String, Object> aquiferResp;
        PHOCSAquiferService aquiferServ = new PHOCSAquiferService();
        
        Test.startTest();        
        aquiferResp = aquiferServ.mappingData('658');
        Test.stopTest();
        
        System.Assert.isNotNull(aquiferResp, 'Aquifer responses is not blank');
    }
    
    @IsTest
    static void testAquifierWithBlankValue() {
        Test.setMock(HttpCalloutMock.class, new PHOCSAquiferMock());       
        Map<String, Object> aquiferResp;
        PHOCSAquiferService aquiferServ = new PHOCSAquiferService();
        
        Test.startTest();        
        aquiferResp = aquiferServ.mappingData(null);
        Test.stopTest();
        
        System.assert(aquiferResp.toString().contains('NoDataForAquifer'), 'Expected Error Key');
    }    
    
    @isTest
    static void testAquifierWithServerError(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsServerErrorMock());       
        Map<String, Object> aquiferResp;
        PHOCSAquiferService aquiferServ = new PHOCSAquiferService();
        
        Test.startTest();        
        aquiferResp = aquiferServ.mappingData('658');
        Test.stopTest();
        
        System.Assert.isNotNull(aquiferResp, 'Aquifer responses is not blank');
    }
}