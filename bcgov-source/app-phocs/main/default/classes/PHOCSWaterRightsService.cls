global with sharing class PHOCSWaterRightsService implements Callable {
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>) args.get('input');
        Map<String, Object> output  = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }
    
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Account acc = getAccountDetails(String.valueOf(inputMap.get('recordId')));
        if (methodName == 'getWaterLicenseDetails') {
            if (acc != null && String.isNotBlank(acc.WaterLicenseNumber__c)) {
                PHOCSWLSWaterRightsWrapper response = getWaterLicenseDetails(acc.WaterLicenseNumber__c);                
                // Put the wrapper directly into the output map
                outMap.put('WaterLicenceStatus', response.features[0].properties.LICENCE_STATUS);
                outMap.put('WellTagNumber', response.features[0].properties.WELL_TAG_NUMBER);
                outMap.put('WaterSourceIntakeUse', response.features[0].properties.PURPOSE_USE);
                outMap.put('WaterSourceIntakeUseCode', response.features[0].properties.PURPOSE_USE_CODE);
                outMap.put('MaximumDiversion', response.features[0].properties.QUANTITY);
                outMap.put('MaximumDiversionUnits', response.features[0].properties.QUANTITY_UNITS);
                outMap.put('PointofDiversionNumber', response.features[0].properties.POD_NUMBER);
                outMap.put('PODDiversionType', response.features[0].properties.POD_DIVERSION_TYPE);
                outMap.put('PODSubtype', response.features[0].properties.POD_SUBTYPE);
                outMap.put('SourceWaterBodyName', response.features[0].properties.SOURCE_NAME);
            } else {
                outMap.put('result', null);
            }
        }
        if (methodName == 'getWaterLicenseApplicationDetails') {
            if (acc != null && String.isNotBlank(acc.WaterLicenseApplicationNumber__c)) {
                PHOCSWLSWaterApplicationsWrapper response = getWaterLicenseApplicationDetails(acc.WaterLicenseApplicationNumber__c);                
                // Put the wrapper directly into the output map
                outMap.put('WaterLicenceApplicationStatus', response.features[0].properties.APPLICATION_STATUS);
                outMap.put('WellTagNumber', response.features[0].properties.WELL_TAG_NUMBER);
                outMap.put('WaterSourceIntakeUse', response.features[0].properties.PURPOSE_USE);
                outMap.put('WaterSourceIntakeUseCode', response.features[0].properties.PURPOSE_USE_CODE);
                outMap.put('MaximumDiversion', response.features[0].properties.QTY_DIVERSION_MAX_RATE);
                outMap.put('MaximumDiversionUnits', response.features[0].properties.QTY_UNITS_DIVERSION_MAX_RATE);
                outMap.put('PointofDiversionNumber', response.features[0].properties.POD_NUMBER);
                outMap.put('PODDiversionType', response.features[0].properties.POD_DIVERSION_TYPE);
                outMap.put('PODSubtype', response.features[0].properties.POD_SUBTYPE);
            } else {
                outMap.put('result', null);
            }
        }
        if (methodName == 'getAquifersDetails') {
            if (acc != null && String.isNotBlank(acc.AquiferNumber__c.toString())) {
                PHOCSAquifersResponseWrapper response = getAquiferDetails(acc.AquiferNumber__c.toString());                
                // Put the wrapper directly into the output map
                outMap.put('aquifer_name', response.aquifer_name);
                outMap.put('subtype', response.subtype);
                outMap.put('material_type', response.geom.type);
                outMap.put('size', response.area);
            } else {
                outMap.put('result', null);
            }
        }
        if (methodName == 'getGWellDetails') {
            if (acc != null && String.isNotBlank(acc.WellTagNumber__c.toString())) {
                PHOCSWellResponseWrapper response = getGWellDetails(acc.WellTagNumber__c.toString());                
                // Put the wrapper directly into the output map
                outMap.put('WellIDPlateNumber', response.IDENTIFICATION_PLATE_NUMBER);
                outMap.put('WellStatus', response.well_status);
                outMap.put('ArtesianCondition', response.artesian_conditions);
                outMap.put('AquiferNumber', response.aquifer);
                outMap.put('StartDateofConstruction', response.construction_start_date);
                outMap.put('EndDateofConstruction', response.construction_end_date);
                outMap.put('WellLocationDescription', response.well_location_description);
                outMap.put('ScreenType', response.other_screen_material);
                outMap.put('ScreenMaterial', response.other_screen_material);
                outMap.put('ScreenIntakeMethod', response.other_screen_material);
                outMap.put('CasingDetails', response.submission_work_dates);
                outMap.put('InstalledScreens', response.submission_work_dates);
            } else {
                outMap.put('result', null);
            }
        }
        return outMap; // always return the whole map
    }
    
    private PHOCSWLSWaterRightsWrapper getWaterLicenseDetails(String licenceNumber) {
        return PHOCSWLSWaterService.getWaterRightsByLicence(licenceNumber);
    }
    
    private PHOCSWLSWaterApplicationsWrapper getWaterLicenseApplicationDetails(String waterApplicationNumber) {
        return PHOCSWLSWaterService.getWaterApplicationsByJob(waterApplicationNumber);
    }
    
    private PHOCSAquifersResponseWrapper getAquiferDetails(String aquiferNumber){
        return PHOCSGwellsService.getAquiferDetails(aquiferNumber);
    }
    
    private PHOCSWellResponseWrapper getGWellDetails(String wellTagNumber){
        return PHOCSGwellsService.getWellDetails(wellTagNumber);
    }
    
    private Account getAccountDetails(String recordId) {
        return [SELECT Id, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c, WellTagNumber__c, AquiferNumber__c FROM Account WHERE Id = :recordId LIMIT 1];
    }
}