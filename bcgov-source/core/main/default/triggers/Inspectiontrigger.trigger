/**
* @Name              : Inspectiontrigger
* @Description       : trigger  for Regulatory Code Violation Records Creation
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-1291 & ALR-1173
* Revision			 : EHIS-3081 - Rahul
**/
trigger Inspectiontrigger on Visit (after update, before insert, before update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        VisitTriggerHandler.afterUpdate(Trigger.New, Trigger.OldMap);
    }
	 if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
           PhocsHealthAuthorityHandler.populateHealthAuthority(Trigger.new, 'AccountId');         
        }
}