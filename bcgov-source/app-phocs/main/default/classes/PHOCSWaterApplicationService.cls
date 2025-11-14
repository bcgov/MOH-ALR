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
    
    public PHOCSWLSWaterApplicationsWrapper runIntegration(String waterApplicationNumber){
        return PHOCSWaterApplicationCallout.getWaterApplicationsByJob(waterApplicationNumber);
    }
    
    public Map<String, Object> mappingData(String waterApplicationNumber){
        Boolean flag = true;
        Map<String, Object> outMap = new Map<String, Object>();
        try{
            if(String.isNotBlank(waterApplicationNumber)){
                PHOCSWLSWaterApplicationsWrapper waterLicenseAppResponse = runIntegration(waterApplicationNumber);
                if(checkValidation(waterLicenseAppResponse)){
                    outMap.put('Application_WaterLicenceApplicationStatus', waterLicenseAppResponse.features[0].properties.APPLICATION_STATUS);
                    outMap.put('Application_WellTagNumber', waterLicenseAppResponse.features[0].properties.WELL_TAG_NUMBER);
                    outMap.put('Application_WaterSourceIntakeUse', waterLicenseAppResponse.features[0].properties.PURPOSE_USE);
                    outMap.put('Application_WaterSourceIntakeUseCode', waterLicenseAppResponse.features[0].properties.PURPOSE_USE_CODE);
                    outMap.put('Application_MaximumDiversion', waterLicenseAppResponse.features[0].properties.QTY_DIVERSION_MAX_RATE);
                    outMap.put('Application_MaximumDiversionUnits', waterLicenseAppResponse.features[0].properties.QTY_UNITS_DIVERSION_MAX_RATE);
                    outMap.put('Application_PointofDiversionNumber', waterLicenseAppResponse.features[0].properties.POD_NUMBER);
                    outMap.put('Application_PODDiversionType', waterLicenseAppResponse.features[0].properties.POD_DIVERSION_TYPE);
                    outMap.put('Application_PODSubtype', waterLicenseAppResponse.features[0].properties.POD_SUBTYPE);   
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
        if(
            (waterLicenseAppResponse == null) || 
            (waterLicenseAppResponse?.features == null && waterLicenseAppResponse?.features.size() == 0) ||
            (
                waterLicenseAppResponse.features[0]?.properties?.APPLICATION_STATUS == null && waterLicenseAppResponse.features[0]?.properties?.WELL_TAG_NUMBER == null && waterLicenseAppResponse.features[0]?.properties?.PURPOSE_USE == null && waterLicenseAppResponse.features[0]?.properties?.PURPOSE_USE_CODE == null && waterLicenseAppResponse.features[0]?.properties?.QTY_DIVERSION_MAX_RATE == null && waterLicenseAppResponse.features[0]?.properties?.POD_NUMBER == null && waterLicenseAppResponse.features[0]?.properties?.POD_DIVERSION_TYPE == null && waterLicenseAppResponse.features[0]?.properties?.POD_SUBTYPE == null
            )
        ){
            return false;
        }
        return true;
    }
}