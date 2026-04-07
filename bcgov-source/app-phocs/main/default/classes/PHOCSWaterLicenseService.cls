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
    
    String licenseNumber;
    String podNumber;
    String purposeCode;
    
    public void setValues(String licenseNumber, String podNumber, String purposeCode){
        this.licenseNumber = licenseNumber;
        this.podNumber = podNumber;
        this.purposeCode = purposeCode;
    }
    
    public PHOCSWLSWaterRightsWrapper runIntegration(String licenceNumber){
        return null;
    }
    
    public PHOCSWLSWaterRightsWrapper runIntegration(String licenseNumber, String podNumber, String purposeCode){
        return PHOCSWaterLicenseCallout.getWaterRightsByLicence(licenseNumber, podNumber, purposeCode);
    }
    
    public Map<String, Object> mappingData(String licenceNumber){
        Boolean flag = true;
        Map<String, Object> outMap = new Map<String, Object>();
        try{
            if(String.isNotBlank(this.licenseNumber) && String.isNotBlank(this.podNumber) && String.isNotBlank(this.purposeCode)){
                PHOCSWLSWaterRightsWrapper waterLicenseResponse = runIntegration(this.licenseNumber, this.podNumber, this.purposeCode);
                PHOCSWaterKeys.setLicenseDetails(waterLicenseResponse);
                if(checkValidation(waterLicenseResponse)){
                    
                    outMap.put('License_WaterLicenceStatus', PHOCSWaterKeys.LIC_STATUS);
                    outMap.put('License_WellTagNumber', PHOCSWaterKeys.LIC_WELL_TAG);
                    outMap.put('License_WaterSourceIntakeUse', PHOCSWaterKeys.LIC_PURPOSE);
                    outMap.put('License_WaterSourceIntakeUseCode', PHOCSWaterKeys.LIC_PURPOSE_CD);
                    outMap.put('License_MaximumDiversion', PHOCSWaterKeys.LIC_QUAN);
                    outMap.put('License_MaximumDiversionUnits', PHOCSWaterKeys.LIC_QUAN_UNT);
                    outMap.put('License_PointofDiversionNumber', PHOCSWaterKeys.LIC_POD_NUM);
                    outMap.put('License_PODDiversionType', PHOCSWaterKeys.LIC_POD_TYPE);
                    outMap.put('License_PODSubtype', PHOCSWaterKeys.LIC_POD_SUBT);
                    outMap.put('License_SourceWaterBodyName', PHOCSWaterKeys.LIC_SRC_WATER);
                    
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
        PHOCSWaterKeys.setLicenseDetails(waterLicenseResponse);
        if(
            (waterLicenseResponse == null) || 
            (waterLicenseResponse?.features == null && waterLicenseResponse?.features.size() == 0) ||
            (
                PHOCSWaterKeys.LIC_STATUS == null && 
                PHOCSWaterKeys.LIC_WELL_TAG == null && 
                PHOCSWaterKeys.LIC_PURPOSE == null && 
                PHOCSWaterKeys.LIC_PURPOSE_CD == null && 
                PHOCSWaterKeys.LIC_QUAN == null && 
                PHOCSWaterKeys.LIC_QUAN_UNT == null && 
                PHOCSWaterKeys.LIC_POD_NUM == null && 
                PHOCSWaterKeys.LIC_POD_TYPE == null && 
                PHOCSWaterKeys.LIC_POD_SUBT == null && 
                PHOCSWaterKeys.LIC_SRC_WATER == null
            )
        ){
            return false;
        }
        return true;
    }
}