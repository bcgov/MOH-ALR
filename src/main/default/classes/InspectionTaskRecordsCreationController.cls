/**
* @Name              : InspectionTaskRecordsCreationController
* @Description       : Controller class for Inspection Assessment Indicator Creation
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-1230
**/

public class InspectionTaskRecordsCreationController {
    public class FlowInputs {
        @InvocableVariable public List<String> ATIId;
        @InvocableVariable Public String InspId; 
    }
    @InvocableMethod
    public static void getActionPlanItemIds(List<FlowInputs> ATI ) {
        Set<String> APTIds = new Set<String>();
        Set<Id> InspectionId = new Set<Id>();
        for (FlowInputs input : ATI) {
            APTIds.addAll(input.ATIId);
            InspectionId.add(input.InspId);   
        }
        string VisitId = null; 
        for (string setElement :InspectionId ) {
                VisitId = setElement; 
         		break; 
        }
        Set<Id> LiteralValues = new Set<Id>();
       List<AssessmentTaskDefinition> ATD = new List<AssessmentTaskDefinition>();
       Set<Id>AIDIdIds = new Set<Id>();
       List<AssessmentTaskIndDefinition> ATID = new List<AssessmentTaskIndDefinition>();
       Set<Id> ATDIds = new Set<Id>();
       List<AssessmentIndicatorDefinition> AID = new List<AssessmentIndicatorDefinition>();
        List<Id> AssessIndDefList = new List<Id>();
       Id AIDIds;
        Set<Id>ATsIds = new Set<Id>();
        String categoryKey;
        Map<String, List<Id>> mapIds = new Map<String, List<Id>>();
        
        for(ActionPlanTemplateItemValue APTIV : [Select Id,ItemEntityFieldName,ValueLiteral,ActionPlanTemplateItemId
                                                From ActionPlanTemplateItemValue
                                                Where ActionPlanTemplateItemId IN :APTIds
                                                AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName]){
                                                  LiteralValues.add(APTIV.ValueLiteral);   
                                                 }
        If(LiteralValues.Size() !=0){
             ATD = [Select Id,Category__c From AssessmentTaskDefinition Where Id IN: LiteralValues];
            for(AssessmentTaskDefinition ATDs : ATD){
                ATDIds.add(ATDs.Id);
            }            
            List<AssessmentTask> ATstoInsert = new List<AssessmentTask>();
            for(AssessmentTaskDefinition ATDs :ATD){
                AssessmentTask  newAssessmentTask = new AssessmentTask();
                newAssessmentTask.Name = ATDs.Category__c;
                newAssessmentTask.AssessmentTaskDefinitionId = ATDs.Id;
                newAssessmentTask.ParentId = VisitId;
                newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
                ATstoInsert.add(newAssessmentTask);
            }
            database.insert(ATstoInsert);
            ATID = [Select AssessmentIndDefinitionId,AssessmentTaskDefinitionId 
                     From AssessmentTaskIndDefinition Where AssessmentTaskDefinitionId IN: ATDIds];
            System.debug('ATID'+ATID.size());
            Map<Id, List<Id>> mapAIDIds = new Map<Id, List<Id>>();
            for(AssessmentTaskIndDefinition atdid : ATID){
                if(!mapAIDIds.containsKey(atdid.AssessmentTaskDefinitionId)){
                    mapAIDIds.put(atdid.AssessmentTaskDefinitionId, new List<Id>());
                }
                mapAIDIds.get(atdid.AssessmentTaskDefinitionId).add(atdid.AssessmentIndDefinitionId);
            }            
            List<InspectionAssessmentInd> IAIstoInsert = new List<InspectionAssessmentInd>();
            for(AssessmentTask assessTask : ATstoInsert){
                if(mapAIDIds.containsKey(assessTask.AssessmentTaskDefinitionId)){
                    for(Id aidId : mapAIDIds.get(assessTask.AssessmentTaskDefinitionId)){
                        InspectionAssessmentInd newInspectionAssessmentInd = new InspectionAssessmentInd();
                        newInspectionAssessmentInd.AssessmentTaskId = assessTask.Id;
                        newInspectionAssessmentInd.AssessmentIndDefinitionId = aidId;
                        IAIstoInsert.add(newInspectionAssessmentInd);
                    }
                }
            } 
       Database.insert(IAIstoInsert);
    }
}
}