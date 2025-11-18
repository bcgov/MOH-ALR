@IsTest
public class PHOCSAquifersResponseWrapperTest {
    public static String getResponse(){
        String jsonString = '{' +
            '"aquifer_id": 658,' +
            '"aquifer_name": "Houston Bedrock",' +
            '"location_description": "Around the town of Houston",' +
            '"quality_concern": "None",' +
            '"material": "Bedrock",' +
            '"subtype": "Fractured crystalline bedrock",' +
            '"vulnerability": "Moderate",' +
            '"known_water_use": null,' +
            '"litho_stratographic_unit": "Kasalka Group, Telka Formation, Goosly Lake Formation",' +
            '"productivity": "Low",' +
            '"demand": "Moderate",' +
            '"mapping_year": 2020,' +
            '"resources": [' +
            '{' +
            '"id": 1664,' +
            '"name": "Stress Index Report",' +
            '"url": "https://services6.arcgis.com/ubm4tcTYICKBpist/arcgis/rest/services/Aquifer_180613_NA/FeatureServer/0/149/attachments/149",' +
            '"section_code": "P"' +
            '},' +
            '{' +
            '"id": 2452,' +
            '"name": "Vanderhoof and Houston Aquifer Mapping and Hydrostratigraphic Characterization",' +
            '"url": "https://a100.gov.bc.ca/pub/acat/public/viewReport.do?reportId=59008",' +
            '"section_code": "M"' +
            '}' +
            '],' +
            '"area": "113.0",' +
            '"notes": null,' +
            '"effective_date": "2000-01-01T00:00:00Z",' +
            '"expiry_date": "9999-12-31T23:59:59.999999Z",' +
            '"retire_date": "9999-12-31T23:59:59.999999Z",' +
            '"geom": {' +
            '"type": "MultiPolygon",' +
            '"coordinates": [[[' +
            '[-126.546828122686, 54.4499133161687],' +
            '[-126.535940120632, 54.4459554189032],' +
            '[-126.528326472044, 54.443186749668],' +
            '[-126.50645691149, 54.4324666454187],' +
            '[-126.531315009312, 54.4253909654856],' +
            '[-126.525185570724, 54.4219423673082],' +
            '[-126.526367896803, 54.4217080190144],' +
            '[-126.52874210368, 54.4219843273157],' +
            '[-126.529625138504, 54.421521987798],' +
            '[-126.530596553875, 54.420256862569],' +
            '[-126.531070378086, 54.4187073253515],' +
            '[-126.530140799545, 54.4155590983698],' +
            '[-126.528430220275, 54.4131020154563],' +
            '[-126.546828122686, 54.4499133161687]' +
            ']]]' +
            '},' +
            '"licence_details": {' +
            '"licence_count": 3,' +
            '"licences_updated": {' +
            '"update_date_max": "2025-09-15T11:47:43.757535Z"' +
            '},' +
            '"num_wells_with_ems": 0,' +
            '"num_artesian_wells": 0,' +
            '"wells_updated": {' +
            '"update_date_max": "2024-12-27T21:16:35.579665Z"' +
            '},' +
            '"num_wells": 53,' +
            '"obs_wells": [],' +
            '"wells_by_licence": [' +
            '{ "licence_number": 506166, "well_tag_numbers_in_licence": "47018" },' +
            '{ "licence_number": 505833, "well_tag_numbers_in_licence": "130048" },' +
            '{ "licence_number": 504400, "well_tag_numbers_in_licence": "125498" }' +
            '],' +
            '"usage": [' +
            '{ "purpose_description": "WSA03 - Commercial Enterprise ", "total_qty": 1460 },' +
            '{ "purpose_description": "WSA08 - Livestock & Animal ", "total_qty": 613.8 },' +
            '{ "purpose_description": "WSA05 - Greenhouse & Nursery ", "total_qty": 50 }' +
            '],' +
            '"lic_qty": [' +
            '{ "purpose_description": "WSA03 - Commercial Enterprise ", "total_qty": 1 },' +
            '{ "purpose_description": "WSA08 - Livestock & Animal ", "total_qty": 1 },' +
            '{ "purpose_description": "WSA05 - Greenhouse & Nursery ", "total_qty": 1 }' +
            '],' +
            '"hydraulically_connected": false' +
            '}' +
            '}';
        return jsonString;
    }
    
    public static String getBlankResponse(){
        String jsonString = '{' +
            '"aquifer_id": 658,' +
            '"aquifer_name": null,' +
            '"location_description": "Around the town of Houston",' +
            '"quality_concern": "None",' +
            '"material": "Bedrock",' +
            '"subtype": null,' +
            '"vulnerability": "Moderate",' +
            '"known_water_use": null,' +
            '"litho_stratographic_unit": "Kasalka Group, Telka Formation, Goosly Lake Formation",' +
            '"productivity": "Low",' +
            '"demand": "Moderate",' +
            '"mapping_year": 2020,' +
            '"resources": [' +
            '{' +
            '"id": 1664,' +
            '"name": "Stress Index Report",' +
            '"url": "https://services6.arcgis.com/ubm4tcTYICKBpist/arcgis/rest/services/Aquifer_180613_NA/FeatureServer/0/149/attachments/149",' +
            '"section_code": "P"' +
            '},' +
            '{' +
            '"id": 2452,' +
            '"name": "Vanderhoof and Houston Aquifer Mapping and Hydrostratigraphic Characterization",' +
            '"url": "https://a100.gov.bc.ca/pub/acat/public/viewReport.do?reportId=59008",' +
            '"section_code": "M"' +
            '}' +
            '],' +
            '"area": null,' +
            '"notes": null,' +
            '"effective_date": "2000-01-01T00:00:00Z",' +
            '"expiry_date": "9999-12-31T23:59:59.999999Z",' +
            '"retire_date": "9999-12-31T23:59:59.999999Z",' +
            '"geom": {' +
            '"type": null,' +
            '"coordinates": [[[' +
            '[-126.546828122686, 54.4499133161687],' +
            '[-126.535940120632, 54.4459554189032],' +
            '[-126.528326472044, 54.443186749668],' +
            '[-126.50645691149, 54.4324666454187],' +
            '[-126.531315009312, 54.4253909654856],' +
            '[-126.525185570724, 54.4219423673082],' +
            '[-126.526367896803, 54.4217080190144],' +
            '[-126.52874210368, 54.4219843273157],' +
            '[-126.529625138504, 54.421521987798],' +
            '[-126.530596553875, 54.420256862569],' +
            '[-126.531070378086, 54.4187073253515],' +
            '[-126.530140799545, 54.4155590983698],' +
            '[-126.528430220275, 54.4131020154563],' +
            '[-126.546828122686, 54.4499133161687]' +
            ']]]' +
            '},' +
            '"licence_details": {' +
            '"licence_count": 3,' +
            '"licences_updated": {' +
            '"update_date_max": "2025-09-15T11:47:43.757535Z"' +
            '},' +
            '"num_wells_with_ems": 0,' +
            '"num_artesian_wells": 0,' +
            '"wells_updated": {' +
            '"update_date_max": "2024-12-27T21:16:35.579665Z"' +
            '},' +
            '"num_wells": 53,' +
            '"obs_wells": [],' +
            '"wells_by_licence": [' +
            '{ "licence_number": 506166, "well_tag_numbers_in_licence": "47018" },' +
            '{ "licence_number": 505833, "well_tag_numbers_in_licence": "130048" },' +
            '{ "licence_number": 504400, "well_tag_numbers_in_licence": "125498" }' +
            '],' +
            '"usage": [' +
            '{ "purpose_description": "WSA03 - Commercial Enterprise ", "total_qty": 1460 },' +
            '{ "purpose_description": "WSA08 - Livestock & Animal ", "total_qty": 613.8 },' +
            '{ "purpose_description": "WSA05 - Greenhouse & Nursery ", "total_qty": 50 }' +
            '],' +
            '"lic_qty": [' +
            '{ "purpose_description": "WSA03 - Commercial Enterprise ", "total_qty": 1 },' +
            '{ "purpose_description": "WSA08 - Livestock & Animal ", "total_qty": 1 },' +
            '{ "purpose_description": "WSA05 - Greenhouse & Nursery ", "total_qty": 1 }' +
            '],' +
            '"hydraulically_connected": false' +
            '}' +
            '}';
        return jsonString;
    }
    @IsTest
    static void testDeserialization() {
        String jsonString = getResponse();        
        
        // Deserialize into wrapper
        PHOCSAquifersResponseWrapper resp = (PHOCSAquifersResponseWrapper) JSON.deserialize(jsonString, PHOCSAquifersResponseWrapper.class);
        
        // Assertions (ensures deserialization worked)
        System.assertEquals(658, resp.aquifer_id);
        System.assertEquals('Houston Bedrock', resp.aquifer_name);
        System.assertEquals('Bedrock', resp.material);
        System.assertEquals(2020, resp.mapping_year);
        System.assertEquals('Stress Index Report', resp.resources[0].name);
        System.assertEquals(3, resp.licence_details.licence_count);
        System.assertEquals(53, resp.licence_details.num_wells);
        System.assertEquals('47018', resp.licence_details.wells_by_licence[0].well_tag_numbers_in_licence);
        System.assertEquals(1460, resp.licence_details.usage[0].total_qty);
        
        // Debug top-level fields
        System.debug('==== Aquifer ID: ' + resp.aquifer_id);
        System.debug('==== Aquifer Name: ' + resp.aquifer_name);
        System.debug('==== Location: ' + resp.location_description);
        System.debug('==== Material: ' + resp.material);
        System.debug('==== Subtype: ' + resp.subtype);
        System.debug('==== Vulnerability: ' + resp.vulnerability);
        
        // Debug nested resources
        if (resp.resources != null && !resp.resources.isEmpty()) {
            for (PHOCSAquifersResponseWrapper.Resource res : resp.resources) {
                System.debug('---- Resource ID: ' + res.id);
                System.debug('---- Resource Name: ' + res.name);
                System.debug('---- Resource URL: ' + res.url);
            }
        }
        
        // Debug licence details
        if (resp.licence_details != null) {
            System.debug('==== Licence Count: ' + resp.licence_details.licence_count);
            System.debug('==== Num Wells: ' + resp.licence_details.num_wells);
            if (resp.licence_details.licences_updated != null) {
                System.debug('==== Licence Updated At: ' + resp.licence_details.licences_updated.updateDateMax);
            }
            if (resp.licence_details.usage != null && !resp.licence_details.usage.isEmpty()) {
                for (PHOCSAquifersResponseWrapper.Usage u : resp.licence_details.usage) {
                    System.debug('---- Usage Purpose: ' + u.purposeDescription);
                    System.debug('---- Usage Qty: ' + u.total_qty);
                }
            }
        }
        
    }
}