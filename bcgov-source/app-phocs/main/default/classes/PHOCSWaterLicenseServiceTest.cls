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
    static void testWaterRightsCallout() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        Test.startTest();
        PHOCSWLSWaterRightsWrapper rightsWrapper = PHOCSWaterLicenseCallout.getWaterRightsByLicence('505833');
        System.debug('Water Rights Wrapper: ' + rightsWrapper);
        Test.stopTest();
        System.assertNotEquals(null, rightsWrapper);
        System.assertEquals('FeatureCollection', rightsWrapper.type);
        System.assertEquals(2, rightsWrapper.features.size());
        //System.assertEquals('505833', rightsWrapper.features[0].properties.LICENCE_NUMBER);
    }
    
    @isTest
    static void testWaterLicenseWorking(){
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
        PHOCSWLSWaterRightsWrapper rightsWrapper = PHOCSWaterLicenseCallout.getWaterRightsByLicence('505833');
        Test.stopTest();
        
        System.debug('Water Licence Type: ' + rightsWrapper.type);
        for (PHOCSWLSWaterRightsWrapper.Feature f : rightsWrapper.features) {
            System.debug('Feature ID: ' + f.id);
            System.debug('Licence Number: ' + f.properties.LICENCE_NUMBER);
            System.debug('Well Tag Number: ' + f.properties.WELL_TAG_NUMBER);
            System.debug('Purpose Use: ' + f.properties.PURPOSE_USE);
            System.debug('Quantity: ' + f.properties.QUANTITY);
            System.debug('Latitude / Longitude: ' + f.properties.LATITUDE + ' , ' + f.properties.LONGITUDE);
        }
        System.assertEquals('49566', ''+ rightsWrapper.features[0].properties.WELL_TAG_NUMBER);
    }
    
}