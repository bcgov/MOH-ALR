@IsTest
private class PHOCSWLSWaterServiceTest {

    @IsTest
    static void testWaterRightsCallout() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());

        PHOCSWLSWaterRightsWrapper rightsWrapper = PHOCSWLSWaterService.getWaterRightsByLicence('505833');
        System.debug('Water Rights Wrapper: ' + rightsWrapper);

        System.assertNotEquals(null, rightsWrapper);
        System.assertEquals('FeatureCollection', rightsWrapper.type);
        System.assertEquals(2, rightsWrapper.features.size());
        //System.assertEquals('505833', rightsWrapper.features[0].properties.LICENCE_NUMBER);
    }

    @IsTest
    static void testWaterApplicationsCallout() {
        Test.setMock(HttpCalloutMock.class, new PHOCSWLSWaterHttpMock());

        PHOCSWLSWaterApplicationsWrapper applicationsWrapper = PHOCSWLSWaterService.getWaterApplicationsByJob('128116');
        System.debug('Water Applications Wrapper: ' + applicationsWrapper);

        System.assertNotEquals(null, applicationsWrapper);
        System.assertEquals('FeatureCollection', applicationsWrapper.type);
        System.assertEquals(2, applicationsWrapper.features.size());
        System.assertEquals('128116', applicationsWrapper.features[0].properties.APPLICATION_JOB_NUMBER);
    }
}