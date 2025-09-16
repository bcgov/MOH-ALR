@IsTest
public class WLSWaterApplicationsWrapperTest {
    
    public Static String getResponse(){
        String jsonString = '{' +
            '"type": "FeatureCollection",' +
            '"features": [' +
            '{' +
            '"type": "Feature",' +
            '"id": "WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_APPLICTNS_SV.fid--1",' +
            '"geometry": {' +
            '"type": "Point",' +
            '"coordinates": [1451962.2133, 484764.7516]' +
            '},' +
            '"geometry_name": "SHAPE",' +
            '"properties": {' +
            '"WLS_WRA_SYSID": 233,' +
            '"APPLICATION_JOB_NUMBER": "128116",' +
            '"POD_NUMBER": "PW212743",' +
            '"POD_SUBTYPE": "PWD",' +
            '"FILE_NUMBER": "20028116",' +
            '"APPLICATION_STATUS": "Active Application",' +
            '"WELL_TAG_NUMBER": 18010,' +
            '"PURPOSE_USE_CODE": "03B",' +
            '"PURPOSE_USE": "03B - Irrigation: Private ",' +
            '"QTY_DIVERSION_MAX_RATE": null,' +
            '"QTY_UNITS_DIVERSION_MAX_RATE": "m3/sec",' +
            '"PRIMARY_APPLICANT_NAME": "0960308 B.C. Ltd. (125786)",' +
            '"ADDRESS_LINE_2": "2247 Sicamous Avenue",' +
            '"ADDRESS_LINE_4": "Coquitlam BC V3K 6R9",' +
            '"COUNTRY": "Canada",' +
            '"POSTAL_CODE": "V3K 6R9",' +
            '"LATITUDE": 49.20089,' +
            '"LONGITUDE": -119.79661,' +
            '"DISTRICT_PRECINCT_NAME": "Princeton / Keremeos",' +
            '"OBJECTID": 33342368' +
            '}' +
            '},' +
            '{' +
            '"type": "Feature",' +
            '"id": "WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_APPLICTNS_SV.fid--2",' +
            '"geometry": {' +
            '"type": "Point",' +
            '"coordinates": [1451521.8235, 484742.81]' +
            '},' +
            '"geometry_name": "SHAPE",' +
            '"properties": {' +
            '"WLS_WRA_SYSID": 234,' +
            '"APPLICATION_JOB_NUMBER": "128116",' +
            '"POD_NUMBER": "PW212740",' +
            '"POD_SUBTYPE": "PWD",' +
            '"FILE_NUMBER": "20028116",' +
            '"APPLICATION_STATUS": "Active Application",' +
            '"WELL_TAG_NUMBER": 1111,' +
            '"PURPOSE_USE_CODE": "03B",' +
            '"PURPOSE_USE": "03B - Irrigation: Private ",' +
            '"QTY_DIVERSION_MAX_RATE": null,' +
            '"QTY_UNITS_DIVERSION_MAX_RATE": "m3/sec",' +
            '"PRIMARY_APPLICANT_NAME": "0960308 B.C. Ltd. (125786)",' +
            '"ADDRESS_LINE_2": "2247 Sicamous Avenue",' +
            '"ADDRESS_LINE_4": "Coquitlam BC V3K 6R9",' +
            '"COUNTRY": "Canada",' +
            '"POSTAL_CODE": "V3K 6R9",' +
            '"LATITUDE": 49.20104,' +
            '"LONGITUDE": -119.80265,' +
            '"DISTRICT_PRECINCT_NAME": "Princeton / Keremeos",' +
            '"OBJECTID": 33342369' +
            '}' +
            '}' +
            '],' +
            '"totalFeatures": 2,' +
            '"numberMatched": 2,' +
            '"numberReturned": 2,' +
            '"timeStamp": "2025-09-16T07:37:46.997Z",' +
            '"crs": {' +
            '"type": "name",' +
            '"properties": {"name": "urn:ogc:def:crs:EPSG::3005"}' +
            '}' +
            '}';
        return jsonString;
    }
    
    @IsTest
    static void testParseWaterApplicationsJSON() {
        String jsonString = getResponse();        
        
        // Deserialize JSON
        WLSWaterApplicationsWrapper wrapper = (WLSWaterApplicationsWrapper) JSON.deserialize(jsonString, WLSWaterApplicationsWrapper.class);
        
        // Debug wrapper properties
        System.debug('Wrapper Type: ' + wrapper.type);
        System.debug('Total Features: ' + wrapper.features.size());
        
        // Loop through features and debug key properties
        for (WLSWaterApplicationsWrapper.Feature f : wrapper.features) {
            System.debug('Feature ID: ' + f.id);
            System.debug('Application Job Number: ' + f.properties.APPLICATION_JOB_NUMBER);
            System.debug('Well Tag Number: ' + f.properties.WELL_TAG_NUMBER);
            System.debug('Purpose Use: ' + f.properties.PURPOSE_USE);
            System.debug('Latitude / Longitude: ' + f.properties.LATITUDE + ' , ' + f.properties.LONGITUDE);
        }
        
        // Assertions
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals('FeatureCollection', wrapper.type, 'Type should be FeatureCollection');
        System.assertEquals(2, wrapper.features.size(), 'There should be 2 features');
    }
}