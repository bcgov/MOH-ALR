/**
* @Name              : Inspectiontrigger
* @Description       : trigger  for Regulatory Code Violation Records Creation
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-1291 & ALR-1173
**/
trigger Inspectiontrigger on Visit (after update) {
    List<Visit> completedVisits = New List<Visit>();
    if(Trigger.isAfter && Trigger.isUpdate){
    for(Visit insp : trigger.new){
        if(insp.status == 'Completed'&& Trigger.oldMap.get(insp.Id).Status != 'Completed'){         
             RCVCreationHelper.createRegulatoryCodeViolations(insp.Id);
        }
    }
    
}
}