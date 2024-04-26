/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Controller class for Inspection Assessment Indicator Creation
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                           ALR-1230             Anilkumar     Error while creating the inspection
***********************************************************************************************/
public with sharing class InspTasksCreationController {
    public static String className = 'InspTasksCreationController';
    public class FlowInputs {
        @InvocableVariable public List<String> aTIId;
        @InvocableVariable public String inspId; 
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @InvocableMethod
    public static void getActionPlanItemIds(List<FlowInputs> ATI ) {
        Set<String> aPTIds = new Set<String>();
        Set<Id> inspectionId = new Set<Id>();
        Set<Id> literalValues = new Set<Id>();
        List<AssessmentTaskDefinition> aTD = new List<AssessmentTaskDefinition>();
        List<AssessmentTaskIndDefinition> aTID = new List<AssessmentTaskIndDefinition>();
        Set<Id> aTDIds = new Set<Id>();
        List<AssessmentIndicatorDefinition> aID = new List<AssessmentIndicatorDefinition>();
        Id aIDIds;
        Map<Id, List<Id>> mapAIDIds = new Map<Id, List<Id>>();
        List<AssessmentTask> aTstoInsert = new List<AssessmentTask>();
        List<InspectionAssessmentInd> iAIstoInsert = new List<InspectionAssessmentInd>();
        string visitId = null; 
        try{
            for (FlowInputs input : ATI) {
                aPTIds.addAll(input.aTIId);
                inspectionId.add(input.inspId);   
            }
            for (string setElement :inspectionId ) {
                visitId = setElement; 
                break; 
            }
            for(ActionPlanTemplateItemValue APTIV : [SELECT Id,ItemEntityFieldName,ValueLiteral,ActionPlanTemplateItemId
                                                     FROM ActionPlanTemplateItemValue
                                                     WHERE ActionPlanTemplateItemId IN :aPTIds
                                                     AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName WITH SECURITY_ENFORCED]){
                                                         literalValues.add(APTIV.ValueLiteral);   
                                                     }
            if(literalValues.Size() !=0){
                aTD = [SELECT Id,Category__c FROM AssessmentTaskDefinition WHERE Id IN: literalValues WITH SECURITY_ENFORCED];
                for(AssessmentTaskDefinition ATDs : aTD){
                    aTDIds.add(ATDs.Id);
                }            
                
                for(AssessmentTaskDefinition ATDs :aTD){
                    AssessmentTask  newAssessmentTask = new AssessmentTask();
                    newAssessmentTask.Name = ATDs.Category__c;
                    newAssessmentTask.AssessmentTaskDefinitionId = ATDs.Id;
                    newAssessmentTask.ParentId = visitId;
                    newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
                    aTstoInsert.add(newAssessmentTask);
                }
                if(!aTstoInsert.isEmpty()){
                    database.insert(aTstoInsert);
                }
                aTID = [SELECT AssessmentIndDefinitionId,AssessmentTaskDefinitionId 
                        FROM AssessmentTaskIndDefinition WHERE AssessmentTaskDefinitionId IN: aTDIds WITH SECURITY_ENFORCED];
                
                for(AssessmentTaskIndDefinition atdid : aTID){
                    if(!mapAIDIds.containsKey(atdid.AssessmentTaskDefinitionId)){
                        mapAIDIds.put(atdid.AssessmentTaskDefinitionId, new List<Id>());
                    }
                    mapAIDIds.get(atdid.AssessmentTaskDefinitionId).add(atdid.AssessmentIndDefinitionId);
                }            
                
                for(AssessmentTask assessTask : aTstoInsert){
                    if(mapAIDIds.containsKey(assessTask.AssessmentTaskDefinitionId)){
                        for(Id aidId : mapAIDIds.get(assessTask.AssessmentTaskDefinitionId)){
                            InspectionAssessmentInd newInspectionAssessmentInd = new InspectionAssessmentInd();
                            newInspectionAssessmentInd.AssessmentTaskId = assessTask.Id;
                            newInspectionAssessmentInd.AssessmentIndDefinitionId = aidId;
                            iAIstoInsert.add(newInspectionAssessmentInd);
                        }
                    }
                } 
                if(!iAIstoInsert.isEmpty()){
                    Database.insert(iAIstoInsert);
                }
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'getActionPlanItemIds', '', ex);
        }
    }
}