/**
* @Name              : AccountTrigger
* @Description       : Trigger is calling helper class.
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-928
**/
trigger AccountTrigger on Account (after update, before insert, before update, after insert, before delete, after delete, after undelete) {
    if(Trigger.isAfter && Trigger.isUpdate){
        AccountHelper.createInspection(Trigger.New);
    }
}