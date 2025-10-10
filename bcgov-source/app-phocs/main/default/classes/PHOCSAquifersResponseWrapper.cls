/*
    Created by: Pawan Atri
    Date: 2024-06-12
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
    public Licence_Details licence_details;

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

    public class Licence_Details {
        public Integer licence_count;
        public Licences_Updated licences_updated;
        public Integer num_wells_with_ems;
        public Integer num_artesian_wells;
        public Wells_Updated wells_updated;
        public Integer num_wells;
        public List<Object> obs_wells;
        public List<Wells_By_Licence> wells_by_licence;
        public List<Usage> usage;
        public List<Lic_Qty> lic_qty;
        public Boolean hydraulically_connected;
    }

    public class Licences_Updated {
        @SerializedName('update_date__max')
        public Datetime updateDateMax;
    }

    public class Wells_Updated {
        @SerializedName('update_date__max')
        public Datetime updateDateMax;
    }

    public class Wells_By_Licence {
        public Integer licence_number;
        public String well_tag_numbers_in_licence;
    }

    public class Usage {
        @SerializedName('purpose__description')
        public String purposeDescription;
        public Decimal total_qty;
    }

    public class Lic_Qty {
        @SerializedName('purpose__description')
        public String purposeDescription;
        public Decimal total_qty;
    }
}