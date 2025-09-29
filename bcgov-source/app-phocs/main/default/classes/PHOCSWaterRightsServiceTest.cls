@IsTest
private class PHOCSWaterRightsServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test Account record
        Account acc = new Account(
            Name = 'Test Facility',
            WaterLicenseNumber__c = '502581',
            WaterLicenseApplicationNumber__c = 'WLA20160113-0001'
        );
        insert acc;
    }
    
    @isTest
    static void testGWellWorking(){
        PHOCSWellResponseWrapper wellResp = PHOCSGwellsService.getWellDetails('129877');
        System.debug('Well GUID: ' + wellResp.well_guid);
        System.debug('Latitude: ' + wellResp.latitude);
        System.debug('Drilling Method: ' + (wellResp.drilling_methods.isEmpty() ? null : wellResp.drilling_methods[0].description));
    }
    
    @isTest
    static void testAquifierWorking(){
        PHOCSAquifersResponseWrapper aquiferResp = PHOCSGwellsService.getAquiferDetails('658');
        System.debug('Aquifer Id: ' + aquiferResp.aquifer_id);
        System.debug('Aquifer Name: ' + aquiferResp.aquifer_name);
        System.debug('Litho Stratographic Unit: ' + aquiferResp.litho_stratographic_unit);
    }
    
    @isTest
    static void testWaterLicenseWorking(){
        PHOCSWLSWaterRightsWrapper rightsWrapper = PHOCSWLSWaterService.getWaterRightsByLicence('505833');
        System.debug('Water Licence Type: ' + rightsWrapper.type);
        for (PHOCSWLSWaterRightsWrapper.Feature f : rightsWrapper.features) {
            System.debug('Feature ID: ' + f.id);
            System.debug('Licence Number: ' + f.properties.LICENCE_NUMBER);
            System.debug('Well Tag Number: ' + f.properties.WELL_TAG_NUMBER);
            System.debug('Purpose Use: ' + f.properties.PURPOSE_USE);
            System.debug('Quantity: ' + f.properties.QUANTITY);
            System.debug('Latitude / Longitude: ' + f.properties.LATITUDE + ' , ' + f.properties.LONGITUDE);
        }
    }
    
    @isTest
    static void testWaterLicenseApplicationWorking(){
        PHOCSWLSWaterApplicationsWrapper applicationsWrapper = PHOCSWLSWaterService.getWaterApplicationsByJob('128116');
        System.debug('Water Licence Application Type: ' + applicationsWrapper.type);
        for (PHOCSWLSWaterApplicationsWrapper.Feature f : applicationsWrapper.features) {
            System.debug('Feature ID: ' + f.id);
            System.debug('Application Job Number: ' + f.properties.APPLICATION_JOB_NUMBER);
            System.debug('Well Tag Number: ' + f.properties.WELL_TAG_NUMBER);
            System.debug('Purpose Use: ' + f.properties.PURPOSE_USE);
            System.debug('Latitude / Longitude: ' + f.properties.LATITUDE + ' , ' + f.properties.LONGITUDE);
        }
    }    
}