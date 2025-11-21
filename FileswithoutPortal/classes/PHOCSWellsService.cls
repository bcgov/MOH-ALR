/**
* --------------------------------------------------------------------------------------------
* Name           : PHOCSWellsService
* Developer      : Pawan Atri
* Title          : Retrieve water license information from the Water Rights Database (WLRS)	
* User Story     : EHIS-1425
* Created Date   : 16-Sept-2025
*
* Description :
* This class is responsible for integrating with the external GWells API to fetch
* well details based on a Well Tag Number. It performs the following operations:
*
* 1. Calls the external GWells API using the helper service "PHOCSWellCallout".
* 2. Validates the API response to ensure the data returned contains meaningful Well attributes.
* 3. If the response is valid, the service maps key well-related properties into a
*    Map<String, Object>, including (but not limited to):
*      - Identification Plate Number
*      - Well Status
*      - Artesian Condition
*      - Aquifer Number
*      - Construction Start and End Dates
*      - Location Description
*      - Screen Specs (Material, Type, Intake Method)
*      - Casing Details & Installed Screens
* 4. If the Well Tag Number is blank OR if the API does not return useful data,
*    the class returns a Map with a predefined error key and a readable message.
*
* Key Notes:
* - This service is a part of the Water Rights integration chain:
*      License → Well Tag → Aquifer
* - It ensures non-null objects for Casing and Screen lists, providing safe defaults
*   even when the external response is empty.
* - The output Map<String, Object> allows flexible reuse in LWC, OmniScripts, flows, or Apex.
*
* Error Handling:
* - When no usable well details are found, the response includes:
*      'NoDataForGWell' : 'No well details available.'
*   which can be surfaced on UI or used in decisioning logic.
*
* Reusability:
* - Implements Interface "PHOCSWaterRights" allowing plug-and-play usage
*   within the Water Rights service workflow and any future orchestration layers.
*
* --------------------------------------------------------------------------------------------
*/

public class PHOCSWellsService implements PHOCSWaterRights {
    public Static String errorKey = 'NoDataForGWell';
    public Static String errorMsg = 'No well details available.';
    
    public PHOCSWellResponseWrapper runIntegration(String wellTagNumber){
        return PHOCSWellCallout.getWellDetails(wellTagNumber);
    }
    
    public Map<String, Object> mappingData(String wellTagNumber){
        Boolean flag = true;
        Map<String, Object> outMap = new Map<String, Object>();
        try{
            if(String.isNotBlank(wellTagNumber)){
                PHOCSWellResponseWrapper wellDetailsResponse = runIntegration(wellTagNumber);
                PHOCSWaterKeys.setWellDetails(wellDetailsResponse);
                if(checkValidation(wellDetailsResponse)){
                    
                    outMap.put('WellTag_WellIDPlateNumber', PHOCSWaterKeys.WELL_ID_PLATE);
                    outMap.put('WellTag_WellStatus', PHOCSWaterKeys.WELL_STATUS);
                    outMap.put('WellTag_ArtesianCondition', PHOCSWaterKeys.ARTESIAN);
                    outMap.put('WellTag_AquiferNumber', PHOCSWaterKeys.AQUIFER_NUM);
                    outMap.put('WellTag_StartDateofConstruction', PHOCSWaterKeys.CONS_START);
                    outMap.put('WellTag_EndDateofConstruction', PHOCSWaterKeys.CONS_END);
                    outMap.put('WellTag_WellLocationDescription', PHOCSWaterKeys.WELL_LOC_DESC);
                    outMap.put('WellTag_ScreenType', PHOCSWaterKeys.SCREEN_TYPE);
                    outMap.put('WellTag_ScreenMaterial', PHOCSWaterKeys.SCREEN_MAT);
                    outMap.put('WellTag_ScreenIntakeMethod', PHOCSWaterKeys.SCREEN_INTAKE);
                    
                    if(wellDetailsResponse?.casing_set.size() > 0){
                        outMap.put('WellTag_CasingDetails', PHOCSWaterKeys.CASING_DETAILS);
                    }else{             
                        outMap.put('WellTag_CasingDetails', new PHOCSWellResponseWrapper.CasingSetItem());
                    }
                    if(wellDetailsResponse?.screen_set.size() > 0){
                        outMap.put('WellTag_InstalledScreens', PHOCSWaterKeys.INSTALLED_SCREENS);
                    }else{                    
                        outMap.put('WellTag_InstalledScreens', new PHOCSWellResponseWrapper.ScreenSetItem());
                    }
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
        PHOCSWellResponseWrapper wellDetailsResponse = (PHOCSWellResponseWrapper) request;
        PHOCSWaterKeys.setWellDetails(wellDetailsResponse);
        if(
            (wellDetailsResponse == null) || 
            (
                PHOCSWaterKeys.WELL_ID_PLATE == null &&
                PHOCSWaterKeys.WELL_STATUS == null &&
                PHOCSWaterKeys.ARTESIAN == null &&
                PHOCSWaterKeys.AQUIFER_NUM == null &&
                PHOCSWaterKeys.CONS_START == null &&
                PHOCSWaterKeys.CONS_END == null &&
                PHOCSWaterKeys.WELL_LOC_DESC == null &&
                PHOCSWaterKeys.SCREEN_TYPE == null &&
                PHOCSWaterKeys.SCREEN_MAT == null &&
                PHOCSWaterKeys.SCREEN_INTAKE == null &&
                PHOCSWaterKeys.CASING_DETAILS == null &&
                PHOCSWaterKeys.INSTALLED_SCREENS == null
            )
        ){
            return false;
        }
        return true;
    }
}