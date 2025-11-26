/*
    Created by: Pawan Atri
    Created Date: 16-Sept-2025
    User Story: EHIS-1425
    Title: Retrieve water license information from the Water Rights Database (WLRS)
    Description: Wrapper class for PHOCS Aquifer Response
*/

public class PHOCSAquifersResponseWrapper {
    public Integer aquifer_id;
    public String aquifer_name;
    public String location_description;
    public String quality_concern;
    public String material;
    public String subtype;
    public String vulnerability;
    public String known_water_use;
    public String litho_stratographic_unit;
    public String productivity;
    public String demand;
    public Integer mapping_year;
    public List<Resource> resources;
    public String area;
    public String notes;
    public Datetime effective_date;
    public Datetime expiry_date;
    public Datetime retire_date;
    public Geom geom;
    public LicenceDetails licence_details;

    public class Resource {
        public Integer id;
        public String name;
        public String url;
        public String section_code;
    }

    public class Geom {
        public String type;
        public List<List<List<List<Double>>>> coordinates;
    }

    public class LicenceDetails {
        public Integer licence_count;
        public LicencesUpdated licences_updated;
        public Integer num_wells_with_ems;
        public Integer num_artesian_wells;
        public WellsUpdated wells_updated;
        public Integer num_wells;
        public List<ObsWell> obs_wells;
        public List<WellsByLicence> wells_by_licence;
        public List<Usage> usage;
        public List<LicQty> lic_qty;
        public Boolean hydraulically_connected;
    }

    public class LicencesUpdated {
        @SerializedName('update_date__max')
        public Datetime updateDateMax;
    }

    public class WellsUpdated {
        @SerializedName('update_date__max')
        public Datetime updateDateMax;
    }

    public class ObsWell {
        public Integer well_tag_number;
        public String observation_well_number;
        public String observation_well_status;
    }

    public class WellsByLicence {
        public Integer licence_number;
        public String well_tag_numbers_in_licence;
    }

    public class Usage {
        @SerializedName('purpose__description')
        public String purposeDescription;
        public Double total_qty;
    }

    public class LicQty {
        @SerializedName('purpose__description')
        public String purposeDescription;
        public Integer total_qty;
    }

    // Helper method to deserialize JSON
    public static PHOCSAquifersResponseWrapper parseJson(String jsonString) {
        return (PHOCSAquifersResponseWrapper) JSON.deserialize(jsonString, PHOCSAquifersResponseWrapper.class);
    }
}