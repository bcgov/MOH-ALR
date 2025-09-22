global with sharing class PHOCSWaterRightsService implements Callable {
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>) args.get('input');
        Map<String, Object> output  = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }
    
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Account acc = getAccountDetails(String.valueOf(inputMap.get('recordId')));
        PHOCSWellResponseWrapper wellDetailsResponse;
        if (methodName == 'getWaterLicenseDetails') {
            if (acc != null && String.isNotBlank(acc.WaterLicenseNumber__c)) {
                try{
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
                }catch(Exception ex){
                    outMap.put('NoData', 'No water license details available.');
                }
            } else {
                outMap.put('NoData', 'No water license details available.');
            }
        }
        if (methodName == 'getWaterLicenseApplicationDetails') {
            if (acc != null && String.isNotBlank(acc.WaterLicenseApplicationNumber__c)) {
                try{
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
                }catch(Exception ex){
                    outMap.put('NoData', 'No water license application details available.');
                }
            } else {
                outMap.put('NoData', 'No water license application details available.');
            }
        }
        if (methodName == 'getAquifersDetails') {
            if (acc != null && acc.AquiferNumber__c != null && String.isNotBlank(acc.AquiferNumber__c.toString())) {
                try{
                    PHOCSAquifersResponseWrapper response = getAquiferDetails(acc.AquiferNumber__c.toString());                
                    // Put the wrapper directly into the output map
                    outMap.put('aquifer_name', response.aquifer_name);
                    outMap.put('subtype', response.subtype);
                    outMap.put('material_type', response.geom.type);
                    outMap.put('size', response.area);
                }catch(Exception ex){
                    outMap.put('NoData', 'No aquifer details available.');
                }                
            } else {
                outMap.put('NoData', 'No aquifer details available.');
            }
        }
        if (methodName == 'getGWellDetails') {
            if (acc != null && acc.WellTagNumber__c != null && String.isNotBlank(acc.WellTagNumber__c.toString())) {
                try{
                    if(wellDetailsResponse == null){
                        wellDetailsResponse = getGWellDetails(acc.WellTagNumber__c.toString());
                    }                                    
                    // Put the wrapper directly into the output map
                    outMap.put('WellIDPlateNumber', wellDetailsResponse.IDENTIFICATION_PLATE_NUMBER);
                    outMap.put('WellStatus', wellDetailsResponse.well_status);
                    outMap.put('ArtesianCondition', wellDetailsResponse.artesian_conditions);
                    outMap.put('AquiferNumber', wellDetailsResponse.aquifer);
                    outMap.put('StartDateofConstruction', wellDetailsResponse.construction_start_date);
                    outMap.put('EndDateofConstruction', wellDetailsResponse.construction_end_date);
                    outMap.put('WellLocationDescription', wellDetailsResponse.well_location_description);
                    outMap.put('ScreenType', wellDetailsResponse.screen_type);
                    outMap.put('ScreenMaterial', wellDetailsResponse.screen_material);
                    outMap.put('ScreenIntakeMethod', wellDetailsResponse.screen_intake_method);
                }catch(Exception ex){
                    outMap.put('NoData', 'No well details available.');
                }
            } else {
                outMap.put('NoData', 'No well details available.');
            }            
        }
        if (methodName == 'getGWellCasingDetails') {
            if (acc != null && acc.WellTagNumber__c != null && String.isNotBlank(acc.WellTagNumber__c.toString())) {
                try{
                    if(wellDetailsResponse == null){
                        wellDetailsResponse = getGWellDetails(acc.WellTagNumber__c.toString());
                    }                                    
                    // Put the wrapper directly into the output map
                    outMap.put('CasingDetails', wellDetailsResponse.casing_set);
                }catch(Exception ex){
                    outMap.put('NoData', 'No well details available.');
                }
            } else {
                outMap.put('NoData', 'No well details available.');
            }
        }
        if (methodName == 'getGWellInstalledDetails') {
            if (acc != null && acc.WellTagNumber__c != null && String.isNotBlank(acc.WellTagNumber__c.toString())) {
                try{
                    if(wellDetailsResponse == null){
                        wellDetailsResponse = getGWellDetails(acc.WellTagNumber__c.toString());
                    }                                    
                    // Put the wrapper directly into the output map
                    outMap.put('InstalledScreens', wellDetailsResponse.screen_set);
                }catch(Exception ex){
                    outMap.put('NoData', 'No well details available.');
                }
            } else {
                outMap.put('NoData', 'No well details available.');
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