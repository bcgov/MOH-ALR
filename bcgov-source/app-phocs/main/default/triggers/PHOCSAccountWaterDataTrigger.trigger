/**
* =================================================================================================
*  Trigger Name     : PHOCSAccountWaterDataTrigger
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

trigger PHOCSAccountWaterDataTrigger on Account (after insert, after update) {
    List<Id> accIds = new List<Id>();
    
    for(Account acc : Trigger.new){
        // Only trigger if WaterLicenseNumber__c OR WaterLicenseApplicationNumber__c changed
        Account oldAcc = Trigger.isUpdate ? Trigger.oldMap.get(acc.Id) : null;
		
		String AccRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSourceIntake').getRecordTypeId();
        
        Boolean islicenseChanged = (oldAcc == null || acc.WaterLicenseNumber__c != oldAcc.WaterLicenseNumber__c);
        Boolean isappNumbChanged = (oldAcc == null || acc.WaterLicenseApplicationNumber__c != oldAcc.WaterLicenseApplicationNumber__c);
        Boolean isPODNumberChanged = (oldAcc == null || acc.PODNumber__c != oldAcc.PODNumber__c);
        Boolean isPurposeCodeChanged = (oldAcc == null || acc.PurposeUseCode__c != oldAcc.PurposeUseCode__c);
        Boolean isCorrectRecordtype = (acc.RecordtypeId == AccRecordTypeID);
        Boolean isCorrectType = (acc.Type == 'Drinking Water');
        
        if((islicenseChanged || isappNumbChanged || isPODNumberChanged || isPurposeCodeChanged) && (isCorrectRecordtype && isCorrectType)){
            accIds.add(acc.Id);
        }
    }
    
    if(!accIds.isEmpty() && !Test.isRunningTest()){
        System.enqueueJob(new PHOCSWaterSystemQueueable(accIds));
    } 
}