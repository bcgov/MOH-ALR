/**********************************************************************************************
* @Author:      Accenture 
* @Date:        22 May 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                22 May -  EHIS-3688         -  Accenture   -  Prevents duplicate records records.
***********************************************************************************************/
trigger EnforcementActionViolationTrigger on EnforcementActionViolation__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        EnforcementActionViolationHandler.validateDuplicateRecords(Trigger.new, null);
    }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
        EnforcementActionViolationHandler.validateDuplicateRecords(Trigger.new, Trigger.oldMap);
    }
}