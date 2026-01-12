/**********************************************************************************************
* @Author:Accenture_PHOCS    
* @Date:      
* @Description: The purpose of this Class is to trigger Geocoder integration for PHOCS Accounts
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           EHIS-718               Vasanthi    Initial Version
***********************************************************************************************/
public class AccountTriggerHandler {
     private static Boolean skipGeocode = false;

    public static void setSkipGeocode(Boolean value) {
        skipGeocode = value;
    }

    public static void handleAfterUpdate(List<Account> newList, Map<Id, Account> oldMap) {
		if (skipGeocode) {
            return;
        }
        executeGeocoder(newList,oldMap);
    }
    public static void handleAfterInsert(List<Account> newList) {
    if (skipGeocode) {
        return;
    }
     executeGeocoder(newList, null);
  }
  
    
   private static void executeGeocoder(List<Account> accounts, Map<Id, Account> oldMap) {
    List<Id> accountsToGeocode = new List<Id>();

    for (Account acct : accounts) {
        if (acct.RecordTypeName__c != 'DrinkingWaterSourceIntake' &&
            acct.RecordTypeName__c != 'DrinkingWaterSystem' &&
            acct.RecordTypeName__c != 'Facility' && 
           	acct.RecordTypeName__c != 'PHOCSDairyFacility') {
            continue;
        }

        Boolean invokeGeocode = false;

        if (oldMap == null) {
            invokeGeocode =
                String.isNotBlank(acct.Physical_Address__Street__s) ||
                String.isNotBlank(acct.Physical_Address__City__s) ||
                String.isNotBlank(acct.Physical_Address__StateCode__s);
        } else {
            Account oldAcct = oldMap.get(acct.Id);
            invokeGeocode =
                acct.Physical_Address__Street__s != oldAcct.Physical_Address__Street__s ||
                acct.Physical_Address__City__s != oldAcct.Physical_Address__City__s ||
                acct.Physical_Address__StateCode__s != oldAcct.Physical_Address__StateCode__s;
        }

        if (invokeGeocode) {
            accountsToGeocode.add(acct.Id);
        }
    }

          if (!accountsToGeocode.isEmpty()) {
            System.enqueueJob(new GeocodeAddressQueueable(new List<Id>(accountsToGeocode)));
        }


   }
    
/**
* =================================================================================================
*  Object           : Account
*  Events           : After Insert, After Update
*
*  Developer      : Pawan Atri
*  Title          : Retrieve water license information from the Water Rights Database (WLRS)
*  User Story     : EHIS-1425
*  Created Date   : 16-Sept-2025
*
*  Summary:
*  This trigger is responsible for initiating an automated background process that retrieves
*  water-related regulatory information for an Account. Whenever an Account record is created
*  or updated, the trigger checks if either of the following fields have changed:
*
*      • WaterLicenseNumber__c
*      • WaterLicenseApplicationNumber__c
*
*  If a change is detected, the trigger enqueues a Queueable Apex class
*  (PHOCSWaterSystemQueueable) that performs external callouts to retrieve:
*
*      1. Well Tag details
*      2. Aquifer details
*      3. Water application details (if license not available)
*
*  Note:
*  The actual data retrieval logic is handled inside PHOCSWaterSystemQueueable class.
*  This trigger only detects changes and delegates processing.
*
* =================================================================================================
*/
    public static void phocsWaterRights(List<Account> accounts, Map<Id, Account> oldMap){
        List<Id> accIds = new List<Id>();
        
        String AccRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSourceIntake').getRecordTypeId();
        
        for(Account acc : accounts){
            Boolean isCorrectRecordtype = (acc.RecordtypeId == AccRecordTypeID);
            if(!isCorrectRecordtype){
                continue;
            }
            
            // Only trigger if WaterLicenseNumber__c OR WaterLicenseApplicationNumber__c changed
            Account oldAcc = oldMap != null ? oldMap.get(acc.Id) : null;
            
            Boolean isCorrectType = (acc.Type == 'Drinking Water');
            Boolean islicenseChanged = (oldAcc == null || acc.WaterLicenseNumber__c != oldAcc.WaterLicenseNumber__c);
            Boolean isappNumbChanged = (oldAcc == null || acc.WaterLicenseApplicationNumber__c != oldAcc.WaterLicenseApplicationNumber__c);
            Boolean isPODNumberChanged = (oldAcc == null || acc.PODNumber__c != oldAcc.PODNumber__c);
            Boolean isPurposeCodeChanged = (oldAcc == null || acc.PurposeUseCode__c != oldAcc.PurposeUseCode__c);
            Boolean isWellTagChanged = (oldAcc == null || acc.WellTagNumber__c != oldAcc.WellTagNumber__c);
            Boolean isAquiferChanged = (oldAcc == null || acc.AquiferNumber__c != oldAcc.AquiferNumber__c);
            
            if((islicenseChanged || isappNumbChanged || isPODNumberChanged || isPurposeCodeChanged || isWellTagChanged || isAquiferChanged) && (isCorrectRecordtype && isCorrectType)){
                accIds.add(acc.Id);
            }
        }
        
        if(!accIds.isEmpty() && !Test.isRunningTest()){
            System.enqueueJob(new PHOCSWaterSystemQueueable(accIds));
        } 
    }

}