/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:    
* @Description: The purpose of this Trigger is to trigger on particular events for RegulatoryTrxnFee
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
***********************************************************************************************/
trigger RegulatoryTrxnFeeTrigger on RegulatoryTrxnFee (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
     TriggerHandler handler = new RegulatoryTrxnFeeTriggerHandler();
     ALR_Trigger_Setting__mdt triggerSettingObj = ALR_Trigger_Setting__mdt.getInstance('AccountTrigger');
     switch on Trigger.operationType {
         when BEFORE_INSERT {
             if(triggerSettingObj.Is_Run_on_Before_Insert__c){
                 handler.beforeInsert(Trigger.new);
             }
         } 
         when BEFORE_UPDATE {
             if(triggerSettingObj.Is_Run_on_Before_Update__c){
                 handler.beforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
             }
         }
         when BEFORE_DELETE {
             if(triggerSettingObj.Is_Run_on_Before_Delete__c){
                 handler.beforeDelete(Trigger.old, Trigger.oldMap);
             }
         }
         when AFTER_INSERT {
             if(triggerSettingObj.Is_Run_on_After_Insert__c){
                 handler.afterInsert(Trigger.new, Trigger.newMap);
             }
         }
         when AFTER_UPDATE {
             if(triggerSettingObj.Is_Run_on_After_Update__c){
                 handler.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
             }
         }
         when AFTER_DELETE {
             if(triggerSettingObj.Is_Run_on_After_Delete__c){
                 handler.afterDelete(Trigger.old, Trigger.oldMap);
             }
         } 
         when AFTER_UNDELETE {
             if(triggerSettingObj.Is_Run_on_After_UnDelete__c){
                 handler.afterUndelete(Trigger.new, Trigger.newMap);
             }
         }
     }
 }