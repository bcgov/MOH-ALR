/**********************************************************************************************
* @Author:Accenture_ALR Team   
* @Date:      
* @Description: The purpose of this Trigger is to trigger on particular events for Account
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR-928               Komal        Compliance inspection scheduling based on compliance score
***********************************************************************************************/
trigger AccountTrigger on Account (after update,after insert) {
    
        if(Trigger.isAfter && Trigger.isUpdate){
           
            List<Account> acclist = trigger.new;
            system.debug('test'+acclist.size());
            AccountHelper.createInspection(Trigger.New);
        }
       if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
       }
      if(Trigger.isAfter && Trigger.isInsert){
        AccountTriggerHandler.handleAfterInsert(Trigger.new);
       }
    
    }