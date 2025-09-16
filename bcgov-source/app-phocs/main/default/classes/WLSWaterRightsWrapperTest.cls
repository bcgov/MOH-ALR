@IsTest
public class WLSWaterRightsWrapperTest {
    
    public static String getResponse(){
        String jsonString = '{' +
            '"type": "FeatureCollection",' +
            '"features": [' +
            '{' +
            '"type": "Feature",' +
            '"id": "WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV.fid--68dfca9f_1995129ac20_2064",' +
            '"geometry": {' +
            '"type": "Point",' +
            '"coordinates": [955964.5835, 1041014.9607]' +
            '},' +
            '"geometry_name": "SHAPE",' +
            '"properties": {' +
            '"WLS_WRL_SYSID": 104649,' +
            '"POD_NUMBER": "PW209334",' +
            '"POD_SUBTYPE": "PWD",' +
            '"POD_DIVERSION_TYPE": null,' +
            '"POD_STATUS": "Active",' +
            '"FILE_NUMBER": "20027805",' +
            '"WELL_TAG_NUMBER": 130048,' +
            '"LICENCE_NUMBER": "505833",' +
            '"LICENCE_STATUS": "Current",' +
            '"LICENCE_STATUS_DATE": "2024-04-30Z",' +
            '"PRIORITY_DATE": "2006-09-01Z",' +
            '"EXPIRY_DATE": null,' +
            '"PURPOSE_USE_CODE": "WSA08",' +
            '"PURPOSE_USE": "WSA08 - Livestock & Animal ",' +
            '"SOURCE_NAME": "658",' +
            '"REDIVERSION_IND": "N",' +
            '"QUANTITY": 306.9,' +
            '"QUANTITY_UNITS": "m3/year",' +
            '"QUANTITY_FLAG": "T",' +
            '"QUANTITY_FLAG_DESCRIPTION": "Total demand for purpose, one POD.",' +
            '"QTY_DIVERSION_MAX_RATE": null,' +
            '"QTY_UNITS_DIVERSION_MAX_RATE": "m3/sec",' +
            '"HYDRAULIC_CONNECTIVITY": "Unknown",' +
            '"PERMIT_OVER_CROWN_LAND_NUMBER": null,' +
            '"PRIMARY_LICENSEE_NAME": "PRIVATE INDIVIDUAL NAME",' +
            '"ADDRESS_LINE_1": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"ADDRESS_LINE_2": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"ADDRESS_LINE_3": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"ADDRESS_LINE_4": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"COUNTRY": "PRIVATE INDIVIDUAL COUNTRY",' +
            '"POSTAL_CODE": "PRIVATE INDIVIDUAL POSTAL CODE",' +
            '"LATITUDE": 54.36907,' +
            '"LONGITUDE": -126.6794,' +
            '"DISTRICT_PRECINCT_NAME": "Hazelton / Smithers",' +
            '"OBJECTID": 209088839,' +
            '"SE_ANNO_CAD_DATA": null' +
            '}' +
            '},' +
            '{' +
            '"type": "Feature",' +
            '"id": "WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV.fid--68dfca9f_1995129ac20_2065",' +
            '"geometry": {' +
            '"type": "Point",' +
            '"coordinates": [955964.5835, 1041014.9607]' +
            '},' +
            '"geometry_name": "SHAPE",' +
            '"properties": {' +
            '"WLS_WRL_SYSID": 104650,' +
            '"POD_NUMBER": "PW209334",' +
            '"POD_SUBTYPE": "PWD",' +
            '"POD_DIVERSION_TYPE": null,' +
            '"POD_STATUS": "Active",' +
            '"FILE_NUMBER": "20027805",' +
            '"WELL_TAG_NUMBER": 130048,' +
            '"LICENCE_NUMBER": "505833",' +
            '"LICENCE_STATUS": "Current",' +
            '"LICENCE_STATUS_DATE": "2024-04-30Z",' +
            '"PRIORITY_DATE": "2006-09-01Z",' +
            '"EXPIRY_DATE": null,' +
            '"PURPOSE_USE_CODE": "WSA08",' +
            '"PURPOSE_USE": "WSA08 - Livestock & Animal ",' +
            '"SOURCE_NAME": "658",' +
            '"REDIVERSION_IND": "N",' +
            '"QUANTITY": 306.9,' +
            '"QUANTITY_UNITS": "m3/year",' +
            '"QUANTITY_FLAG": "T",' +
            '"QUANTITY_FLAG_DESCRIPTION": "Total demand for purpose, one POD.",' +
            '"QTY_DIVERSION_MAX_RATE": null,' +
            '"QTY_UNITS_DIVERSION_MAX_RATE": "m3/sec",' +
            '"HYDRAULIC_CONNECTIVITY": "Unknown",' +
            '"PERMIT_OVER_CROWN_LAND_NUMBER": null,' +
            '"PRIMARY_LICENSEE_NAME": "PRIVATE INDIVIDUAL NAME",' +
            '"ADDRESS_LINE_1": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"ADDRESS_LINE_2": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"ADDRESS_LINE_3": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"ADDRESS_LINE_4": "PRIVATE INDIVIDUAL ADDRESS",' +
            '"COUNTRY": "PRIVATE INDIVIDUAL COUNTRY",' +
            '"POSTAL_CODE": "PRIVATE INDIVIDUAL POSTAL CODE",' +
            '"LATITUDE": 54.36907,' +
            '"LONGITUDE": -126.6794,' +
            '"DISTRICT_PRECINCT_NAME": "Hazelton / Smithers",' +
            '"OBJECTID": 209088840,' +
            '"SE_ANNO_CAD_DATA": null' +
            '}' +
            '}' +
            '],' +
            '"totalFeatures": 2,' +
            '"numberMatched": 2,' +
            '"numberReturned": 2,' +
            '"timeStamp": "2025-09-16T06:44:58.816Z",' +
            '"crs": {' +
            '"type": "name",' +
            '"properties": {' +
            '"name": "urn:ogc:def:crs:EPSG::3005"' +
            '}' +
            '}' +
            '}';
        return jsonString;
    }
    
    @IsTest
    static void testParseWaterRightsJSON() {
        String jsonString = getResponse();        
        
        // Deserialize JSON
        WLSWaterRightsWrapper resp = (WLSWaterRightsWrapper) JSON.deserialize(jsonString, WLSWaterRightsWrapper.class);
        
        // Debug wrapper object
        System.debug('Parsed Wrapper Type: ' + resp.type);
        System.debug('Total Features: ' + resp.features.size());
        
        // Loop through features and debug key properties
        for (WLSWaterRightsWrapper.Feature f : resp.features) {
            System.debug('Feature ID: ' + f.id);
            System.debug('Licence Number: ' + f.properties.LICENCE_NUMBER);
            System.debug('Well Tag Number: ' + f.properties.WELL_TAG_NUMBER);
            System.debug('Purpose Use: ' + f.properties.PURPOSE_USE);
            System.debug('Quantity: ' + f.properties.QUANTITY);
            System.debug('Latitude / Longitude: ' + f.properties.LATITUDE + ' , ' + f.properties.LONGITUDE);
        }
        
        // Assertions
        System.assertNotEquals(null, resp, 'Wrapper should not be null');
        System.assertEquals('FeatureCollection', resp.type, 'Type should be FeatureCollection');
        System.assertEquals(2, resp.features.size(), 'There should be 2 feature');
        System.assertEquals('505833', resp.features[0].properties.LICENCE_NUMBER, 'Licence number should match');
        System.assertEquals(104649, resp.features[0].properties.WLS_WRL_SYSID, 'SYSID should match');
    }
}