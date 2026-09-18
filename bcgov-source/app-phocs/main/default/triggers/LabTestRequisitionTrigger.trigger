/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
***********************************************************************************************/
trigger LabTestRequisitionTrigger on LabTestRequisition__c (before insert, after insert) {
    if (Trigger.isBefore) {
        LabTestRequisitionTriggerHandler.assignWaterRequisitionsToHealthAuthorityQueue(Trigger.new);
    }
    if (Trigger.isAfter) {
        LabTestRequisitionTriggerHandler.populateLabTestRequisitionNumber(Trigger.new);
        LabTestRequisitionTriggerHandler.shareQueueOwnedRequisitionsWithCreator(Trigger.new);
    }
}
