/*
*     Created by: Pawan Atri
*     Created Date: 16-Sept-2025
*     User Story: EHIS-1425
*     Title: Retrieve water license information from the Water Rights Database (WLRS)
*     Description: Wrapper class for PHOCS Water Application License Response
*/

public class PHOCSWLSWaterApplicationsWrapper {
	public String type;
    public List<Feature> features;
    public Integer totalFeatures;
    public Integer numberMatched;
    public Integer numberReturned;
    public String timeStamp;
    public Crs crs;

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
        public Integer WLS_WRA_SYSID;
        public String APPLICATION_JOB_NUMBER;
        public String POD_NUMBER;
        public String POD_SUBTYPE;
        public String POD_DIVERSION_TYPE;
        public String FILE_NUMBER;
        public String APPLICATION_STATUS;
        public Integer WELL_TAG_NUMBER;
        public String PURPOSE_USE_CODE;
        public String PURPOSE_USE;
        public Double QTY_DIVERSION_MAX_RATE;
        public String QTY_UNITS_DIVERSION_MAX_RATE;
        public String PRIMARY_APPLICANT_NAME;
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

    public class Crs {
        public String type;
        public CrsProperties properties;
    }

    public class CrsProperties {
        public String name;
    }

    // Deserialize JSON string to wrapper
    public static PHOCSWLSWaterApplicationsWrapper parse(String json) {
        return (PHOCSWLSWaterApplicationsWrapper) System.JSON.deserialize(json, PHOCSWLSWaterApplicationsWrapper.class);
    }
}