public with sharing class PHOCSWaterKeys {
    
    // user-facing key
    public static final String KEY_NO_WL 	= 'NoDataForWaterLicense';
    public static final String KEY_NO_WLA 	= 'NoDataForLicenseApplication';
    public static final String KEY_NO_WELL 	= 'NoDataForGWell';
    public static final String KEY_NO_AQ 	= 'NoDataForAquifer';
    
    // user-facing messages
    public static final String MSG_NO_WL   = 'No water license details available.';
    public static final String MSG_NO_WLA  = 'No water license application details available.';
    public static final String MSG_NO_WELL = 'No well details available.';
    public static final String MSG_NO_AQ   = 'No aquifer details available.';
    
    // water licence details keys
    public static String LIC_STATUS;
    public static Integer LIC_WELL_TAG;
    public static String LIC_PURPOSE;
    public static String LIC_PURPOSE_CD;
    public static Double LIC_QUAN;
    public static String LIC_QUAN_UNT;
    public static String LIC_POD_NUM;
    public static String LIC_POD_TYPE;
    public static String LIC_POD_SUBT;
    public static String LIC_SRC_WATER;
    
    public static void setLicenseDetails(PHOCSWLSWaterRightsWrapper waterLicenseResponse){
        LIC_STATUS = waterLicenseResponse.features[0]?.properties?.LICENCE_STATUS;
        LIC_WELL_TAG = waterLicenseResponse.features[0]?.properties?.WELL_TAG_NUMBER;
        LIC_PURPOSE = waterLicenseResponse.features[0]?.properties?.PURPOSE_USE;
        LIC_PURPOSE_CD = waterLicenseResponse.features[0]?.properties?.PURPOSE_USE_CODE;
        LIC_QUAN = waterLicenseResponse.features[0]?.properties?.QUANTITY;
        LIC_QUAN_UNT = waterLicenseResponse.features[0]?.properties?.QUANTITY_UNITS;
        LIC_POD_NUM = waterLicenseResponse.features[0]?.properties?.POD_NUMBER;
        LIC_POD_TYPE = waterLicenseResponse.features[0]?.properties?.POD_DIVERSION_TYPE;
        LIC_POD_SUBT = waterLicenseResponse.features[0]?.properties?.POD_SUBTYPE;
        LIC_SRC_WATER = waterLicenseResponse.features[0]?.properties?.SOURCE_NAME;
    }
    
    // application details keys
    public static String APP_STATUS;
    public static Integer APP_WELL_TAG;
    public static String APP_PURPOSE_USE;
    public static String APP_PURPOSE_USE_CODE;
    public static Double APP_QTY_DIV_MAX_RATE;
    public static String APP_QTY_UNITS_DIV_MAX_RATE;
    public static String APP_POD_NUMBER;
    public static String APP_POD_DIV_TYPE;
    public static String APP_POD_SUBTYPE;
    
    public static void setApplicationDetails(PHOCSWLSWaterApplicationsWrapper waterLicenseAppResponse){
        APP_STATUS = waterLicenseAppResponse.features[0]?.properties?.APPLICATION_STATUS;
        APP_WELL_TAG = waterLicenseAppResponse.features[0]?.properties?.WELL_TAG_NUMBER;
        APP_PURPOSE_USE = waterLicenseAppResponse.features[0]?.properties?.PURPOSE_USE;
        APP_PURPOSE_USE_CODE = waterLicenseAppResponse.features[0]?.properties?.PURPOSE_USE_CODE;
        APP_QTY_DIV_MAX_RATE = waterLicenseAppResponse.features[0]?.properties?.QTY_DIVERSION_MAX_RATE;
        APP_QTY_UNITS_DIV_MAX_RATE = waterLicenseAppResponse.features[0].properties.QTY_UNITS_DIVERSION_MAX_RATE;
        APP_POD_NUMBER = waterLicenseAppResponse.features[0]?.properties?.POD_NUMBER;
        APP_POD_DIV_TYPE = waterLicenseAppResponse.features[0]?.properties?.POD_DIVERSION_TYPE;
        APP_POD_SUBTYPE = waterLicenseAppResponse.features[0]?.properties?.POD_SUBTYPE;
    }
    
    // well details keys
    public static Integer WELL_ID_PLATE;
    public static String WELL_STATUS;
    public static Boolean ARTESIAN;
    public static String AQUIFER_NUM;
    public static String CONS_START;
    public static String CONS_END;
    public static String WELL_LOC_DESC;
    public static String SCREEN_TYPE;
    public static String SCREEN_MAT;
    public static String SCREEN_INTAKE;
    
    // well sections
    public static List<PHOCSWellResponseWrapper.CasingSetItem> CASING_DETAILS;
    public static List<PHOCSWellResponseWrapper.ScreenSetItem> INSTALLED_SCREENS;
    
    public static void setWellDetails(PHOCSWellResponseWrapper wellDetailsResponse){
        WELL_ID_PLATE = wellDetailsResponse?.IDENTIFICATION_PLATE_NUMBER;
        WELL_STATUS = wellDetailsResponse?.well_status;
        ARTESIAN = wellDetailsResponse?.artesian_conditions;
        AQUIFER_NUM = wellDetailsResponse?.aquifer;
        CONS_START = wellDetailsResponse?.construction_start_date;
        CONS_END = wellDetailsResponse?.construction_end_date;
        WELL_LOC_DESC = wellDetailsResponse?.well_location_description;
        SCREEN_TYPE = wellDetailsResponse?.screen_type;
        SCREEN_MAT = wellDetailsResponse?.screen_material;
        SCREEN_INTAKE = wellDetailsResponse?.screen_intake_method;
        CASING_DETAILS = wellDetailsResponse?.casing_set;
        INSTALLED_SCREENS = wellDetailsResponse?.screen_set;
    }
    
    // aquifer keys
    public static String AQUIFER_NAME;
    public static String AQUIFER_SUBT;
    public static String AQUIFER_MAT;
    public static String AQUIFER_SIZE;
    
    public static void setAquiferDetails(PHOCSAquifersResponseWrapper aquiferDetailsResponse){
        AQUIFER_NAME 	= aquiferDetailsResponse?.aquifer_name;
        AQUIFER_SUBT 	= aquiferDetailsResponse?.subtype;
        AQUIFER_MAT 	= aquiferDetailsResponse?.geom?.type;
        AQUIFER_SIZE 	= aquiferDetailsResponse?.area;
    }
}