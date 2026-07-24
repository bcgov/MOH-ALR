/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 May 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                28 May -  EHIS-2668         -  Accenture   -  Close subsequent child records.
***********************************************************************************************/
trigger RegulatoryCodeViolationTrigger on RegulatoryCodeViolation (after update, after insert, before insert) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        RegulatoryCodeViolationHandler.syncChildViolationStatus(Trigger.new, Trigger.oldMap);
      
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        RegulatoryCodeViolationHandler.updateRecurrenceCount(Trigger.new);
    }
    if(Trigger.isBefore && (Trigger.isInsert)){
        PhocsHealthAuthorityHandler.populateHealthAuthority(Trigger.new, 'PHOCSParentAccountID__c');         
    }
}