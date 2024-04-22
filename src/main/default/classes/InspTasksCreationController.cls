/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Controller class for Inspection Assessment Indicator Creation
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                           ALR-1230             Anilkumar
***********************************************************************************************/
public with sharing class InspTasksCreationController {
    public static String className = 'InspTasksCreationController';
    public class FlowInputs {
        @InvocableVariable public List<String> ATIId;
        @InvocableVariable public String InspId; 
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @InvocableMethod
    public static void getActionPlanItemIds(List<FlowInputs> ATI ) {
        Set<String> APTIds = new Set<String>();
        Set<Id> InspectionId = new Set<Id>();
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
        Map<Id, List<Id>> mapAIDIds = new Map<Id, List<Id>>();
        List<AssessmentTask> ATstoInsert = new List<AssessmentTask>();
        List<InspectionAssessmentInd> IAIstoInsert = new List<InspectionAssessmentInd>();
        string visitId = null; 
        try{
            for (FlowInputs input : ATI) {
                APTIds.addAll(input.ATIId);
                InspectionId.add(input.InspId);   
            }
            
            for (string setElement :InspectionId ) {
                visitId = setElement; 
                break; 
            }
            for(ActionPlanTemplateItemValue APTIV : [SELECT Id,ItemEntityFieldName,ValueLiteral,ActionPlanTemplateItemId
                                                     FROM ActionPlanTemplateItemValue
                                                     WHERE ActionPlanTemplateItemId IN :APTIds
                                                     AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName WITH SECURITY_ENFORCED]){
                                                         LiteralValues.add(APTIV.ValueLiteral);   
                                                     }
            if(LiteralValues.Size() !=0){
                ATD = [SELECT Id,Category__c FROM AssessmentTaskDefinition WHERE Id IN: LiteralValues WITH SECURITY_ENFORCED];
                for(AssessmentTaskDefinition ATDs : ATD){
                    ATDIds.add(ATDs.Id);
                }            
                
                for(AssessmentTaskDefinition ATDs :ATD){
                    AssessmentTask  newAssessmentTask = new AssessmentTask();
                    newAssessmentTask.Name = ATDs.Category__c;
                    newAssessmentTask.AssessmentTaskDefinitionId = ATDs.Id;
                    newAssessmentTask.ParentId = visitId;
                    newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
                    ATstoInsert.add(newAssessmentTask);
                }
                if(!ATstoInsert.isEmpty()){
                    database.insert(ATstoInsert);
                }
                ATID = [SELECT AssessmentIndDefinitionId,AssessmentTaskDefinitionId 
                        FROM AssessmentTaskIndDefinition WHERE AssessmentTaskDefinitionId IN: ATDIds WITH SECURITY_ENFORCED];
                
                for(AssessmentTaskIndDefinition atdid : ATID){
                    if(!mapAIDIds.containsKey(atdid.AssessmentTaskDefinitionId)){
                        mapAIDIds.put(atdid.AssessmentTaskDefinitionId, new List<Id>());
                    }
                    mapAIDIds.get(atdid.AssessmentTaskDefinitionId).add(atdid.AssessmentIndDefinitionId);
                }            
                
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
                if(!IAIstoInsert.isEmpty()){
                    Database.insert(IAIstoInsert);
                }
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'getActionPlanItemIds', '', ex);
        }
    }
}