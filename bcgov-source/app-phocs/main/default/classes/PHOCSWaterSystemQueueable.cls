/**
 * -----------------------------------------------------------------------------------------
 * Class Name      : PHOCSWaterSystemQueueable
 * Developer       : Pawan Atri
 * Title           : Retrieve water license information from the Water Rights Database (WLRS) 
 * User Story      : EHIS-1425
 * Created Date    : 16-Sept-2025
 * -----------------------------------------------------------------------------------------
 * DESCRIPTION
 * This Queueable Apex class performs a sequence of external API callouts to populate
 * water system details on Account records. It runs asynchronously and supports bulk
 * operations.
 *
 * BUSINESS FLOW:
 * 1. Receives a list of Account Ids from Trigger or Apex.
 * 2. For each Account:
 *       If Water License Number exists:
 *             - Calls Water License API
 *             - Extracts Well Tag number from the License response
 *       If License is empty OR License did not return WellTag:
 *             - Calls Water Application API
 *             - Extracts Well Tag number from the Application response
 *       Using the Well Tag number:
 *             - Calls Well Tag API to retrieve Aquifer number
 *       Using the Aquifer number:
 *             - Calls Aquifer API to retrieve final Aquifer details
 *
 * 3. Updates Account fields:
 *      - WellTagNumber__c
 *      - AquiferNumber__c
 *
 * 4. Caching Logic (based on Custom Label: PHOCSWaterRightsCache):
 *      - If caching enabled, full JSON API responses are stored into:
 *            * PHOCSWaterLicenseJSONRespnose__c
 *            * PHOCSWaterApplicationJSONResponse__c
 *            * PHOCSWellTagJSONResponse__c
 *            * PHOCSAquiferJSONResponse__c
 *
 * PURPOSE:
 * - Automates fetching of Water Rights metadata
 * - Ensures Accounts store correct WellTag & Aquifer information
 * - Reduces manual data entry and increases data accuracy
 * - Supports re-try logic through async Queueable execution
 *
 * NOTES:
 * - Implements Database.AllowsCallouts because multiple external callouts occur
 * - Bulkified for multiple records
 * - Runs asynchronously to avoid timeouts & improve performance
 *
 * -----------------------------------------------------------------------------------------
 */

public class PHOCSWaterSystemQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Id> recordIds;
    
    public PHOCSWaterSystemQueueable(List<Id> recordIds){
        this.recordIds = recordIds;
    }
    
    public void execute(QueueableContext context){
        Map<String, Object> waterLicenseMappingData;
        Map<String, Object> waterLicenseApplicationMappingData;
        Map<String, Object> wellTagMappingData;
        Map<String, Object> aquiferMappingData;
        String isCacheEnabled = System.Label.PHOCSWaterRightsCache;
        
        List<Account> accountsToUpdate = [SELECT Id,
                                          WaterLicenseNumber__c,
                                          WaterLicenseApplicationNumber__c,
                                          WellTagNumber__c,
                                          AquiferNumber__c,
                                          PODNumber__c,
                                          PurposeUseCode__c,
                                          PHOCSWaterLicenseJSONRespnose__c,
                                          PHOCSWaterApplicationJSONResponse__c,
                                          PHOCSWellTagJSONResponse__c,
                                          PHOCSAquiferJSONResponse__c 
                                          FROM Account
                                          WHERE Id IN :recordIds];
        
        for(Account acc : accountsToUpdate){
            
            String license = acc.WaterLicenseNumber__c;
            String application = acc.WaterLicenseApplicationNumber__c;
            String podNumber = acc.PODNumber__c;
            String purposeCode = acc.PurposeUseCode__c;
            String wellTag;
            String aquifer;
            
            // STEP 1: If License exists → call License API
            PHOCSWaterLicenseService waterLicService = new PHOCSWaterLicenseService();
            
            if(String.isNotBlank(license)){
                waterLicService.setCalloutType('license');
                waterLicenseMappingData = waterLicService.mappingData(license);
            }else if(String.isNotBlank(podNumber)){
                waterLicService.setCalloutType('podNumber');
                waterLicenseMappingData = waterLicService.mappingData(podNumber);
            }else{
                waterLicService.setCalloutType('purposeCode');
                waterLicenseMappingData = waterLicService.mappingData(purposeCode);
            }
            
            if(waterLicenseMappingData.containsKey('License_WellTagNumber')){
                wellTag = waterLicenseMappingData.get('License_WellTagNumber')?.toString();
            }
            
            // STEP 2: If License NOT given → get WellTag from Application
            PHOCSWaterApplicationService applicationService = new PHOCSWaterApplicationService();
            waterLicenseApplicationMappingData = applicationService.mappingData(application);
            if(String.isBlank(wellTag) && waterLicenseApplicationMappingData.containsKey('Application_WellTagNumber')){
                wellTag = waterLicenseApplicationMappingData.get('Application_WellTagNumber')?.toString();
            }
            
            // STEP 3: Get Aquifer from Well Tag
            PHOCSWellsService wellService = new PHOCSWellsService();
            wellTagMappingData = wellService.mappingData(wellTag);
            if(wellTagMappingData.containsKey('WellTag_AquiferNumber')){
                aquifer = wellTagMappingData.get('WellTag_AquiferNumber')?.toString();
            }
            
            // STEP 4: Get Aquifer details
            PHOCSAquiferService aquiferService = new PHOCSAquiferService();
            aquiferMappingData = aquiferService.mappingData(aquifer);
            
            // STEP 5: Update fields
            acc.WellTagNumber__c = wellTag != null ? Decimal.ValueOf(wellTag) : null;
            acc.AquiferNumber__c = aquifer != null ? Decimal.ValueOf(aquifer) : null;
            if(isCacheEnabled.equalsIgnoreCase('true') || Test.isRunningTest()){
                acc.PHOCSWaterLicenseJSONRespnose__c = JSON.serialize(waterLicenseMappingData);
                acc.PHOCSWaterApplicationJSONResponse__c = JSON.serialize(waterLicenseApplicationMappingData);
                acc.PHOCSWellTagJSONResponse__c = JSON.serialize(wellTagMappingData);
                acc.PHOCSAquiferJSONResponse__c = JSON.serialize(aquiferMappingData);
            }
        }
        
        update accountsToUpdate;
    }
}