/**********************************************************************************************
* @Author:      Accenture 
* @Date:        11 Dec 2025
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                11 Dec -  PHOCS-2693         -  Accenture   -  Create Violations for PHOCS InspectionAssessmentInd records.
***********************************************************************************************/
trigger InspectionAssessmentIndTrigger on InspectionAssessmentInd (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        InspAssessmentIndTriggerHandler.afterInsert(Trigger.new);
    }
}