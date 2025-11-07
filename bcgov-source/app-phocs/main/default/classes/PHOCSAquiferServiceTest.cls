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
    static void testAquifierWorking(){
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        // Call service
        Object result = new PHOCSWaterRightsSystemService().call(
            'getAllData',
            new Map<String, Object>{
                'input'   => input,
                'output'  => output,
                'options' => options
            }
        );
        PHOCSAquifersResponseWrapper aquiferResp = PHOCSAquiferCallout.getAquiferDetails('658');
        Test.stopTest();
        
        System.debug('Aquifer Id: ' + aquiferResp.aquifer_id);
        System.debug('Aquifer Name: ' + aquiferResp.aquifer_name);
        System.debug('Litho Stratographic Unit: ' + aquiferResp.litho_stratographic_unit);
        System.assertEquals('658', ''+ aquiferResp.aquifer_id);
    }
    
    @IsTest
    static void testGetAquiferDetails_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSAquiferMock());
        
        PHOCSAquifersResponseWrapper aquiferResp = PHOCSAquiferCallout.getAquiferDetails('658');
        
        System.debug('Aquifer Name: ' + aquiferResp.aquifer_name);
        System.debug('Mapping Year: ' + aquiferResp.mapping_year);
        System.debug('Licence Count: ' + aquiferResp.licence_details.licence_count);
        
        System.assertEquals('Houston Bedrock', aquiferResp.aquifer_name);
        System.assertEquals(2020, aquiferResp.mapping_year);
        System.assertEquals(3, aquiferResp.licence_details.licence_count);
        Test.stopTest();
    }    
}