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
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001'
        );
        insert acc;
    }
    
    static Account getAccount(){
        return [Select Id, Name, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c from Account where Name = 'Test Facility' limit 1];
    }
    
    @isTest
    static void testGWellWorking(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWaterRightsCommonMock());
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        // Call service
        Object result = new PHOCSWaterRightsSystemService().call(
            'getAllData',
            new Map<String, Object>{
                'input'   => input,
                'output'  => output,
                'options' => options
            }
        );
        PHOCSWellResponseWrapper wellResp = PHOCSWellCallout.getWellDetails('129877');        
        Test.stopTest();
        
        System.debug(wellResp);
        System.debug('Well GUID: ' + wellResp.well_guid);
        System.debug('Latitude: ' + wellResp.latitude);
        System.debug('Drilling Method: ' + (wellResp.drilling_methods.isEmpty() ? null : wellResp.drilling_methods[0].description));
        
        System.assertEquals('129877', ''+ wellResp.well_tag_number);
    }
    
    
    @IsTest
    static void testGetWellDetails_Success() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWellMock());
        
        Test.startTest();        
        PHOCSWellResponseWrapper wellResp = PHOCSWellCallout.getWellDetails('129877');
        Test.stopTest();
        
        System.debug('Well GUID: ' + wellResp.well_guid);
        System.debug('Latitude: ' + wellResp.latitude);
        System.debug('Drilling Method: ' + (wellResp.drilling_methods.isEmpty() ? null : wellResp.drilling_methods[0].description));
        
        System.assertEquals('dbf618ed-9a8e-428f-89c1-3fc861a0721d', wellResp.well_guid);
        System.assertEquals(54.81518, wellResp.latitude);
        System.assertEquals('Dug', wellResp.drilling_methods[0].description);        
    }
}