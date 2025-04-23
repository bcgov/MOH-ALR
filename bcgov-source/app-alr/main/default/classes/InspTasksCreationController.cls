/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Controller class for Inspection Assessment Indicator Creation
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                           ALR-1230             Anilkumar     Error while creating the inspection
                           EHIS-1363            Vasanthi      Updated class to handle phocs inspection creation logic
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
* @description: The purpose of this method is for InspTasksCreationController
* @return:  void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @InvocableMethod
    public static void getActionPlanItemIds(List<FlowInputs> ATI ) {
        Set<String> aPTIds = new Set<String>();
        Set<Id> inspectionIds = new Set<Id>();
        Set<String> literalValues = new Set<String>();
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
                inspectionIds.add(input.inspId);   
            }
            for (string setElement :inspectionIds ) {
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
                aTD = [SELECT Id,Name,Category__c FROM AssessmentTaskDefinition 
                        WHERE Name IN: literalValues WITH SECURITY_ENFORCED order by Name];
                for(AssessmentTaskDefinition ATDs : aTD){
                    aTDIds.add(ATDs.Id);
                }            
                
                Id assesmentTaskRecordTypeId;
                Visit visit = [select Id, Account.RecordType.Name From Visit where Id=:visitId Limit 1];
                if(visit?.AccountId != null){
                   AssesmentTaskRecrdTypeMapping__mdt recordTypeMapping =  AssesmentTaskRecrdTypeMapping__mdt.getInstance(visit.Account?.RecordType.Name.deleteWhitespace());
                   if(recordTypeMapping?.AssesmentTaskRecordType__c != null){
                       assesmentTaskRecordTypeId = Schema.SObjectType.AssessmentTask.getRecordTypeInfosByName().get(recordTypeMapping.AssesmentTaskRecordType__c).getRecordTypeId(); 
                   }
                }
                
                for(AssessmentTaskDefinition ATDs :aTD){
                    AssessmentTask  newAssessmentTask = new AssessmentTask();
                    if(String.isNotEmpty(ATDs.Category__c)){
                    newAssessmentTask.Name = ATDs.Category__c;
                    }
                    else{
                        newAssessmentTask.Name  = ATDs.Name;
                    }
                    newAssessmentTask.AssessmentTaskDefinitionId = ATDs.Id;
                    newAssessmentTask.ParentId = visitId;
                    newAssessmentTask.TaskType = BCMOH_Constants.TaskType;
                    newAssessmentTask.RecordTypeId = assesmentTaskRecordTypeId;
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