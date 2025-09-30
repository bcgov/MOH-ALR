@IsTest
private class PHOCSWaterRightsServiceTest {
    
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
        Test.setMock(HttpCalloutMock.class, new PHOCSGwellsServiceMock());
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        // Call service
        Object result = new PHOCSWaterRightsService().call(
            'getGWellDetails',
            new Map<String, Object>{
                'input'   => input,
                'output'  => output,
                'options' => options
            }
        );
        PHOCSWellResponseWrapper wellResp = PHOCSGwellsService.getWellDetails('129877');        
        Test.stopTest();
        
        System.debug(wellResp);
        System.debug('Well GUID: ' + wellResp.well_guid);
        System.debug('Latitude: ' + wellResp.latitude);
        System.debug('Drilling Method: ' + (wellResp.drilling_methods.isEmpty() ? null : wellResp.drilling_methods[0].description));
        
        System.assertEquals('129877', ''+ wellResp.well_tag_number);
    }
    
    @isTest
    static void testAquifierWorking(){
        Test.setMock(HttpCalloutMock.class, new PHOCSGwellsServiceMock());
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        // Call service
        Object result = new PHOCSWaterRightsService().call(
            'getAquifersDetails',
            new Map<String, Object>{
                'input'   => input,
                'output'  => output,
                'options' => options
            }
        );
        PHOCSAquifersResponseWrapper aquiferResp = PHOCSGwellsService.getAquiferDetails('658');
        Test.stopTest();
        
        System.debug('Aquifer Id: ' + aquiferResp.aquifer_id);
        System.debug('Aquifer Name: ' + aquiferResp.aquifer_name);
        System.debug('Litho Stratographic Unit: ' + aquiferResp.litho_stratographic_unit);
        System.assertEquals('658', ''+ aquiferResp.aquifer_id);
    }
    
    @isTest
    static void testWaterLicenseWorking(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        // Call service
        Object result = new PHOCSWaterRightsService().call(
            'getWaterLicenseDetails',
            new Map<String, Object>{
                'input'   => input,
                'output'  => output,
                'options' => options
            }
        );
        PHOCSWLSWaterRightsWrapper rightsWrapper = PHOCSWLSWaterService.getWaterRightsByLicence('505833');
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
    
    @isTest
    static void testWaterLicenseApplicationWorking(){
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());
        
        // Prepare input for FlexCard-style call
        Map<String, Object> input   = new Map<String, Object>{ 'recordId' => getAccount().Id };
        Map<String, Object> output  = new Map<String, Object>();
        Map<String, Object> options = new Map<String, Object>();        
        
        Test.startTest();
        // Call service
        Object result = new PHOCSWaterRightsService().call(
            'getWaterLicenseApplicationDetails',
            new Map<String, Object>{
                'input'   => input,
                'output'  => output,
                'options' => options
            }
        );
        PHOCSWLSWaterApplicationsWrapper applicationsWrapper = PHOCSWLSWaterService.getWaterApplicationsByJob('128116');
        Test.stopTest();
        
        System.debug('Water Licence Application Type: ' + applicationsWrapper.type);
        for (PHOCSWLSWaterApplicationsWrapper.Feature f : applicationsWrapper.features) {
            System.debug('Feature ID: ' + f.id);
            System.debug('Application Job Number: ' + f.properties.APPLICATION_JOB_NUMBER);
            System.debug('Well Tag Number: ' + f.properties.WELL_TAG_NUMBER);
            System.debug('Purpose Use: ' + f.properties.PURPOSE_USE);
            System.debug('Latitude / Longitude: ' + f.properties.LATITUDE + ' , ' + f.properties.LONGITUDE);
        }
        System.assertEquals('128116', ''+ applicationsWrapper.features[0].properties.APPLICATION_JOB_NUMBER);
    }    
}