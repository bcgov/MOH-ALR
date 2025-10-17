@IsTest
private class PHOCSGwellsServiceTest {
    
    @IsTest
    static void testGetWellDetails_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSGwellsServiceMock());
        
        PHOCSWellResponseWrapper wellResp = PHOCSGwellsService.getWellDetails('129877');
        
        System.debug('Well GUID: ' + wellResp.well_guid);
        System.debug('Latitude: ' + wellResp.latitude);
        System.debug('Drilling Method: ' + (wellResp.drilling_methods.isEmpty() ? null : wellResp.drilling_methods[0].description));
        
        System.assertEquals('dbf618ed-9a8e-428f-89c1-3fc861a0721d', wellResp.well_guid);
        System.assertEquals(54.81518, wellResp.latitude);
        System.assertEquals('Dug', wellResp.drilling_methods[0].description);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetAquiferDetails_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PHOCSGwellsServiceMock());
        
        PHOCSAquifersResponseWrapper aquiferResp = PHOCSGwellsService.getAquiferDetails('658');
        
        System.debug('Aquifer Name: ' + aquiferResp.aquifer_name);
        System.debug('Mapping Year: ' + aquiferResp.mapping_year);
        System.debug('Licence Count: ' + aquiferResp.licence_details.licence_count);
        
        System.assertEquals('Houston Bedrock', aquiferResp.aquifer_name);
        System.assertEquals(2020, aquiferResp.mapping_year);
        System.assertEquals(3, aquiferResp.licence_details.licence_count);
        Test.stopTest();
    }
}