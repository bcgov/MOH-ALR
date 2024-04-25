/**
* @Name              : AccountTrigger
* @Description       : Trigger is calling helper class.
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-928
**/
trigger AccountTrigger on Account (after update) {
        if(Trigger.isAfter && Trigger.isUpdate){
            AccountHelper.createInspection(Trigger.New);
        }
    }