/**
* --------------------------------------------------------------------------------------------
*  Class Name     : PHOCSWaterRightsSystemService
*  Developer      : Pawan Atri
*  Title          : Retrieve water license information from the Water Rights Database (WLRS)
*  User Story     : EHIS-1425
*  Created Date   : 16-Sept-2025
*
*  Description:
*  This class acts as a centralized Callable Apex service used to fetch and merge
*  Water Rights related data including:
*      # Water License
*      # Water Application
*      # Well Tag
*      # Aquifer
*
*  How it works:
*  • Triggered via Flexcard: PHOCSWaterRightsSystem
*  • Receives "input", "output", and "options" via the "call()" method as per Callable interface
*  • Executes method "getAllData" which:
*       1. Reads recordId from input
*       2. Queries Account fields holding license, application, welltag, aquifer
*       3. Determines if caching is enabled via Custom Label: PHOCSWaterRightsCache
*
*   If Cache = TRUE:
*       - Reads previously stored JSON responses from Account fields
*       - Pushes all values into the output map without doing any new callouts
*
*   If Cache = FALSE:
*       - Makes real-time callouts to:
*           a) PHOCSWaterLicenseService      (License → License Details)
*           b) PHOCSWaterApplicationService  (Application → Application Details)
*           c) PHOCSWellsService             (WellTag → Well Details)
*           d) PHOCSAquiferService           (Aquifer → Aquifer Details)
*       - Merges all returned JSON into output map
*
*  Purpose / Business Use:
*      • Used by PHOCS (Public Health Operating Compliance System) to auto-fill water rights
*        information on Account record pages.
*      • Data is consumed by Omnistudio FlexCards, OmniScripts, and Salesforce UI components.
*
*  Important Notes:
*      • Supports multi-step API dependency order (License → WellTag → Aquifer)
*      • Avoids repeated expensive API calls when cache is enabled
*      • All service response data is stored in output map for downstream usage
*      • Designed to be extendable for additional water-related services
* --------------------------------------------------------------------------------------------
*/

global with sharing class PHOCSWaterRightsSystemService implements Callable {
    
    global Object call(String action, Map<String, Object> args) {
        Map<String, Object> input   = (Map<String, Object>) args.get('input');
        Map<String, Object> output  = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }
    
    private Object invokeMethod(String methodName, Map<String, Object> inputMap, Map<String, Object> outMap, Map<String, Object> options) {
        Map<String, Object> waterLicenseMappingData;
        Map<String, Object> waterLicenseApplicationMappingData;
        Map<String, Object> wellTagMappingData;
        Map<String, Object> aquiferMappingData;
        String isCacheEnabled = System.Label.PHOCSWaterRightsCache;
        
        if (methodName == 'getAllData') {
            String recordId = String.valueOf(inputMap.get('recordId'));
            List<Account> accounts = [SELECT Id,
                                      WaterLicenseNumber__c,
                                      WaterLicenseApplicationNumber__c,
                                      WellTagNumber__c,
                                      AquiferNumber__c,
                                      PHOCSWaterLicenseJSONRespnose__c,
                                      PHOCSWaterApplicationJSONResponse__c,
                                      PHOCSWellTagJSONResponse__c,
                                      PHOCSAquiferJSONResponse__c 
                                      FROM Account
                                      WHERE Id = :recordId];
            for(Account acc : accounts){
                String license = acc?.WaterLicenseNumber__c;
                String application = acc?.WaterLicenseApplicationNumber__c;
                String wellTag = acc.WellTagNumber__c?.toString();
                String aquifer = acc.AquiferNumber__c?.toString();
                
                if(isCacheEnabled.equalsIgnoreCase('true')){
                    
                    // Fetch Water license existing JSON Response, if it is blank then pass Error in Map
                    if(String.isNotBlank(acc.PHOCSWaterLicenseJSONRespnose__c))
                        outMap.putAll((Map<String, Object>) JSON.deserializeUntyped(acc.PHOCSWaterLicenseJSONRespnose__c));
                    else
                        outMap.put(PHOCSWaterLicenseService.errorKey, PHOCSWaterLicenseService.errorMsg);
                    
                    // Fetch Water license application existing JSON Response, if it is blank then pass Error in Map
                    if(String.isNotBlank(acc.PHOCSWaterApplicationJSONResponse__c))
                        outMap.putAll((Map<String, Object>) JSON.deserializeUntyped(acc.PHOCSWaterApplicationJSONResponse__c));
                    else
                        outMap.put(PHOCSWaterApplicationService.errorKey, PHOCSWaterApplicationService.errorMsg);
                    
                    // Fetch Well-Tag existing JSON Response, if it is blank then pass Error in Map
                    if(String.isNotBlank(acc.PHOCSWellTagJSONResponse__c))
                        outMap.putAll((Map<String, Object>) JSON.deserializeUntyped(acc.PHOCSWellTagJSONResponse__c));
                    else
                        outMap.put(PHOCSWellsService.errorKey, PHOCSWellsService.errorMsg);
                    
                    // Fetch Aquifer existing JSON Response, if it is blank then pass Error in Map
                    if(String.isNotBlank(acc.PHOCSAquiferJSONResponse__c))
                        outMap.putAll((Map<String, Object>) JSON.deserializeUntyped(acc.PHOCSAquiferJSONResponse__c));
                    else
                        outMap.put(PHOCSAquiferService.errorKey, PHOCSAquiferService.errorMsg);
                    
                }else{
                    // STEP 1: If License exists → call License API
                    PHOCSWaterLicenseService waterLicService = new PHOCSWaterLicenseService();
                    waterLicenseMappingData = waterLicService.mappingData(license);
                    
                    // STEP 2: If License NOT given → get WellTag from Application
                    PHOCSWaterApplicationService applicationService = new PHOCSWaterApplicationService();
                    waterLicenseApplicationMappingData = applicationService.mappingData(application);
                    
                    // STEP 3: Get Aquifer from Well Tag
                    PHOCSWellsService wellService = new PHOCSWellsService();
                    wellTagMappingData = wellService.mappingData(wellTag);
                    
                    // STEP 4: Get Aquifer details
                    PHOCSAquiferService aquiferService = new PHOCSAquiferService();
                    aquiferMappingData = aquiferService.mappingData(aquifer);
                    
                    // STEP 5: Put all responses in outMap
                    outMap.putAll(waterLicenseMappingData);
                    outMap.putAll(waterLicenseApplicationMappingData);
                    outMap.putAll(wellTagMappingData);
                    outMap.putAll(aquiferMappingData);
                }
            }
        }        
        return outMap;
    }
}