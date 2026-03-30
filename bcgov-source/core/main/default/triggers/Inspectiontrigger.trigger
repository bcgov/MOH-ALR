/**
* @Name              : Inspectiontrigger
* @Description       : trigger  for Regulatory Code Violation Records Creation
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-1291 & ALR-1173
**/
trigger Inspectiontrigger on Visit (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        VisitTriggerHandler.afterUpdate(Trigger.New, Trigger.OldMap);
    }
}