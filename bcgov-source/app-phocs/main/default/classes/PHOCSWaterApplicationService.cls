/**
* -------------------------------------------------------------------------------------------
*  Class Name     : PHOCSWaterApplicationService
*  Developer      : Pawan Atri
*  Title          : Retrieve water license information from the Water Rights Database (WLRS)	
*  User Story     : EHIS-1425
*  Created Date   : 16-Sept-2025
*
*  Summary:
*  This Apex service class is used to fetch and process Water Application data
*  from the external Water Rights Integration system. It performs the following:
*
*   1. Accepts a Water Application Number sent from trigger, batch, or queueable job.
*   2. Makes a callout via PHOCSWaterApplicationCallout.getWaterApplicationsByJob()
*      to retrieve a `PHOCSWLSWaterApplicationsWrapper` response.
*   3. Validates the response using `checkValidation()` to ensure the API returned data.
*   4. If valid data exists, it extracts multiple fields from the API response such as:
*        - APPLICATION_STATUS
*        - WELL_TAG_NUMBER
*        - PURPOSE_USE & PURPOSE_USE_CODE
*        - QTY_DIVERSION_MAX_RATE & UNITS
*        - POD Diversion details (POD_NUMBER, POD_DIVERSION_TYPE, POD_SUBTYPE)
*      These values are returned in a key-value map for further processing or record updates.
*   5. If input is blank or API returns empty/invalid response, the method returns an
*      error message with a custom error key: `NoDataForLicenseApplication`.
*
*  Return Structure:
*      A Map<String,Object> containing either mapped Application data
*      or an error message if no valid data exists.
*
*  Notes:
*      - This class implements PHOCSWaterRights interface.
*      - Used by integration flows to update Account, Opportunities or Custom Objects.
*      - Can be invoked by Queueable, Batch Apex, Platform Events or Trigger handlers.
*
* -------------------------------------------------------------------------------------------
*/
public class PHOCSWaterApplicationService implements PHOCSWaterRights {
    public Static String errorKey = 'NoDataForLicenseApplication';
    public Static String errorMsg = 'No water license application details available.';
    
    String applicationNumber;
    String podNumber;
    String purposeCode;
    
    public void setValues(String applicationNumber, String podNumber, String purposeCode){
        this.applicationNumber = applicationNumber;
        this.podNumber = podNumber;
        this.purposeCode = purposeCode;
    }
    
    public PHOCSWLSWaterApplicationsWrapper runIntegration(String waterApplicationNumber){
        return null;
    }
    
    public PHOCSWLSWaterApplicationsWrapper runIntegration(String applicationNumber, String podNumber, String purposeCode){
        return PHOCSWaterApplicationCallout.getWaterApplicationsByJob(applicationNumber, podNumber, purposeCode);
    }
    
    public Map<String, Object> mappingData(String waterApplicationNumber){
        Boolean flag = true;
        Map<String, Object> outMap = new Map<String, Object>();
        try{
            if(String.isNotBlank(this.applicationNumber) && String.isNotBlank(this.podNumber) && String.isNotBlank(this.purposeCode)){
                PHOCSWLSWaterApplicationsWrapper waterLicenseAppResponse = runIntegration(this.applicationNumber, this.podNumber, this.purposeCode);
                if(checkValidation(waterLicenseAppResponse)){
                    
                    outMap.put('Application_WaterLicenceApplicationStatus', PHOCSWaterKeys.APP_STATUS);
                    outMap.put('Application_WellTagNumber', PHOCSWaterKeys.APP_WELL_TAG);
                    outMap.put('Application_WaterSourceIntakeUse', PHOCSWaterKeys.APP_PURPOSE_USE);
                    outMap.put('Application_WaterSourceIntakeUseCode', PHOCSWaterKeys.APP_PURPOSE_USE_CODE);
                    outMap.put('Application_MaximumDiversion', PHOCSWaterKeys.APP_QTY_DIV_MAX_RATE);
                    outMap.put('Application_MaximumDiversionUnits', PHOCSWaterKeys.APP_QTY_UNITS_DIV_MAX_RATE);
                    outMap.put('Application_PointofDiversionNumber', PHOCSWaterKeys.APP_POD_NUMBER);
                    outMap.put('Application_PODDiversionType', PHOCSWaterKeys.APP_POD_DIV_TYPE);
                    outMap.put('Application_PODSubtype', PHOCSWaterKeys.APP_POD_SUBTYPE);
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
        PHOCSWLSWaterApplicationsWrapper waterLicenseAppResponse = (PHOCSWLSWaterApplicationsWrapper) request;
        PHOCSWaterKeys.setApplicationDetails(waterLicenseAppResponse);
        if(
            (waterLicenseAppResponse == null) || 
            (waterLicenseAppResponse?.features == null && waterLicenseAppResponse?.features.size() == 0) ||
            (
                PHOCSWaterKeys.APP_STATUS == null && 
                PHOCSWaterKeys.APP_WELL_TAG == null && 
                PHOCSWaterKeys.APP_PURPOSE_USE == null && 
                PHOCSWaterKeys.APP_PURPOSE_USE_CODE == null && 
                PHOCSWaterKeys.APP_QTY_DIV_MAX_RATE == null && 
                PHOCSWaterKeys.APP_QTY_UNITS_DIV_MAX_RATE == null && 
                PHOCSWaterKeys.APP_POD_NUMBER == null && 
                PHOCSWaterKeys.APP_POD_SUBTYPE == null && 
                PHOCSWaterKeys.APP_POD_DIV_TYPE == null
            )
        ){
            return false;
        }
        return true;
    }
}