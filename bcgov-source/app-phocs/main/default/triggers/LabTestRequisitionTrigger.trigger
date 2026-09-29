/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
                15 Sep -  EHIS-5712         -  Deepak      -  added after update, calling updateDairyRequisitionFlag on insert and update
                28 Sep -  Orphan Lab Requisitions - Accenture - Restrict orphan edits, assign Health Authority/queue on Facility assignment, cascade Facility to Lab Test Required.
***********************************************************************************************/
trigger LabTestRequisitionTrigger on LabTestRequisition__c (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            LabTestRequisitionTriggerHandler.assignWaterRequisitionsToHealthAuthorityQueue(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LabTestRequisitionTriggerHandler.restrictOrphanFieldEdits(Trigger.new, Trigger.oldMap);
            LabTestRequisitionTriggerHandler.assignOrphanRequisitionsToFacility(Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            LabTestRequisitionTriggerHandler.populateLabTestRequisitionNumber(Trigger.new);
            //LabTestRequisitionTriggerHandler.shareQueueOwnedRequisitionsWithCreator(Trigger.new);
        }
        if (Trigger.isUpdate) {
            LabTestRequisitionTriggerHandler.cascadeFacilityToLabTestsRequired(Trigger.new, Trigger.oldMap);
        }
        LabTestRequisitionTriggerHandler.updateDairyRequisitionFlag(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
    }
}