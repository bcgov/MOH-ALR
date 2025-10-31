global with sharing class PHOCSWaterRightsSystemService implements Callable {
    private static Account facility;
    private static PHOCSWLSWaterRightsWrapper waterLicenseResponse;
    private static PHOCSWLSWaterApplicationsWrapper waterLicenseAppResponse;
    private static PHOCSWellResponseWrapper wellDetailsResponse;
    private static PHOCSAquifersResponseWrapper aquiferDetailsResponse;
    
    private static Boolean exceptionInWLN = false;
    private static Boolean exceptionInWLAN = false;
    private static Boolean exceptionInWTN = false;
    private static Boolean exceptionInAQN = false;
    
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>) args.get('input');
        Map<String, Object> output  = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }
    
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        system.debug('>>> Entered in invokeMethod method <<<');
        Account acc = getAccountDetails(String.valueOf(inputMap.get('recordId')));
        integrationFlow(acc);
        if (methodName == 'getAllData') {
            outMap.putAll(getAllData());
        }
        system.debug('>>> Exist in invokeMethod method <<<');
        return outMap; // always return the whole map
    }
    
    private void integrationFlow(Account acc){
        system.debug('>>> Entered in integrationFlow method <<<');
        Integer wellTagNumber = null;
        Integer aquiferNumber = null;
        if(acc != null && String.isBlank(acc.WaterLicenseNumber__c) && String.isBlank(acc.WaterLicenseApplicationNumber__c)){
            updateFacility(acc.Id, null, null);
            exceptionInWLN = true;
            exceptionInWLAN = true;
            exceptionInWTN = true;
            exceptionInAQN = true;
        }else{
            if (acc != null && String.isNotBlank(acc.WaterLicenseNumber__c)) {
                System.debug('Water License Number: ' + acc.WaterLicenseNumber__c);
                getWaterLicenseDetailsRequest(acc.WaterLicenseNumber__c);
                System.debug('waterLicenseResponse : ' + waterLicenseResponse);
                if(waterLicenseResponse != null && waterLicenseResponse.features != null && waterLicenseResponse.features.size() > 0){
                    
                    System.debug('Feature: ' + waterLicenseResponse.features);
                    System.debug('Feature - properties: ' + waterLicenseResponse.features[0]?.properties);
                    System.debug('Well Tag Number: ' + waterLicenseResponse.features[0]?.properties.WELL_TAG_NUMBER);
                    
                    wellTagNumber = waterLicenseResponse.features[0]?.properties.WELL_TAG_NUMBER;            
                    if(wellTagNumber != null){
                        getGWellDetailsRequest(waterLicenseResponse.features[0]?.properties.WELL_TAG_NUMBER.toString());
                        if(wellDetailsResponse != null && wellDetailsResponse.aquifer != null){
                            aquiferNumber = Integer.valueOf(wellDetailsResponse.aquifer);
                            getAquiferDetailsRequest(wellDetailsResponse.aquifer);
                        }                    
                    }
                }            
            }else{
                exceptionInWLN = true;
            }
            if (acc != null && String.isNotBlank(acc.WaterLicenseApplicationNumber__c)) {
                System.debug('Water License Application Number: ' + acc.WaterLicenseApplicationNumber__c);
                getWaterLicenseApplicationDetailsRequest(acc.WaterLicenseApplicationNumber__c);
                if (acc != null && String.isBlank(acc.WaterLicenseNumber__c)) {
                    if(waterLicenseAppResponse.features != null && waterLicenseAppResponse.features.size() > 0){
                        wellTagNumber = waterLicenseAppResponse.features[0]?.properties.WELL_TAG_NUMBER;
                        if(wellTagNumber != null){
                            getGWellDetailsRequest(wellTagNumber.toString());
                            aquiferNumber = Integer.valueOf(wellDetailsResponse?.aquifer);
                            getAquiferDetailsRequest(wellDetailsResponse.aquifer);
                        } 
                    }                
                }            
            }else{
                exceptionInWLAN = true;
            }
            updateFacility(acc.Id, wellTagNumber, aquiferNumber);
        }        
        system.debug('>>> Exist in integrationFlow method <<<');
    }
    
    private static Map<String, Object> getAllData(){
        Map<String, Object> outMap = new Map<String, Object>();
        if(waterLicenseResponse != null || !exceptionInWLN) {
            // Put the wrapper directly into the output map
            if(waterLicenseResponse.features != null && waterLicenseResponse.features.size() > 0){
                if(waterLicenseResponse.features[0].properties.LICENCE_STATUS == null &&
                   waterLicenseResponse.features[0].properties.WELL_TAG_NUMBER == null &&
                   waterLicenseResponse.features[0].properties.PURPOSE_USE == null &&
                   waterLicenseResponse.features[0].properties.PURPOSE_USE_CODE == null &&
                   waterLicenseResponse.features[0].properties.QUANTITY == null &&
                   waterLicenseResponse.features[0].properties.QUANTITY_UNITS == null &&
                   waterLicenseResponse.features[0].properties.POD_NUMBER == null &&
                   waterLicenseResponse.features[0].properties.POD_DIVERSION_TYPE == null &&
                   waterLicenseResponse.features[0].properties.POD_SUBTYPE == null &&
                   waterLicenseResponse.features[0].properties.SOURCE_NAME == null
                  ){
                      outMap.put('NoDataForWaterLicense', 'No water license details available.');
                  }else{
                      outMap.put('License_WaterLicenceStatus', waterLicenseResponse.features[0].properties.LICENCE_STATUS);
                      outMap.put('License_WellTagNumber', waterLicenseResponse.features[0].properties.WELL_TAG_NUMBER);
                      outMap.put('License_WaterSourceIntakeUse', waterLicenseResponse.features[0].properties.PURPOSE_USE);
                      outMap.put('License_WaterSourceIntakeUseCode', waterLicenseResponse.features[0].properties.PURPOSE_USE_CODE);
                      outMap.put('License_MaximumDiversion', waterLicenseResponse.features[0].properties.QUANTITY);
                      outMap.put('License_MaximumDiversionUnits', waterLicenseResponse.features[0].properties.QUANTITY_UNITS);
                      outMap.put('License_PointofDiversionNumber', waterLicenseResponse.features[0].properties.POD_NUMBER);
                      outMap.put('License_PODDiversionType', waterLicenseResponse.features[0].properties.POD_DIVERSION_TYPE);
                      outMap.put('License_PODSubtype', waterLicenseResponse.features[0].properties.POD_SUBTYPE);
                      outMap.put('License_SourceWaterBodyName', waterLicenseResponse.features[0].properties.SOURCE_NAME);
                      outMap.put('License_AccountId', facility.Id);
                  }                
            }
        } else {
            outMap.put('NoDataForWaterLicense', 'No water license details available.');
        }
        if (waterLicenseAppResponse != null || !exceptionInWLAN) {
            if(waterLicenseAppResponse.features != null && waterLicenseAppResponse.features.size() >0){
                if(waterLicenseAppResponse.features[0].properties.APPLICATION_STATUS == null &&
                   waterLicenseAppResponse.features[0].properties.WELL_TAG_NUMBER == null &&
                   waterLicenseAppResponse.features[0].properties.PURPOSE_USE == null &&
                   waterLicenseAppResponse.features[0].properties.PURPOSE_USE_CODE == null &&
                   waterLicenseAppResponse.features[0].properties.QTY_DIVERSION_MAX_RATE == null &&
                   waterLicenseAppResponse.features[0].properties.POD_NUMBER == null &&
                   waterLicenseAppResponse.features[0].properties.POD_DIVERSION_TYPE == null &&
                   waterLicenseAppResponse.features[0].properties.POD_SUBTYPE == null
                  ){
                      outMap.put('NoDataForLicenseApplication', 'No water license application details available.');
                  }else{
                      outMap.put('Application_WaterLicenceApplicationStatus', waterLicenseAppResponse.features[0].properties.APPLICATION_STATUS);
                      outMap.put('Application_WellTagNumber', waterLicenseAppResponse.features[0].properties.WELL_TAG_NUMBER);
                      outMap.put('Application_WaterSourceIntakeUse', waterLicenseAppResponse.features[0].properties.PURPOSE_USE);
                      outMap.put('Application_WaterSourceIntakeUseCode', waterLicenseAppResponse.features[0].properties.PURPOSE_USE_CODE);
                      outMap.put('Application_MaximumDiversion', waterLicenseAppResponse.features[0].properties.QTY_DIVERSION_MAX_RATE);
                      outMap.put('Application_MaximumDiversionUnits', waterLicenseAppResponse.features[0].properties.QTY_UNITS_DIVERSION_MAX_RATE);
                      outMap.put('Application_PointofDiversionNumber', waterLicenseAppResponse.features[0].properties.POD_NUMBER);
                      outMap.put('Application_PODDiversionType', waterLicenseAppResponse.features[0].properties.POD_DIVERSION_TYPE);
                      outMap.put('Application_PODSubtype', waterLicenseAppResponse.features[0].properties.POD_SUBTYPE);
                  }                
            }
        } else {
            outMap.put('NoDataForLicenseApplication', 'No water license application details available.');
        }
        if (wellDetailsResponse != null || !exceptionInWTN) {
            if(wellDetailsResponse?.IDENTIFICATION_PLATE_NUMBER == null &&
               wellDetailsResponse?.well_status == null &&
               wellDetailsResponse?.artesian_conditions == null &&
               wellDetailsResponse?.aquifer == null &&
               wellDetailsResponse?.construction_start_date == null &&
               wellDetailsResponse?.construction_end_date == null &&
               wellDetailsResponse?.well_location_description == null &&
               wellDetailsResponse?.screen_type == null &&
               wellDetailsResponse?.screen_material == null &&
               wellDetailsResponse?.screen_intake_method == null &&
               wellDetailsResponse?.casing_set == null
              ){
                  outMap.put('NoDataForGWell', 'No well details available.');
              }
            else{
                outMap.put('WellTag_WellIDPlateNumber', wellDetailsResponse?.IDENTIFICATION_PLATE_NUMBER);
                outMap.put('WellTag_WellStatus', wellDetailsResponse?.well_status);
                outMap.put('WellTag_ArtesianCondition', wellDetailsResponse?.artesian_conditions);
                outMap.put('WellTag_AquiferNumber', wellDetailsResponse?.aquifer);
                outMap.put('WellTag_StartDateofConstruction', wellDetailsResponse?.construction_start_date);
                outMap.put('WellTag_EndDateofConstruction', wellDetailsResponse?.construction_end_date);
                outMap.put('WellTag_WellLocationDescription', wellDetailsResponse?.well_location_description);
                outMap.put('WellTag_ScreenType', wellDetailsResponse?.screen_type);
                outMap.put('WellTag_ScreenMaterial', wellDetailsResponse?.screen_material);
                outMap.put('WellTag_ScreenIntakeMethod', wellDetailsResponse?.screen_intake_method);
                if(wellDetailsResponse?.casing_set.size() > 0){
                    outMap.put('WellTag_CasingDetails', wellDetailsResponse.casing_set);
                }else{             
                    outMap.put('WellTag_CasingDetails', new PHOCSWellResponseWrapper.CasingSetItem());
                }
                if(wellDetailsResponse?.screen_set.size() > 0){
                    outMap.put('WellTag_InstalledScreens', wellDetailsResponse.screen_set);
                }else{                    
                    outMap.put('WellTag_InstalledScreens', new PHOCSWellResponseWrapper.ScreenSetItem());
                }
            }            
        } else {
            outMap.put('NoDataForGWell', 'No well details available.');
        }
        if (aquiferDetailsResponse != null || !exceptionInAQN) {
            if(aquiferDetailsResponse?.aquifer_name == null && aquiferDetailsResponse?.subtype == null && aquiferDetailsResponse?.geom?.type == null && aquiferDetailsResponse?.area == null){
                outMap.put('NoDataForAquifer', 'No aquifer details available.');
            }else{
                outMap.put('Aquifer_aquifer_name', aquiferDetailsResponse?.aquifer_name);
                outMap.put('Aquifer_subtype', aquiferDetailsResponse?.subtype);
                outMap.put('Aquifer_material_type', aquiferDetailsResponse?.geom?.type);
                outMap.put('Aquifer_size', aquiferDetailsResponse?.area);
            }            
        } else {
            outMap.put('NoDataForAquifer', 'No aquifer details available.');
        }
        return outMap;
    }
    
    private PHOCSWLSWaterRightsWrapper getWaterLicenseDetailsRequest(String licenceNumber) {
        system.debug('>>> Entered in getWaterLicenseDetailsRequest method <<<');
        try{
            waterLicenseResponse = PHOCSWLSWaterService.getWaterRightsByLicence(licenceNumber);
        }catch(Exception ex){
            exceptionInWLN = true;
        }
        system.debug('>>> Exist in getWaterLicenseDetailsRequest method <<<');
        return waterLicenseResponse;
    }
    
    private PHOCSWLSWaterApplicationsWrapper getWaterLicenseApplicationDetailsRequest(String waterApplicationNumber) {
        system.debug('>>> Entered in getWaterLicenseApplicationDetailsRequest method <<<');
        try{
            waterLicenseAppResponse = PHOCSWLSWaterService.getWaterApplicationsByJob(waterApplicationNumber);
        }catch(Exception ex){
            exceptionInWLAN = true;
        }
        system.debug('>>> Exist in getWaterLicenseApplicationDetailsRequest method <<<');
        return waterLicenseAppResponse;
    }
    
    private PHOCSAquifersResponseWrapper getAquiferDetailsRequest(String aquiferNumber){
        system.debug('>>> Entered in getAquiferDetailsRequest method <<<');
        try{
            aquiferDetailsResponse = PHOCSGwellsService.getAquiferDetails(aquiferNumber);
        }catch(Exception ex){
            exceptionInAQN = true;
        }
        system.debug('>>> Exist in getAquiferDetailsRequest method <<<');
        return aquiferDetailsResponse;
    }
    
    private PHOCSWellResponseWrapper getGWellDetailsRequest(String wellTagNumber){
        system.debug('>>> Entered in getGWellDetailsRequest method <<<');
        try{
            wellDetailsResponse = PHOCSGwellsService.getWellDetails(wellTagNumber);
        }catch(Exception ex){
            exceptionInWTN = true;
        }
        system.debug('>>> Exist in getGWellDetailsRequest method <<<');
        return wellDetailsResponse;
    }
    
    private Account getAccountDetails(String recordId) {
        if(facility == null){
            facility = [SELECT Id, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c, WellTagNumber__c, AquiferNumber__c FROM Account WHERE Id = :recordId LIMIT 1];
        }
        return facility;
    }
    
    @future
    private static void updateFacility(String recordId, Integer WellTagNumber, Integer AquiferNumber){
        Account facility = [SELECT Id, WellTagNumber__c, AquiferNumber__c FROM Account WHERE Id = :recordId LIMIT 1];
        facility.WellTagNumber__c = WellTagNumber;
        facility.AquiferNumber__c = AquiferNumber;
        update facility;
    }
}