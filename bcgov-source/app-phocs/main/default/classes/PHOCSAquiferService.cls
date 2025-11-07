/**
 * --------------------------------------------------------------------------------------------
 * Name        	  : PHOCSAquiferService
 * Developer      : Pawan Atri
 * Title          : Retrieve water license information from the Water Rights Database (WLRS)	
 * User Story     : EHIS-1425
 * Created Date   : 16-Sept-2025
 *
 * Description :
 * This class is responsible for integrating with the external Water Rights API to fetch
 * aquifer details based on an Aquifer Number. It performs the following steps:
 *
 * 1. Calls the external Aquifer API using the helper class "PHOCSAquiferCallout".
 * 2. Validates the response to ensure that meaningful data is returned from the external system.
 * 3. If valid, maps the key properties such as:
 *      - Aquifer Name
 *      - Subtype
 *      - Material Type (from geometry)
 *      - Size (area)
 * 4. If the aquifer number is blank OR the service returns no usable data,
 *    it returns a response map containing a default error key with a readable message.
 *
 * Key Notes:
 * - Used by Water Rights Integration workflow where Aquifer details are fetched
 *   after Well Tag lookup.
 * - All response data is returned as a Map<String, Object> so it can be reused
 *   in FlexCards, LWC, flows, or Apex.
 * - "checkValidation" ensures response contains meaningful fields before mapping.
 *
 * Error Handling:
 * - When no data is found, a predefined "errorKey" and "errorMsg" are added in the result map
 *   which can be used to show user-friendly messages on UI.
 *
 * Reusability:
 * - Implemented Interface "PHOCSWaterRights" making the service plug-and-play in
 *   the Water Rights service chain (License → Well → Aquifer → Application).
 *
 * --------------------------------------------------------------------------------------------
 */

public class PHOCSAquiferService implements PHOCSWaterRights {
    public Static String errorKey = 'NoDataForAquifer';
    public Static String errorMsg = 'No aquifer details available.';
    
    public PHOCSAquifersResponseWrapper runIntegration(String aquiferNumber){
        return PHOCSAquiferCallout.getAquiferDetails(aquiferNumber);
    }
    
    public Map<String, Object> mappingData(String aquiferNumber){
        Boolean flag = false;
        Map<String, Object> outMap = new Map<String, Object>();
        if(String.isNotBlank(aquiferNumber)){
            PHOCSAquifersResponseWrapper aquiferDetailsResponse = runIntegration(aquiferNumber);
            if(checkValidation(aquiferDetailsResponse)){
                outMap.put('Aquifer_aquifer_name', aquiferDetailsResponse?.aquifer_name);
                outMap.put('Aquifer_subtype', aquiferDetailsResponse?.subtype);
                outMap.put('Aquifer_material_type', aquiferDetailsResponse?.geom?.type);
                outMap.put('Aquifer_size', aquiferDetailsResponse?.area);           
            }else{
                flag = true;
            }
        }else{
            flag = true;
        }
        System.debug('PHOCSAquiferService-Flag: ' + flag);
        if(flag){
            outMap.put(errorKey, errorMsg);
        }
        return outMap;
    }
    
    public Boolean checkValidation(Object request){
        PHOCSAquifersResponseWrapper aquiferDetailsResponse = (PHOCSAquifersResponseWrapper) request;
        if(
            (aquiferDetailsResponse == null) || 
            (
                aquiferDetailsResponse?.aquifer_name == null && 
                aquiferDetailsResponse?.subtype == null && 
                aquiferDetailsResponse?.geom?.type == null && 
                aquiferDetailsResponse?.area == null
            )
        ){
            return false;
        }
        return true;
    }
}