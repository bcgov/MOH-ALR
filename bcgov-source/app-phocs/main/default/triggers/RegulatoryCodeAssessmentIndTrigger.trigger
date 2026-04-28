/**********************************************************************************************
* @Author:      Accenture 
* @Date:        18 Feb 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                18 Feb -  PHOCS-3397         -  Accenture   -  Update RelatedRegulatoryCodes__c on InspectionAssessmentInd records.
***********************************************************************************************/
trigger RegulatoryCodeAssessmentIndTrigger on RegulatoryCodeAssessmentInd (after insert, after delete) {

    if(Trigger.isAfter){
        if (Trigger.isInsert) {
            RegCodeAssessmentIndTriggerHandler.updateRelatedRegulatoryCodes(Trigger.new, null);
        }
        
        if(Trigger.isDelete){
            RegCodeAssessmentIndTriggerHandler.updateRelatedRegulatoryCodes(null, Trigger.old);
        }
    }
}