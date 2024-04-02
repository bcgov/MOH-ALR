/**
* @Name              : AccountTrigger
* @Description       : Trigger is calling helper class.
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-928
**/
trigger AccountTrigger on Account (after update, before insert, before update, after insert, before delete, after delete, after undelete) {
    switch on Trigger.operationType {
        when AFTER_UPDATE {
                 AccountHelper.createInspection(Trigger.New);
            }
    }
    }