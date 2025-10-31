global with sharing class PHOCSWaterRightsService implements Callable {
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

        if (methodName == 'getWaterLicenseDetails') {
            outMap.putAll(getWaterLicenseDetails());
        }
        if (methodName == 'getWaterLicenseApplicationDetails') {
            outMap.putAll(getWaterLicenseApplicationDetails());
        }
        if (methodName == 'getAquifersDetails') {
            outMap.putAll(getAquiferDetails());
        }
        if (methodName == 'getGWellDetails') {
            outMap.putAll(getGWellDetails());
        }
        if (methodName == 'getGWellCasingDetails') {            
            if(wellDetailsResponse != null && wellDetailsResponse?.casing_set.size() > 0){
                outMap.put('CasingDetails', wellDetailsResponse.casing_set);
            }else{
                outMap.put('CasingDetails', new PHOCSWellResponseWrapper.CasingSetItem());
            }            
        }
        if (methodName == 'getGWellInstalledDetails') {            
            if(wellDetailsResponse != null && wellDetailsResponse?.screen_set.size() > 0){
                outMap.put('InstalledScreens', wellDetailsResponse.screen_set);
            }else{
                outMap.put('InstalledScreens', new PHOCSWellResponseWrapper.ScreenSetItem());
            }            
        }
        system.debug('>>> Exist in invokeMethod method <<<');
        return outMap; // always return the whole map
    }
	
    private void integrationFlow(Account acc){
        system.debug('>>> Entered in integrationFlow method <<<');
        Integer wellTagNumber = null;
        Integer aquiferNumber = null;
        if(acc != null && String.isBlank(acc.WaterLicenseNumber__c) && String.isBlank(acc.WaterLicenseApplicationNumber__c)){
            updateFacility(wellTagNumber, aquiferNumber);
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
            updateFacility(wellTagNumber, aquiferNumber);
        }        
        system.debug('>>> Exist in integrationFlow method <<<');
    }

    private Map<String, Object> getWaterLicenseDetails() {
        system.debug('>>> Entered in getWaterLicenseDetails method <<<');
        Map<String, Object> outMap = new Map<String, Object>();
        if(waterLicenseResponse != null || !exceptionInWLN) {
            // Put the wrapper directly into the output map
            if(waterLicenseResponse.features != null && waterLicenseResponse.features.size() > 0){
                System.debug(waterLicenseResponse.features);
                System.debug('LICENCE_STATUS: ' + waterLicenseResponse.features[0].properties?.LICENCE_STATUS);
                System.debug('WELL_TAG_NUMBER: ' + waterLicenseResponse.features[0].properties.WELL_TAG_NUMBER);
                System.debug('PURPOSE_USE: ' + waterLicenseResponse.features[0].properties.PURPOSE_USE);
                System.debug('PURPOSE_USE_CODE: ' + waterLicenseResponse.features[0].properties.PURPOSE_USE_CODE);
                System.debug('QUANTITY: ' + waterLicenseResponse.features[0].properties.QUANTITY);
                System.debug('QUANTITY_UNITS: ' + waterLicenseResponse.features[0].properties.QUANTITY_UNITS);
                System.debug('POD_NUMBER: ' + waterLicenseResponse.features[0].properties.POD_NUMBER);
                System.debug('POD_DIVERSION_TYPE: ' + waterLicenseResponse.features[0].properties.POD_DIVERSION_TYPE);
                System.debug('POD_SUBTYPE: ' + waterLicenseResponse.features[0].properties.POD_SUBTYPE);
                System.debug('SOURCE_NAME: ' + waterLicenseResponse.features[0].properties.SOURCE_NAME);

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
                      outMap.put('NoData', 'No water license details available.');
                  }else{
                      outMap.put('WaterLicenceStatus', waterLicenseResponse.features[0].properties.LICENCE_STATUS);
                      outMap.put('WellTagNumber', waterLicenseResponse.features[0].properties.WELL_TAG_NUMBER);
                      outMap.put('WaterSourceIntakeUse', waterLicenseResponse.features[0].properties.PURPOSE_USE);
                      outMap.put('WaterSourceIntakeUseCode', waterLicenseResponse.features[0].properties.PURPOSE_USE_CODE);
                      outMap.put('MaximumDiversion', waterLicenseResponse.features[0].properties.QUANTITY);
                      outMap.put('MaximumDiversionUnits', waterLicenseResponse.features[0].properties.QUANTITY_UNITS);
                      outMap.put('PointofDiversionNumber', waterLicenseResponse.features[0].properties.POD_NUMBER);
                      outMap.put('PODDiversionType', waterLicenseResponse.features[0].properties.POD_DIVERSION_TYPE);
                      outMap.put('PODSubtype', waterLicenseResponse.features[0].properties.POD_SUBTYPE);
                      outMap.put('SourceWaterBodyName', waterLicenseResponse.features[0].properties.SOURCE_NAME);
                      outMap.put('AccountId', facility.Id);
                  }                
            }
        } else {
            outMap.put('NoData', 'No water license details available.');
        }
        system.debug('>>> Exist in getWaterLicenseDetails method <<<');
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

    private Map<String, Object> getWaterLicenseApplicationDetails() {
        system.debug('>>> Entered in getWaterLicenseApplicationDetails method <<<');
        Map<String, Object> outMap = new Map<String, Object>();
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
                      outMap.put('NoData', 'No water license application details available.');
                  }else{
                      outMap.put('WaterLicenceApplicationStatus', waterLicenseAppResponse.features[0].properties.APPLICATION_STATUS);
                      outMap.put('WellTagNumber', waterLicenseAppResponse.features[0].properties.WELL_TAG_NUMBER);
                      outMap.put('WaterSourceIntakeUse', waterLicenseAppResponse.features[0].properties.PURPOSE_USE);
                      outMap.put('WaterSourceIntakeUseCode', waterLicenseAppResponse.features[0].properties.PURPOSE_USE_CODE);
                      outMap.put('MaximumDiversion', waterLicenseAppResponse.features[0].properties.QTY_DIVERSION_MAX_RATE);
                      outMap.put('MaximumDiversionUnits', waterLicenseAppResponse.features[0].properties.QTY_UNITS_DIVERSION_MAX_RATE);
                      outMap.put('PointofDiversionNumber', waterLicenseAppResponse.features[0].properties.POD_NUMBER);
                      outMap.put('PODDiversionType', waterLicenseAppResponse.features[0].properties.POD_DIVERSION_TYPE);
                      outMap.put('PODSubtype', waterLicenseAppResponse.features[0].properties.POD_SUBTYPE);
                  }                
            }
        } else {
            outMap.put('NoData', 'No water license application details available.');
        }
        system.debug('>>> Exist in getWaterLicenseApplicationDetails method <<<');
        return outMap;
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

    private Map<String, Object> getAquiferDetails(){
        system.debug('>>> Entered in getAquiferDetails method <<<');
        Map<String, Object> outMap = new Map<String, Object>();
        if (aquiferDetailsResponse != null || !exceptionInAQN) {
            if(aquiferDetailsResponse?.aquifer_name == null && aquiferDetailsResponse?.subtype == null && aquiferDetailsResponse?.geom?.type == null && aquiferDetailsResponse?.area == null){
                outMap.put('NoData', 'No aquifer details available.');
            }else{
                outMap.put('aquifer_name', aquiferDetailsResponse?.aquifer_name);
                outMap.put('subtype', aquiferDetailsResponse?.subtype);
                outMap.put('material_type', aquiferDetailsResponse?.geom?.type);
                outMap.put('size', aquiferDetailsResponse?.area);
            }            
        } else {
            outMap.put('NoData', 'No aquifer details available.');
        }
        system.debug('>>> Exist in getAquiferDetails method <<<');
        return outMap;
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

    private Map<String, Object> getGWellDetails(){
        system.debug('>>> Entered in getGWellDetails method <<<');
        Map<String, Object> outMap = new Map<String, Object>();
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
                  outMap.put('NoData', 'No well details available.');
              }
            else{
                outMap.put('WellIDPlateNumber', wellDetailsResponse?.IDENTIFICATION_PLATE_NUMBER);
                outMap.put('WellStatus', wellDetailsResponse?.well_status);
                outMap.put('ArtesianCondition', wellDetailsResponse?.artesian_conditions);
                outMap.put('AquiferNumber', wellDetailsResponse?.aquifer);
                outMap.put('StartDateofConstruction', wellDetailsResponse?.construction_start_date);
                outMap.put('EndDateofConstruction', wellDetailsResponse?.construction_end_date);
                outMap.put('WellLocationDescription', wellDetailsResponse?.well_location_description);
                outMap.put('ScreenType', wellDetailsResponse?.screen_type);
                outMap.put('ScreenMaterial', wellDetailsResponse?.screen_material);
                outMap.put('ScreenIntakeMethod', wellDetailsResponse?.screen_intake_method);                                
            }            
        } else {
            outMap.put('NoData', 'No well details available.');
        }
        system.debug('>>> Exist in getGWellDetails method <<<');
        return outMap;
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

    //@future
    private static void updateFacility(Integer WellTagNumber, Integer AquiferNumber){
        if(WellTagNumber != null)
            facility.WellTagNumber__c = WellTagNumber;
        if(AquiferNumber != null)
            facility.AquiferNumber__c = AquiferNumber;
        if(WellTagNumber != null && AquiferNumber != null)
            update facility;
    }
}