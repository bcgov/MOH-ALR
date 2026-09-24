/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
                15 Sep -  EHIS-5712         -  Deepak      -  added after update, calling updateDairyRequisitionFlag on insert and update
***********************************************************************************************/
trigger LabTestRequisitionTrigger on LabTestRequisition__c (before insert, after insert, after update) {
    if (Trigger.isBefore) {
        LabTestRequisitionTriggerHandler.assignWaterRequisitionsToHealthAuthorityQueue(Trigger.new);
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LabTestRequisitionTriggerHandler.populateLabTestRequisitionNumber(Trigger.new);
            //LabTestRequisitionTriggerHandler.shareQueueOwnedRequisitionsWithCreator(Trigger.new);
        }
        LabTestRequisitionTriggerHandler.updateDairyRequisitionFlag(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
    }
}