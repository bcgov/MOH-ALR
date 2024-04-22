/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:    
* @Description: The purpose of this Trigger is to trigger on particular events for Case
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
***********************************************************************************************/
trigger ComplaintCaseTrigger on Case (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        ComplaintCaseTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}