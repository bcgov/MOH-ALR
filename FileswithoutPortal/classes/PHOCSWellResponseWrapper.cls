/*
*     Created by: Pawan Atri
*     Created Date: 16-Sept-2025
*     User Story: EHIS-1425
*     Title: Retrieve wells information from the Water Rights Database (WLRS)
*     Description: Wrapper class for PHOCS Well Response
*/

public class PHOCSWellResponseWrapper {
    public String well_guid;
    public Integer well;
    public Integer well_tag_number;
    public Integer identification_plate_number;
    public String owner_full_name;
    public String well_class;
    public String well_subclass;
    public String intended_water_use;
    public String well_status;
    public String well_publication_status;
    public String licenced_status;
    public String street_address;
    public String city;
    public String legal_lot;
    public String legal_plan;
    public String legal_district_lot;
    public String legal_block;
    public String legal_section;
    public String legal_township;
    public String legal_range;
    public String land_district;
    public String legal_pid;
    public String well_location_description;
    public String construction_start_date;
    public String construction_end_date;
    public String alteration_start_date;
    public String alteration_end_date;
    public String decommission_start_date;
    public String decommission_end_date;
    public String person_responsible;
    public String driller_name;
    public String drilling_company;
    public String company_of_person_responsible;
    public String consultant_name;
    public String consultant_company;
    public String well_identification_plate_attached;
    public String id_plate_attached_by;
    public String water_supply_system_name;
    public String water_supply_system_well_name;
    public Double latitude;
    public Double longitude;
    public String coordinate_acquisition_code;
    public String ground_elevation;
    public String ground_elevation_method;
    public List<DrillingMethod> drilling_methods;
    public String well_orientation_status;
    public String surface_seal_material;
    public String surface_seal_thickness;
    public String surface_seal_method;
    public String surface_seal_depth;
    public String backfill_type;
    public String backfill_depth;
    public String liner_diameter;
    public String liner_thickness;
    public String liner_from;
    public String liner_to;
    public String screen_intake_method;
    public String screen_type;
    public String screen_material;
    public String other_screen_material;
    public String screen_opening;
    public String screen_bottom;
    public String other_screen_bottom;
    public String screen_information;
    public String filter_pack_from;
    public String filter_pack_to;
    public String filter_pack_thickness;
    public String filter_pack_material;
    public String filter_pack_material_size;
    public List<DevelopmentMethod> development_methods;
    public String development_hours;
    public String development_notes;
    public List<String> water_quality_characteristics;
    public String water_quality_colour;
    public String water_quality_odour;
    public String total_depth_drilled;
    public String finished_well_depth;
    public String final_casing_stick_up;
    public String bedrock_depth;
    public String static_water_level;
    public String well_yield;
    public String artesian_flow;
    public String artesian_pressure;
    public String artesian_pressure_head;
    public Boolean artesian_conditions;
    public String well_cap_type;
    public String well_disinfected_status;
    public String comments;
    public String alternative_specs_submitted;
    public Boolean technical_report;
    public Boolean drinking_water_protection_area_ind;
    public String well_yield_unit;
    public String diameter;
    public String observation_well_number;
    public String observation_well_status;
    public String ems;
    public String aquifer;
    public String utm_zone_code;
    public Integer utm_northing;
    public Integer utm_easting;
    public String bcgs_id;
    public String decommission_reason;
    public String decommission_method;
    public String decommission_sealant_material;
    public String decommission_backfill_material;
    public String decommission_details;
    public String aquifer_vulnerability_index;
    public String aquifer_lithology;
    public String storativity;
    public String transmissivity;
    public String hydraulic_conductivity;
    public String specific_storage;
    public String specific_yield;
    public String testing_method;
    public String testing_duration;
    public String analytic_solution_type;
    public String boundary_effect;
    public String yield_estimation_method;
    public String yield_estimation_rate;
    public String yield_estimation_duration;
    public String static_level_before_test;
    public String drawdown;
    public Boolean hydro_fracturing_performed;
    public String hydro_fracturing_yield_increase;
    public String recommended_pump_depth;
    public String recommended_pump_rate;
    public List<CasingSetItem> casing_set;
    public List<Object> aquifer_parameters_set;
    public List<ScreenSetItem> screen_set;
    public List<Object> linerperforation_set;
    public List<Object> decommission_description_set;
    public List<LithologyDescription> lithologydescription_set;
    public List<SubmissionWorkDate> submission_work_dates;
    public Boolean is_published;
    
    // ---------- INNER CLASSES ----------
    public class DrillingMethod {
        public String description;
    }
    
    public class DevelopmentMethod {
        public String description;
    }
    
    public class CasingSetItem {
        public String start;
        public String endVal; // renamed from 'end'
        public String diameter;
        public String casing_code;
        public String casing_material;
        public String drive_shoe_status;
        public String wall_thickness;
    }
    
    public class ScreenSetItem {
        public String start;
        public String endVal; // renamed from 'end'
        public String diameter;
        public String assembly_type;
        public String slot_size;
    }
    
    public class LithologyDescription {
        public String start;
        public String endVal; // renamed from 'end'
        public String lithology_raw_data;
        public String lithology_colour;
        public String lithology_hardness;
        public String lithology_moisture;
        public String lithology_observation;
        public String water_bearing_estimated_flow;
    }
    
    public class SubmissionWorkDate {
        public Integer well;
        public String create_date;
        public String well_activity_description;
        public String work_start_date;
        public String work_end_date;
        public String drilling_company;
    }
    
    // ---------- PARSER ----------
    public static PHOCSWellResponseWrapper parse(String jsonString) {
        return (PHOCSWellResponseWrapper) JSON.deserialize(jsonString, PHOCSWellResponseWrapper.class);
    }
}