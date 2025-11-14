/**
* ---------------------------------------------------------------------------------------------------------
*  Class Name      : PHOCSWaterLicenseService
*  Developer       : Pawan Atri
*  Title           : Retrieve water license information from the Water Rights Database (WLRS)	
*  User Story      : EHIS-1425
*  Created Date    : 16-Sept-2025
*
*  Summary:
*      This Apex service class is responsible for calling the external Water License API,
*      validating the API response, extracting required fields, and returning a mapped result
*      to the caller.
*
*      High-Level Flow:
*      1. Accept a Water License Number as input.
*      2. Make a callout (through PHOCSWaterLicenseCallout) to fetch water rights / license data.
*      3. Validate the API response using checkValidation().
*      4. If data exists, extract the following from response:
*          - License Status
*          - Well Tag Number
*          - Purpose of Use (and Code)
*          - Maximum Diversion (Quantity & Units)
*          - Point of Diversion details (Number, Type, Subtype)
*          - Source Water Body Name
*      5. If no data is found or the license number is blank, return an error map with:
*          key = 'NoDataForWaterLicense'
*          value = 'No water license details available.'
*
*      Returned Value:
*          Map<String, Object> where keys represent field names expected by PHOCS logic,
*          and values represent the corresponding water license properties.
*
*      Notes:
*          - Implements PHOCSWaterRights interface.
*          - Uses PHOCSWLSWaterRightsWrapper model class for handling JSON API response.
*          - Error handling is accomplished through flag-based validation and standard
*            error return structure.
*
* ---------------------------------------------------------------------------------------------------------
*/
public class PHOCSWaterLicenseService implements PHOCSWaterRights {
    public Static String errorKey = 'NoDataForWaterLicense';
    public Static String errorMsg = 'No water license details available.';
    
    String calloutType = 'license';
    
    public void setCalloutType(String type){
        calloutType = type;
    }
    
    public String getCalloutType(){
        return calloutType;
    }
    
    public PHOCSWLSWaterRightsWrapper runIntegration(String licenceNumber){
        PHOCSWLSWaterRightsWrapper response;
        if(getCalloutType().equalsIgnoreCase('license')){
            response = PHOCSWaterLicenseCallout.getWaterRightsByLicence(licenceNumber);
        }
        if(getCalloutType().equalsIgnoreCase('podNumber')){
            response = PHOCSWaterPODCallout.getWaterRightsByPODNumber(licenceNumber);
        }
        if(getCalloutType().equalsIgnoreCase('purposeCode')){
            response = PHOCSWaterPurposeCallout.getWaterRightsByPurposeCode(licenceNumber);
        }
        return response;
    }
    
    public Map<String, Object> mappingData(String licenceNumber){
        Boolean flag = true;
        Map<String, Object> outMap = new Map<String, Object>();
        try{
            if(String.isNotBlank(licenceNumber)){
                PHOCSWLSWaterRightsWrapper waterLicenseResponse = runIntegration(licenceNumber);
                if(checkValidation(waterLicenseResponse)){
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
                    flag = false;
                }
            }
        }catch(Exception ex){
            System.debug(ex);
        }
        if(flag){
            outMap.put(errorKey, errorMsg);
        }
        return outMap;
    }
    
    public Boolean checkValidation(Object request){
        PHOCSWLSWaterRightsWrapper waterLicenseResponse = (PHOCSWLSWaterRightsWrapper) request;
        if(
            (waterLicenseResponse == null) || 
            (waterLicenseResponse?.features == null && waterLicenseResponse?.features.size() == 0) ||
            (
                waterLicenseResponse.features[0]?.properties?.LICENCE_STATUS == null && waterLicenseResponse.features[0]?.properties?.WELL_TAG_NUMBER == null && waterLicenseResponse.features[0]?.properties?.PURPOSE_USE == null && waterLicenseResponse.features[0]?.properties?.PURPOSE_USE_CODE == null && waterLicenseResponse.features[0]?.properties?.QUANTITY == null && waterLicenseResponse.features[0]?.properties?.QUANTITY_UNITS == null && waterLicenseResponse.features[0]?.properties?.POD_NUMBER == null && waterLicenseResponse.features[0]?.properties?.POD_DIVERSION_TYPE == null && waterLicenseResponse.features[0]?.properties?.POD_SUBTYPE == null && waterLicenseResponse.features[0]?.properties?.SOURCE_NAME == null
            )
        ){
            return false;
        }
        return true;
    }
}