public class WLSWaterRightsWrapper {

    public String type;
    public List<Feature> features;
    public Integer totalFeatures;
    public Integer numberMatched;
    public Integer numberReturned;
    public String timeStamp;
    public CRS crs;

    public class Feature {
        public String type;
        public String id;
        public Geometry geometry;
        public String geometry_name;
        public Properties properties;
    }

    public class Geometry {
        public String type;
        public List<Double> coordinates;
    }

    public class Properties {
        public Integer WLS_WRL_SYSID;
        public String POD_NUMBER;
        public String POD_SUBTYPE;
        public String POD_DIVERSION_TYPE;
        public String POD_STATUS;
        public String FILE_NUMBER;
        public Integer WELL_TAG_NUMBER;
        public String LICENCE_NUMBER;
        public String LICENCE_STATUS;
        public String LICENCE_STATUS_DATE;
        public String PRIORITY_DATE;
        public String EXPIRY_DATE;
        public String PURPOSE_USE_CODE;
        public String PURPOSE_USE;
        public String SOURCE_NAME;
        public String REDIVERSION_IND;
        public Double QUANTITY;
        public String QUANTITY_UNITS;
        public String QUANTITY_FLAG;
        public String QUANTITY_FLAG_DESCRIPTION;
        public Double QTY_DIVERSION_MAX_RATE;
        public String QTY_UNITS_DIVERSION_MAX_RATE;
        public String HYDRAULIC_CONNECTIVITY;
        public String PERMIT_OVER_CROWN_LAND_NUMBER;
        public String PRIMARY_LICENSEE_NAME;
        public String ADDRESS_LINE_1;
        public String ADDRESS_LINE_2;
        public String ADDRESS_LINE_3;
        public String ADDRESS_LINE_4;
        public String COUNTRY;
        public String POSTAL_CODE;
        public Double LATITUDE;
        public Double LONGITUDE;
        public String DISTRICT_PRECINCT_NAME;
        public Integer OBJECTID;
        public String SE_ANNO_CAD_DATA;
    }

    public class CRS {
        public String type;
        public CRSProperties properties;
    }

    public class CRSProperties {
        public String name;
    }

    // Method to deserialize JSON string into this wrapper
    public static WLSWaterRightsWrapper parse(String jsonString) {
        return (WLSWaterRightsWrapper) JSON.deserialize(jsonString, WLSWaterRightsWrapper.class);
    }
}