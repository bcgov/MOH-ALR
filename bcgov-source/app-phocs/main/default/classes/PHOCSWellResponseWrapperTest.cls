@isTest
public class PHOCSWellResponseWrapperTest {
    
    public static String getResponse(){
        String jsonString = '{' +
            '"well_guid": "dbf618ed-9a8e-428f-89c1-3fc861a0721d",' +
            '"well": 129877,' +
            '"well_tag_number": 129877,' +
            '"identification_plate_number": 71465,' +
            '"owner_full_name": "Fisheries and Oceans Canada (attn Jennifer Simpson)",' +
            '"well_class": "Water Supply",' +
            '"well_subclass": "Not Applicable",' +
            '"intended_water_use": "Commercial and Industrial",' +
            '"well_status": "New",' +
            '"well_publication_status": "Well is Published and can be Open Information for the public",' +
            '"licenced_status": "Licensed",' +
            '"street_address": null,' +
            '"city": null,' +
            '"legal_lot": null,' +
            '"legal_plan": "2TU1538",' +
            '"legal_district_lot": "1611A",' +
            '"legal_block": "A",' +
            '"legal_section": null,' +
            '"legal_township": null,' +
            '"legal_range": "5",' +
            '"land_district": "14",' +
            '"legal_pid": null,' +
            '"well_location_description": "River Well 1 - next to the river",' +
            '"construction_start_date": null,' +
            '"construction_end_date": null,' +
            '"alteration_start_date": null,' +
            '"alteration_end_date": null,' +
            '"decommission_start_date": null,' +
            '"decommission_end_date": null,' +
            '"person_responsible": null,' +
            '"driller_name": null,' +
            '"consultant_name": null,' +
            '"consultant_company": null,' +
            '"well_identification_plate_attached": "Not Provided",' +
            '"id_plate_attached_by": null,' +
            '"water_supply_system_name": null,' +
            '"water_supply_system_well_name": "River Well 1",' +
            '"latitude": 54.81518,' +
            '"longitude": -126.1638,' +
            '"coordinate_acquisition_code": "(10 m accuracy) Handheld GPS with accuracy of +/- 10 metres",' +
            '"ground_elevation": null,' +
            '"drilling_methods": [' +
            '{ "description": "Dug" }' +
            '],' +
            '"well_orientation_status": "VERTICAL",' +
            '"surface_seal_thickness": null,' +
            '"surface_seal_depth": null,' +
            '"backfill_type": null,' +
            '"backfill_depth": null,' +
            '"liner_diameter": null,' +
            '"liner_thickness": null,' +
            '"liner_from": null,' +
            '"liner_to": null,' +
            '"other_screen_material": null,' +
            '"other_screen_bottom": null,' +
            '"screen_information": null,' +
            '"filter_pack_from": null,' +
            '"filter_pack_to": null,' +
            '"filter_pack_thickness": null,' +
            '"filter_pack_material": null,' +
            '"filter_pack_material_size": null,' +
            '"development_methods": [],' +
            '"development_hours": null,' +
            '"development_notes": null,' +
            '"water_quality_characteristics": [],' +
            '"water_quality_colour": null,' +
            '"water_quality_odour": null,' +
            '"total_depth_drilled": null,' +
            '"finished_well_depth": "10.00",' +
            '"final_casing_stick_up": null,' +
            '"bedrock_depth": null,' +
            '"static_water_level": null,' +
            '"well_yield": null,' +
            '"artesian_flow": null,' +
            '"artesian_pressure": null,' +
            '"artesian_pressure_head": null,' +
            '"artesian_conditions": false,' +
            '"well_cap_type": null,' +
            '"well_disinfected_status": null,' +
            '"comments": "Well x-ref\'d and associated with groundwater licence application. Specific water use: fish hatchery, secondary purpose: camps and facilities. Well likely constructed around 1974. Well location is updated based on the revised map submitted on May 2024.",' +
            '"alternative_specs_submitted": "No",' +
            '"technical_report": false,' +
            '"drinking_water_protection_area_ind": false,' +
            '"well_yield_unit": null,' +
            '"diameter": "",' +
            '"observation_well_number": null,' +
            '"observation_well_status": null,' +
            '"ems": null,' +
            '"aquifer": null,' +
            '"utm_zone_code": "9",' +
            '"utm_northing": 6077913,' +
            '"utm_easting": 682236,' +
            '"bcgs_id": null,' +
            '"decommission_reason": null,' +
            '"decommission_method": null,' +
            '"decommission_sealant_material": null,' +
            '"decommission_backfill_material": null,' +
            '"decommission_details": null,' +
            '"aquifer_vulnerability_index": null,' +
            '"aquifer_lithology": null,' +
            '"storativity": null,' +
            '"transmissivity": null,' +
            '"hydraulic_conductivity": null,' +
            '"specific_storage": null,' +
            '"specific_yield": null,' +
            '"testing_method": null,' +
            '"testing_duration": null,' +
            '"analytic_solution_type": null,' +
            '"boundary_effect": null,' +
            '"yield_estimation_rate": null,' +
            '"yield_estimation_duration": null,' +
            '"static_level_before_test": null,' +
            '"drawdown": null,' +
            '"hydro_fracturing_performed": false,' +
            '"hydro_fracturing_yield_increase": null,' +
            '"recommended_pump_depth": null,' +
            '"recommended_pump_rate": null,' +
            '"casing_set": [],' +
            '"aquifer_parameters_set": [],' +
            '"screen_set": [],' +
            '"linerperforation_set": [],' +
            '"decommission_description_set": [],' +
            '"lithologydescription_set": [],' +
            '"submission_work_dates": [' +
            '{' +
            '"well": 129877,' +
            '"create_date": "2024-03-14T20:28:58.409047Z",' +
            '"well_activity_description": "Construction report",' +
            '"work_start_date": null,' +
            '"work_end_date": null' +
            '}' +
            '],' +
            '"is_published": true' +
            '}';
        return jsonString;
    }
    @isTest
    static void testWellResponseDeserialization() {
        // Sample JSON payload (copied from your example)
        String jsonString = getResponse();        
        
        // Act: Deserialize
        PHOCSWellResponseWrapper resp = PHOCSWellResponseWrapper.parse(jsonString);
        
        // Assert: main fields
        System.assertNotEquals(null, resp, 'Wrapper should not be null');
        System.assertEquals('dbf618ed-9a8e-428f-89c1-3fc861a0721d', resp.well_guid, 'Well GUID mismatch');
        System.assertEquals(129877, resp.well, 'Well ID mismatch');
        System.assertEquals(71465, resp.identification_plate_number, 'Plate number mismatch');
        System.assertEquals('Fisheries and Oceans Canada (attn Jennifer Simpson)', resp.owner_full_name, 'Owner mismatch');
        System.assertEquals('Water Supply', resp.well_class, 'Well class mismatch');
        System.assertEquals('Commercial and Industrial', resp.intended_water_use, 'Intended use mismatch');
        System.assertEquals('New', resp.well_status, 'Well status mismatch');
        System.assertEquals('Licensed', resp.licenced_status, 'Licence status mismatch');
        
        // Assert: numeric and geo fields
        System.assertEquals(54.81518, resp.latitude, 'Latitude mismatch');
        System.assertEquals(-126.1638, resp.longitude, 'Longitude mismatch');
        System.assertEquals('2TU1538', resp.legal_plan, 'Legal plan mismatch');
        
        // Assert: nested drilling methods
        System.assertNotEquals(null, resp.drilling_methods, 'Drilling methods should not be null');
        System.assertEquals(1, resp.drilling_methods.size(), 'Expected 1 drilling method');
        System.assertEquals('Dug', resp.drilling_methods[0].description, 'Drilling method mismatch');
        
        // Assert: submission work dates
        System.assertNotEquals(null, resp.submission_work_dates, 'Submission work dates should not be null');
        System.assertEquals(1, resp.submission_work_dates.size(), 'Expected 1 submission record');
        System.assertEquals('Construction report', resp.submission_work_dates[0].well_activity_description, 'Activity description mismatch');
        System.assertEquals('2024-03-14T20:28:58.409047Z', resp.submission_work_dates[0].create_date, 'Create date mismatch');
        
        
        // Debug logs (optional, for visibility in tests)
        System.debug('Full Parsed JSON: ' + JSON.serializePretty(resp));
        System.debug('Well GUID: ' + resp.well_guid);
        System.debug('Latitude: ' + resp.latitude);
        System.debug('First Drilling Method: ' + resp.drilling_methods[0].description);
        System.debug('Submission Create Date: ' + resp.submission_work_dates[0].create_date);
    }
}