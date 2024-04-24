/**
* @Name              : AccountTrigger
* @Description       : Trigger is calling helper class.
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-928
**/
trigger AccountTrigger on Account (after update, before insert, before update, after insert, before delete, after delete, after undelete) {
    for(Account acc : Trigger.New){
        if(Trigger.isAfter && Trigger.isUpdate){
            if(acc.Rating != NULL){
            AccountHelper.createInspection(Trigger.New);
        }
        }
    }
    }