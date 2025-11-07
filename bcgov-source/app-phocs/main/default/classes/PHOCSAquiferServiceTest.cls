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
        return [Select Id, Name, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c from Account where Name = 'Test Facility' limit 1];
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
}