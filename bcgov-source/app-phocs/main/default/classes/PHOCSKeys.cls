public with sharing class PHOCSKeys {
    // input/output map keys
    public static final String INPUT    = 'input';
    public static final String OUTPUT   = 'output';
    public static final String OPTIONS  = 'options';
    public static final String RECORD_ID = 'recordId';

    // common output keys
    public static final String NODATA = 'NoData';
    public static final String ACCOUNT_ID = 'AccountId';

    // well sections
    public static final String CASING_DETAILS = 'CasingDetails';
    public static final String INSTALLED_SCREENS = 'InstalledScreens';

    // water licence details keys
    public static final String LIC_STATUS = 'WaterLicenceStatus';
    public static final String WELL_TAG   = 'WellTagNumber';
    public static final String PURPOSE    = 'WaterSourceIntakeUse';
    public static final String PURPOSE_CD = 'WaterSourceIntakeUseCode';
    public static final String MAX_DIV    = 'MaximumDiversion';
    public static final String MAX_DIV_U  = 'MaximumDiversionUnits';
    public static final String POD_NUM    = 'PointofDiversionNumber';
    public static final String POD_TYPE   = 'PODDiversionType';
    public static final String POD_SUBT   = 'PODSubtype';
    public static final String SRC_WATER  = 'SourceWaterBodyName';

    // well details keys
    public static final String WELL_ID_PLATE = 'WellIDPlateNumber';
    public static final String WELL_STATUS   = 'WellStatus';
    public static final String ARTESIAN      = 'ArtesianCondition';
    public static final String AQUIFER_NUM   = 'AquiferNumber';
    public static final String CONS_START    = 'StartDateofConstruction';
    public static final String CONS_END      = 'EndDateofConstruction';
    public static final String WELL_LOC_DESC = 'WellLocationDescription';
    public static final String SCREEN_TYPE   = 'ScreenType';
    public static final String SCREEN_MAT    = 'ScreenMaterial';
    public static final String SCREEN_INTAKE = 'ScreenIntakeMethod';

    // aquifer keys
    public static final String AQUIFER_NAME  = 'aquifer_name';
    public static final String AQUIFER_SUBT  = 'subtype';
    public static final String AQUIFER_MAT   = 'material_type';
    public static final String AQUIFER_SIZE  = 'size';

    // user-facing messages
    public static final String MSG_NO_WL   = 'No water license details available.';
    public static final String MSG_NO_WLA  = 'No water license application details available.';
    public static final String MSG_NO_WELL = 'No well details available.';
    public static final String MSG_NO_AQ   = 'No aquifer details available.';

    // actions (Callable entrypoints)
    public static final String ACT_WL   = 'getWaterLicenseDetails';
    public static final String ACT_WLA  = 'getWaterLicenseApplicationDetails';
    public static final String ACT_AQ   = 'getAquifersDetails';
    public static final String ACT_WELL = 'getGWellDetails';
    public static final String ACT_CASING   = 'getGWellCasingDetails';
    public static final String ACT_SCREENS  = 'getGWellInstalledDetails';
}