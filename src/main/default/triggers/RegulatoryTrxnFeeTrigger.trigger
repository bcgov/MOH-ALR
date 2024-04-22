/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:    
* @Description: The purpose of this Trigger is to trigger on particular events for RegulatoryTrxnFee
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
***********************************************************************************************/
trigger RegulatoryTrxnFeeTrigger on RegulatoryTrxnFee (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    TriggerHandler handler = new RegulatoryTrxnFeeTriggerHandler();
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
        }

}