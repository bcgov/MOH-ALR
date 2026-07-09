/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
***********************************************************************************************/
trigger LabTestRequisitionTrigger on LabTestRequisition__c (after insert) {
    LabTestRequisitionTriggerHandler.populateLabTestRequisitionNumber(Trigger.new);
}