/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:    
* @Description: The purpose of this Trigger is to trigger on particular events for Case
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
***********************************************************************************************/
trigger ComplaintCaseTrigger on Case (before insert) {
    ALR_Trigger_Setting__mdt triggerSettingObj = ALR_Trigger_Setting__mdt.getInstance('AccountTrigger');
    if (Trigger.isBefore && Trigger.isInsert && triggerSettingObj.Is_Run_on_Before_Insert__c) {
        ComplaintCaseTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}