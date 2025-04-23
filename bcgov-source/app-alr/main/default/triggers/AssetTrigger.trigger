/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:       
* @Description: The purpose of this Trigger is to trigger on particular events for Asset
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                            ALR-810             ACN-ALR        Business License Update to display both Organization (Registrant) and Account (Residence)
***********************************************************************************************/
trigger AssetTrigger on Asset (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    
   //ByPass Trigger through Custom setting
   // if(EnableDisableSetting__c.getInstance().DisabledAccountTrigger__c){
        //return;
    //}
   //  fflib_SObjectDomain.triggerHandler(Accounts.class);.
  // handler.AssetTriggerHandler();
  /*system.debug('99==');
    TriggerHandler handler = new AssetTriggerHandler();
     //TriggerHandler handler = new AccountTriggerHandler(Trigger.isExecuting, Trigger.size);
        switch on Trigger.operationType {
            when BEFORE_INSERT {
                 handler.beforeInsert(Trigger.new);
            } 
            when BEFORE_UPDATE {
                 handler.beforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
            when BEFORE_DELETE {
                 handler.beforeDelete(Trigger.old, Trigger.oldMap);
            }
            when AFTER_INSERT {
                 handler.afterInsert(Trigger.new, Trigger.newMap);
            }
            when AFTER_UPDATE {
                 handler.afterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
            }
            when AFTER_DELETE {
                 handler.afterDelete(Trigger.old, Trigger.oldMap);
            } 
            when AFTER_UNDELETE {
                 handler.afterUndelete(Trigger.new, Trigger.newMap);
            }
        }*/
}