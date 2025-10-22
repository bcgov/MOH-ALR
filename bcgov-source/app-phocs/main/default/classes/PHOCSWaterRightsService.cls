global with sharing class PHOCSWaterRightsService implements Callable {

    // per-invocation context (no static mutable state)
    private Account facility;
    private PHOCSWLSWaterRightsWrapper  wlResp;
    private PHOCSWLSWaterApplicationsWrapper wlaResp;
    private PHOCSWellResponseWrapper    wellResp;
    private PHOCSAquifersResponseWrapper aqResp;

    // light error collector (optional to expose later)
    private List<String> errors = new List<String>();

    // ------------------ Callable entry ------------------
    global Object call(String action, Map<String, Object> args) {
        final Map<String, Object> input   = (Map<String, Object>) args.get(PHOCSKeys.INPUT);
        final Map<String, Object> output  = (Map<String, Object>) args.get(PHOCSKeys.OUTPUT);
        final Map<String, Object> options = (Map<String, Object>) args.get(PHOCSKeys.OPTIONS);

        return invoke(action, input, output, options);
    }

    private Object invoke(String action, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        System.debug('>>> PHOCSWaterRightsService.invoke: ' + action);

        // load account once per invocation
        final String recordId = String.valueOf(input.get(PHOCSKeys.RECORD_ID));
        facility = loadAccount(recordId);

        // run upstream integration to hydrate dependent datasets & update account
        runIntegration(facility);

        // route action
        // --- Route action ---
        if (action == PHOCSKeys.ACT_WL) {
            output.putAll(mapWaterLicence());
        }
        else if (action == PHOCSKeys.ACT_WLA) {
            output.putAll(mapWaterLicenceApplication());
        }
        else if (action == PHOCSKeys.ACT_AQ) {
            output.putAll(mapAquifer());
        }
        else if (action == PHOCSKeys.ACT_WELL) {
            output.putAll(mapWell());
        }
        else if (action == PHOCSKeys.ACT_CASING) {
            output.putAll(mapCasing());
        }
        else if (action == PHOCSKeys.ACT_SCREENS) {
            output.putAll(mapScreens());
        }
        else {
            output.put(PHOCSKeys.NODATA, 'Unknown action: ' + action);
        }

        System.debug('<<< PHOCSWaterRightsService.invoke done');
        return output; // always return whole map
    }

    // ------------------ Integration flow ------------------
    private void runIntegration(Account acc) {
        if (acc == null) return;

        Integer wellTag = null;
        Integer aquiferNum = null;

        // 1) Water Licence → Well → Aquifer chain
        if (String.isNotBlank(acc.WaterLicenseNumber__c)) {
            try {
                wlResp = PHOCSWLSWaterService.getWaterRightsByLicence(acc.WaterLicenseNumber__c);
                if (hasFeatures(wlResp)) {
                    wellTag = wlResp.features[0]?.properties.WELL_TAG_NUMBER;
                    if (wellTag != null) {
                        wellResp = safeGetWellDetails(String.valueOf(wellTag));
                        if (wellResp != null && wellResp.aquifer != null) {
                            aquiferNum = Integer.valueOf(wellResp.aquifer);
                            aqResp = safeGetAquiferDetails(wellResp.aquifer);
                        }
                    }
                }
            } catch (Exception ex) {
                errors.add('WL fetch failed: ' + ex.getMessage());
            }
        }

        // 2) Water Licence Application path (only if WL not present)
        if (String.isNotBlank(acc.WaterLicenseApplicationNumber__c) && String.isBlank(acc.WaterLicenseNumber__c)) {
            try {
                wlaResp = PHOCSWLSWaterService.getWaterApplicationsByJob(acc.WaterLicenseApplicationNumber__c);
                if (hasFeatures(wlaResp)) {
                    wellTag = wlaResp.features[0]?.properties.WELL_TAG_NUMBER;
                    if (wellTag != null) {
                        wellResp = safeGetWellDetails(String.valueOf(wellTag));
                        if (wellResp != null && wellResp.aquifer != null) {
                            aquiferNum = Integer.valueOf(wellResp.aquifer);
                            aqResp = safeGetAquiferDetails(wellResp.aquifer);
                        }
                    }
                }
            } catch (Exception ex) {
                errors.add('WLA fetch failed: ' + ex.getMessage());
            }
        }

        // 3) Persist discovered Well/Aquifer numbers back to the facility
        upsertFacilityDerivedValues(wellTag, aquiferNum);
    }

    // ------------------ Mapping methods (pure-ish) ------------------
    private Map<String, Object> mapWaterLicence() {
        Map<String, Object> out = new Map<String, Object>();
        if (!hasFeatures(wlResp)) {
            out.put(PHOCSKeys.NODATA, PHOCSKeys.MSG_NO_WL);
            return out;
        }

        final PHOCSWLSWaterRightsWrapper.Feature f = wlResp.features[0];
        final Boolean allNull =
            f.properties.LICENCE_STATUS == null &&
            f.properties.WELL_TAG_NUMBER == null &&
            f.properties.PURPOSE_USE == null &&
            f.properties.PURPOSE_USE_CODE == null &&
            f.properties.QUANTITY == null &&
            f.properties.QUANTITY_UNITS == null &&
            f.properties.POD_NUMBER == null &&
            f.properties.POD_DIVERSION_TYPE == null &&
            f.properties.POD_SUBTYPE == null &&
            f.properties.SOURCE_NAME == null;

        if (allNull) {
            out.put(PHOCSKeys.NODATA, PHOCSKeys.MSG_NO_WL);
            return out;
        }

        out.put(PHOCSKeys.LIC_STATUS,  f.properties.LICENCE_STATUS);
        out.put(PHOCSKeys.WELL_TAG,    f.properties.WELL_TAG_NUMBER);
        out.put(PHOCSKeys.PURPOSE,     f.properties.PURPOSE_USE);
        out.put(PHOCSKeys.PURPOSE_CD,  f.properties.PURPOSE_USE_CODE);
        out.put(PHOCSKeys.MAX_DIV,     f.properties.QUANTITY);
        out.put(PHOCSKeys.MAX_DIV_U,   f.properties.QUANTITY_UNITS);
        out.put(PHOCSKeys.POD_NUM,     f.properties.POD_NUMBER);
        out.put(PHOCSKeys.POD_TYPE,    f.properties.POD_DIVERSION_TYPE);
        out.put(PHOCSKeys.POD_SUBT,    f.properties.POD_SUBTYPE);
        out.put(PHOCSKeys.SRC_WATER,   f.properties.SOURCE_NAME);
        if (facility != null) out.put(PHOCSKeys.ACCOUNT_ID, facility.Id);

        return out;
    }

    private Map<String, Object> mapWaterLicenceApplication() {
        Map<String, Object> out = new Map<String, Object>();
        if (!hasFeatures(wlaResp)) {
            out.put(PHOCSKeys.NODATA, PHOCSKeys.MSG_NO_WLA);
            return out;
        }

        final PHOCSWLSWaterApplicationsWrapper.Feature f = wlaResp.features[0];
        final Boolean allNull =
            f.properties.APPLICATION_STATUS == null &&
            f.properties.WELL_TAG_NUMBER == null &&
            f.properties.PURPOSE_USE == null &&
            f.properties.PURPOSE_USE_CODE == null &&
            f.properties.QTY_DIVERSION_MAX_RATE == null &&
            f.properties.POD_NUMBER == null &&
            f.properties.POD_DIVERSION_TYPE == null &&
            f.properties.POD_SUBTYPE == null;

        if (allNull) {
            out.put(PHOCSKeys.NODATA, PHOCSKeys.MSG_NO_WLA);
            return out;
        }

        out.put(PHOCSKeys.LIC_STATUS, f.properties.APPLICATION_STATUS);
        out.put(PHOCSKeys.WELL_TAG,   f.properties.WELL_TAG_NUMBER);
        out.put(PHOCSKeys.PURPOSE,    f.properties.PURPOSE_USE);
        out.put(PHOCSKeys.PURPOSE_CD, f.properties.PURPOSE_USE_CODE);
        out.put(PHOCSKeys.MAX_DIV,    f.properties.QTY_DIVERSION_MAX_RATE);
        out.put(PHOCSKeys.MAX_DIV_U,  f.properties.QTY_UNITS_DIVERSION_MAX_RATE);
        out.put(PHOCSKeys.POD_NUM,    f.properties.POD_NUMBER);
        out.put(PHOCSKeys.POD_TYPE,   f.properties.POD_DIVERSION_TYPE);
        out.put(PHOCSKeys.POD_SUBT,   f.properties.POD_SUBTYPE);
        return out;
    }

    private Map<String, Object> mapAquifer() {
        Map<String, Object> out = new Map<String, Object>();
        if (aqResp == null ||
            (aqResp.aquifer_name == null && aqResp.subtype == null && aqResp.geom?.type == null && aqResp.area == null)) {
            out.put(PHOCSKeys.NODATA, PHOCSKeys.MSG_NO_AQ);
            return out;
        }
        out.put(PHOCSKeys.AQUIFER_NAME, aqResp.aquifer_name);
        out.put(PHOCSKeys.AQUIFER_SUBT, aqResp.subtype);
        out.put(PHOCSKeys.AQUIFER_MAT,  aqResp.geom?.type);
        out.put(PHOCSKeys.AQUIFER_SIZE, aqResp.area);
        return out;
    }

    private Map<String, Object> mapWell() {
        Map<String, Object> out = new Map<String, Object>();
        if (wellResp == null ||
            (wellResp.IDENTIFICATION_PLATE_NUMBER == null &&
             wellResp.well_status == null &&
             wellResp.artesian_conditions == null &&
             wellResp.aquifer == null &&
             wellResp.construction_start_date == null &&
             wellResp.construction_end_date == null &&
             wellResp.well_location_description == null &&
             wellResp.screen_type == null &&
             wellResp.screen_material == null &&
             wellResp.screen_intake_method == null &&
             wellResp.casing_set == null)) {
            out.put(PHOCSKeys.NODATA, PHOCSKeys.MSG_NO_WELL);
            return out;
        }

        out.put(PHOCSKeys.WELL_ID_PLATE, wellResp.IDENTIFICATION_PLATE_NUMBER);
        out.put(PHOCSKeys.WELL_STATUS,   wellResp.well_status);
        out.put(PHOCSKeys.ARTESIAN,      wellResp.artesian_conditions);
        out.put(PHOCSKeys.AQUIFER_NUM,   wellResp.aquifer);
        out.put(PHOCSKeys.CONS_START,    wellResp.construction_start_date);
        out.put(PHOCSKeys.CONS_END,      wellResp.construction_end_date);
        out.put(PHOCSKeys.WELL_LOC_DESC, wellResp.well_location_description);
        out.put(PHOCSKeys.SCREEN_TYPE,   wellResp.screen_type);
        out.put(PHOCSKeys.SCREEN_MAT,    wellResp.screen_material);
        out.put(PHOCSKeys.SCREEN_INTAKE, wellResp.screen_intake_method);
        return out;
    }

    private Map<String, Object> mapCasing() {
        Map<String, Object> out = new Map<String, Object>();
        if (wellResp != null && wellResp.casing_set != null && wellResp.casing_set.size() > 0) {
            out.put(PHOCSKeys.CASING_DETAILS, wellResp.casing_set);
        } else {
            out.put(PHOCSKeys.CASING_DETAILS, new PHOCSWellResponseWrapper.CasingSetItem());
        }
        return out;
    }

    private Map<String, Object> mapScreens() {
        Map<String, Object> out = new Map<String, Object>();
        if (wellResp != null && wellResp.screen_set != null && wellResp.screen_set.size() > 0) {
            out.put(PHOCSKeys.INSTALLED_SCREENS, wellResp.screen_set);
        } else {
            out.put(PHOCSKeys.INSTALLED_SCREENS, new PHOCSWellResponseWrapper.ScreenSetItem());
        }
        return out;
    }

    // ------------------ Data access helpers ------------------
    private Account loadAccount(String recordId) {
        if (String.isBlank(recordId)) return null;
        return [
            SELECT Id, WaterLicenseNumber__c, WaterLicenseApplicationNumber__c,
                   WellTagNumber__c, AquiferNumber__c
            FROM Account
            WHERE Id = :recordId
            LIMIT 1
        ];
    }

    private Boolean hasFeatures(PHOCSWLSWaterRightsWrapper r) {
        return r != null && r.features != null && r.features.size() > 0;
    }
    private Boolean hasFeatures(PHOCSWLSWaterApplicationsWrapper r) {
        return r != null && r.features != null && r.features.size() > 0;
    }

    private PHOCSWellResponseWrapper safeGetWellDetails(String wellTagNumber) {
        try {
            return PHOCSGwellsService.getWellDetails(wellTagNumber);
        } catch (Exception ex) {
            errors.add('Well fetch failed: ' + ex.getMessage());
            return null;
        }
    }

    private PHOCSAquifersResponseWrapper safeGetAquiferDetails(String aquiferNumber) {
        try {
            return PHOCSGwellsService.getAquiferDetails(aquiferNumber);
        } catch (Exception ex) {
            errors.add('Aquifer fetch failed: ' + ex.getMessage());
            return null;
        }
    }

    private void upsertFacilityDerivedValues(Integer wellTag, Integer aquiferNum) {
        if (facility == null) return;

        Boolean changed = false;
        if (wellTag != null && facility.WellTagNumber__c != wellTag) {
            facility.WellTagNumber__c = wellTag;
            changed = true;
        }
        if (aquiferNum != null && facility.AquiferNumber__c != aquiferNum) {
            facility.AquiferNumber__c = aquiferNum;
            changed = true;
        }
        if (changed) {
            try {
                update facility;
            } catch (DmlException d) {
                errors.add('Facility update failed: ' + d.getMessage());
            }
        }
    }
}