/**********************************************************************************************
* @Author:      Accenture 
* @Date:        19 Dec 2025
* @Description: The purpose of this class is to create AssessmentTaskIndDefinition for PHOCS Inspections.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                06 Jan -  PHOCS-2681        -  Accenture   -  InvocableMethod is to call from InspectionAssessmentTaskCreation flow.
                05 Jan -  PHOCS-2681        -  Accenture   -  Create AssessmentTaskIndDefinition for PHOCS Inspections records.
                05 Jan -  PHOCS-2681        -  Accenture   -  return Dairy ActionPlanTemplateNames.
                06 Apr -  PHOCS-3459        -  Accenture   -  return PSE ActionPlanTemplateNames.
                06 Apr -  PHOCS-3349        -  Accenture   -  return Food ActionPlanTemplateNames.
***********************************************************************************************/
public without sharing class InspectionAssessmentTaskCreationService {
    public static String className = 'InspectionAssessmentTaskCreationService';
    public static Boolean forceSignatureProcessingInTest = false;
    public static Set<Id> testSignatureItemIds = new Set<Id>();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
/**
* @author: Deepak
* @date: 06 Jan 2026
* @description: The purpose of this InvocableMethod is to call from InspectionAssessmentTaskCreation flow.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @InvocableMethod(label='Execute Inspection Assessment Task Creation')
    public static void executeInspectionQuestions(List<FlowInputs> ATI){
        if (ATI == null || ATI.isEmpty()) return;
        Set<Id> inspectionIds = new Set<Id>();
        for (FlowInputs input : ATI) {
            inspectionIds.add(input.inspId);   
        }
        if (!inspectionIds.isEmpty()){
            for (Id visitId : inspectionIds) {
                runForVisit(visitId);
            }
        }
    }
    
/**
* @author: Deepak
* @date: 05 Jan 2026
* @description: The purpose of this Method is to create AssessmentTaskIndDefinition for PHOCS Inspections.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    public static void runForVisit(Id visitId) {
        if (visitId == null){
            return;
        } 
        try {
            Visit visit = [SELECT Id, RecordType.DeveloperName, AccountId, Account.Type, Account.RecordType.DeveloperName, VisitType.Name FROM Visit WHERE Id = :visitId LIMIT 1];
            
            if (visit.RecordTypeId != recordTypePHOCSInspection){
                return;
            }
            
            Id facilityAccountId = visit.AccountId != null ? visit.AccountId : null;
            String accountType = visit.Account != null ? visit.Account.Type : null;
            String inspectionType = visit.VisitType != null ? visit.VisitType.Name : null;
            
            Set<String> templateNames = new Set<String>();
            templateNames = getActionPlanTemplateNames(facilityAccountId, accountType, inspectionType);
            
            if (templateNames.isEmpty()) return;
            
            List<ActionPlanTemplate> templates = [SELECT Id, Name FROM ActionPlanTemplate WHERE Name IN: templateNames AND Status = 'Final'];
            
            if (templates.isEmpty()) return;
            
            List<Id> templateIds = new List<Id>();
            for (ActionPlanTemplate t : templates) templateIds.add(t.Id);
            
            List<ActionPlanTemplateVersion> versions = [SELECT Id, ActionPlanTemplateId FROM ActionPlanTemplateVersion WHERE ActionPlanTemplateId IN :templateIds AND Status = 'Final'];
            if (versions.isEmpty()) return;
            
            Set<Id> versionIds = new Set<Id>();
            for (ActionPlanTemplateVersion v : versions){
                versionIds.add(v.Id);
            } 
            
            List<ActionPlanTemplateItem> assessmentItems = [SELECT Id, ActionPlanTemplateVersionId, DisplayOrder FROM ActionPlanTemplateItem WHERE ActionPlanTemplateVersionId IN :versionIds AND ItemEntityType = 'AssessmentTask' ORDER BY DisplayOrder ASC];
            
            //List<ActionPlanTemplateItem> signatureItems = [SELECT Id, ActionPlanTemplateVersionId, DisplayOrder FROM ActionPlanTemplateItem WHERE ActionPlanTemplateVersionId IN :versionIds AND ItemEntityType = 'SignatureTask' ORDER BY DisplayOrder ASC];
            
            List<Id> assessmentItemIds = new List<Id>();            
            for (ActionPlanTemplateItem item : assessmentItems) {
                assessmentItemIds.add(item.Id);
            }
            
            /*Set<Id> signatureItemIds = new Set<Id>();
            for (ActionPlanTemplateItem it : signatureItems){
                signatureItemIds.add(it.Id);
            }
            System.debug('###signatureItemIds'+ signatureItemIds); */
            
            Map<Id, String> templateItemIdToDefName = new Map<Id, String>();
            if (!assessmentItemIds.isEmpty()) {
                List<ActionPlanTemplateItemValue> aPTemplateItemValueList = [SELECT Id, ItemEntityFieldName, ValueLiteral, ValueFormula, ActionPlanTemplateItemId FROM ActionPlanTemplateItemValue
                                                                             WHERE ActionPlanTemplateItemId IN :assessmentItemIds AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName];
                for (ActionPlanTemplateItemValue v : aPTemplateItemValueList){
                    if(String.isNotBlank(v.ValueLiteral)){
                        templateItemIdToDefName.put(v.ActionPlanTemplateItemId, v.ValueLiteral);
                    }
                }
            }
            
            //if (templateItemIdToDefName.isEmpty() && signatureItemIds.isEmpty()) {
            if (templateItemIdToDefName.isEmpty()) {
                return;
            }
            
            List<AssessmentTaskDefinition> taskDefs = new List<AssessmentTaskDefinition>();
            if (!templateItemIdToDefName.isEmpty()) {
                taskDefs = [SELECT Id, Name, Category__c FROM AssessmentTaskDefinition WHERE Name IN :templateItemIdToDefName.Values()];
            }
            
            Map<String, AssessmentTaskDefinition> defByName = new Map<String, AssessmentTaskDefinition>();
            for (AssessmentTaskDefinition def : taskDefs) {
                defByName.put(def.Name, def);
            }
            
            Id assessmentTaskRecordTypeId;
            if (visit.AccountId != null) {
                try {
                    String acctDevName = visit.Account.Type;
                    AssesmentTaskRecrdTypeMapping__mdt mapping = AssesmentTaskRecrdTypeMapping__mdt.getInstance((visit.Account.RecordType != null) ? visit.Account.RecordType.DeveloperName.deleteWhitespace() : null);
                    if (mapping != null && String.isNotBlank(mapping.AssesmentTaskRecordType__c)) {
                        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.AssessmentTask.getRecordTypeInfosByName();
                        if (rtMap.containsKey(mapping.AssesmentTaskRecordType__c)) {
                            assessmentTaskRecordTypeId = rtMap.get(mapping.AssesmentTaskRecordType__c).getRecordTypeId();
                        }
                    }
                } catch (Exception e) {
                    assessmentTaskRecordTypeId = null;
                }
            }
            
            List<AssessmentTask> tasksToInsert = new List<AssessmentTask>();
            
            for (ActionPlanTemplateItem item : assessmentItems) {
                
                String defName = templateItemIdToDefName.get(item.Id);
                if (String.isBlank(defName) || !defByName.containsKey(defName)) {
                    continue;
                }
                
                AssessmentTaskDefinition def = defByName.get(defName);
                AssessmentTask newTask = new AssessmentTask();
                newTask.Name = String.isNotBlank(def.Category__c) ? def.Category__c : def.Name;
                newTask.AssessmentTaskDefinitionId = def.Id;
                newTask.ParentId = visit.Id;
                newTask.TaskType = BCMOH_Constants.TaskType;
                newTask.RecordTypeId = (assessmentTaskRecordTypeId != null) ? assessmentTaskRecordTypeId : null;
                newTask.SequenceNumber = item.DisplayOrder;
                tasksToInsert.add(newTask);
            }            
            
            if (!tasksToInsert.isEmpty()) {
                Database.insert(tasksToInsert, true);
            }
            
            Map<Id, Id> defIdToCreatedTaskId = new Map<Id, Id>();
            for (AssessmentTask t : tasksToInsert) {
                defIdToCreatedTaskId.put(t.AssessmentTaskDefinitionId, t.Id);
            }
            
            List<InspectionAssessmentInd> indicatorsToInsert = new List<InspectionAssessmentInd>();
            Id inspAssmntIndRTId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
            
            if (!defIdToCreatedTaskId.isEmpty()) {
                List<AssessmentTaskIndDefinition> atidList = [SELECT AssessmentTaskDefinitionId, AssessmentIndDefinitionId FROM AssessmentTaskIndDefinition
                                                              WHERE AssessmentTaskDefinitionId IN :defIdToCreatedTaskId.keySet()];
                
                for (AssessmentTaskIndDefinition atid : atidList) {
                    Id createdTaskId = defIdToCreatedTaskId.get(atid.AssessmentTaskDefinitionId);
                    if (createdTaskId != null) {
                        InspectionAssessmentInd ia = new InspectionAssessmentInd();
                        ia.AssessmentTaskId = createdTaskId;
                        ia.AssessmentIndDefinitionId = atid.AssessmentIndDefinitionId;
                        ia.RecordTypeId = inspAssmntIndRTId;
                        indicatorsToInsert.add(ia);
                    }
                }
                
                if (!indicatorsToInsert.isEmpty()) {
                    Database.insert(indicatorsToInsert, true);
                }
            }
            
            if (Test.isRunningTest()) {
                forceSignatureProcessingInTest = true;
            }
            
           /* if (!signatureItemIds.isEmpty() || (Test.isRunningTest() && forceSignatureProcessingInTest)) {                
                Set<Id> effectiveSignatureItemIds = !signatureItemIds.isEmpty() ? signatureItemIds : testSignatureItemIds;
                Set<String> signatureLiterals = new Set<String>();
                
                for (ActionPlanTemplateItemValue pav : [SELECT ActionPlanTemplateItemId, ItemEntityFieldName, ValueLiteral
                                                        FROM ActionPlanTemplateItemValue WHERE ActionPlanTemplateItemId IN: effectiveSignatureItemIds AND ItemEntityFieldName = :BCMOH_Constants.ItemEntityName]) {
                                                            if (String.isNotBlank(pav.ValueLiteral)){
                                                                signatureLiterals.add(pav.ValueLiteral);
                                                            } 
                                                        }
                
                List<AssessmentTaskDefinition> sigTaskDefs = new List<AssessmentTaskDefinition>();
                if (!signatureLiterals.isEmpty()) {
                    sigTaskDefs = [SELECT Id, Name, Category__c FROM AssessmentTaskDefinition WHERE Name IN :signatureLiterals];
                }
                
                List<AssessmentTask> signatureTasksToInsert = new List<AssessmentTask>();
                for (AssessmentTaskDefinition def : sigTaskDefs) {
                    AssessmentTask nt = new AssessmentTask();
                    nt.Name = String.isNotBlank(def.Category__c) ? def.Category__c : def.Name;
                    nt.AssessmentTaskDefinitionId = def.Id;
                    nt.ParentId = visit.Id;
                    nt.TaskType = 'SignatureTask';
                    nt.RecordTypeId = assessmentTaskRecordTypeId != null ? assessmentTaskRecordTypeId : null;                        
                    signatureTasksToInsert.add(nt);
                }
                
                if (!signatureTasksToInsert.isEmpty()) {
                    Database.insert(signatureTasksToInsert);
                }
                
                List<SignatureTask> signatureChildTasks = new List<SignatureTask>();
                for (AssessmentTask st : signatureTasksToInsert) {
                    SignatureTask s = new SignatureTask();
                    s.Name = 'Signature for ' + (st.Name != null ? st.Name : '');
                    s.ParentTaskId = st.Id;
                    signatureChildTasks.add(s);
                }
                
                if (!signatureChildTasks.isEmpty()) {
                    Database.insert(signatureChildTasks);
                }
            } */
            
        } catch (Exception ex) {
            LogService.logAndPublish(className, 'runForVisit', String.valueOf(visitId), ex);
        }
    }

/**
* @author: Deepak
* @date: 05 Jan 2026
* @description: The purpose of this Method is to return ActionPlanTemplateNames.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    public static Set<String> getActionPlanTemplateNames(Id facilityAccountId, String accountType, String inspectionType){
        Set<String> getAPTemplatesName = new Set<String>();
        Set<String> attributeTypesFromAssets = new Set<String>();
        Id dairyAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('PHOCSDairyPlantRoomsandEquipment').getRecordTypeId();
        
        try {
            if(facilityAccountId == null || String.isBlank(accountType) || String.isBlank(inspectionType)){
                return getAPTemplatesName;
            }
            
            List<PHOCSActionPlanTemplateDecisionMap__mdt> decisionMaps = [SELECT ActionPlanTemplateName__c, InspectionFacilityType__c, InspectionCategory__c, AttributeType__c, Active__c,
                                                                          CategoryL1__c, CategoryL2__c, CategoryL3__c
                                                                          FROM PHOCSActionPlanTemplateDecisionMap__mdt WHERE Active__c = true AND InspectionFacilityType__c =: accountType];
            
            if(accountType == 'Dairy' && inspectionType != 'Inspection Update'){       
                getAPTemplatesName.addAll(getDairyTemplates(facilityAccountId, inspectionType, decisionMaps));
            } else if (accountType == 'Personal Services') {
                getAPTemplatesName.addAll(getPSETemplates(facilityAccountId, decisionMaps));
            } else if (accountType == 'Food') {
                getAPTemplatesName.addAll(getFoodTemplates(facilityAccountId, decisionMaps));
            }
            
        } catch(Exception e){
            LogService.logAndPublish(className, 'getActionPlanTemplateNames', 'Error in getActionPlanTemplateNames: ', e);
        }
        return getAPTemplatesName;
    }

/**
* @author: Deepak
* @date: 06 April 2026
* @description: The purpose of this Method is to return Dairy ActionPlanTemplateNames.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    private static Set<String> getDairyTemplates(Id facilityAccountId, String inspectionType, List<PHOCSActionPlanTemplateDecisionMap__mdt> decisionMaps){
        Set<String> templateNames = new Set<String>();
        Set<String> attributeTypesFromAssets = new Set<String>();        
        Id dairyAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('PHOCSDairyPlantRoomsandEquipment').getRecordTypeId();
        
        for (PHOCSActionPlanTemplateDecisionMap__mdt dm : decisionMaps) {
            if (dm.InspectionCategory__c == inspectionType && dm.AttributeType__c == null) {                    
                templateNames.add(dm.ActionPlanTemplateName__c);
            }
        }
        
        for (Asset assetObj : [SELECT PlantEquipment__c FROM Asset WHERE AccountId =: facilityAccountId AND RecordTypeId =: dairyAssetRTId AND Status = 'Active']) {
            if (String.isNotBlank(assetObj.PlantEquipment__c)) {
                attributeTypesFromAssets.add(assetObj.PlantEquipment__c);
            }
        }
        
        if (!attributeTypesFromAssets.isEmpty()) {
            for (PHOCSActionPlanTemplateDecisionMap__mdt dm : decisionMaps) {
                if (dm.AttributeType__c != null && attributeTypesFromAssets.contains(dm.AttributeType__c)) {                        
                    templateNames.add(dm.ActionPlanTemplateName__c);
                }
            }
        }        
        return templateNames;
    }
 
/**
* @author: Deepak
* @date: 06 April 2026
* @description: The purpose of this Method is to return PSE ActionPlanTemplateNames.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    private static Set<String> getPSETemplates(Id facilityAccountId, List<PHOCSActionPlanTemplateDecisionMap__mdt> decisionMaps){
        Set<String> templateNames = new Set<String>();
        Set<String> attributeTypesFromAssets = new Set<String>();        
        Id pseAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('PHOCSPersonalServices').getRecordTypeId();
        
        for (PHOCSActionPlanTemplateDecisionMap__mdt dm : decisionMaps) {
            if (dm.AttributeType__c == null) {
                templateNames.add(dm.ActionPlanTemplateName__c);
            }
        }
        
        for (Asset assetObj : [SELECT ServiceType__c FROM Asset WHERE AccountId =: facilityAccountId AND RecordTypeId =: pseAssetRTId AND Status = 'Active']) {
            if (String.isNotBlank(assetObj.ServiceType__c)) {
                attributeTypesFromAssets.add(assetObj.ServiceType__c);
            }
        }
        
        if (!attributeTypesFromAssets.isEmpty()) {
            for (PHOCSActionPlanTemplateDecisionMap__mdt dm : decisionMaps) {
                if (dm.AttributeType__c != null && attributeTypesFromAssets.contains(dm.AttributeType__c)){                        
                    templateNames.add(dm.ActionPlanTemplateName__c);
                }
            }
        }
        return templateNames;
    }

/**
* @author: Deepak
* @date: 06 April 2026
* @description: The purpose of this Method is to return Food ActionPlanTemplateNames.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/         
    private static Set<String> getFoodTemplates(Id facilityAccountId, List<PHOCSActionPlanTemplateDecisionMap__mdt> decisionMaps){
        Set<String> templateNames = new Set<String>();
        Set<String> foodFacilityServices = new Set<String>();
        
        Account facility = [SELECT CategoryL1__c, CategoryL2__c, CategoryL3__c, Service_s__c FROM Account WHERE Id = :facilityAccountId LIMIT 1];
        
        if (String.isNotBlank(facility.Service_s__c)) {
            foodFacilityServices.addAll(facility.Service_s__c.split(';'));
        }        
        String facilityCategoryL1 = facility.CategoryL1__c;
        String facilityCategoryL2 = facility.CategoryL2__c;
        String facilityCategoryL3 = facility.CategoryL3__c;
        
        for (PHOCSActionPlanTemplateDecisionMap__mdt decisionMap : decisionMaps){            
            if(decisionMap.CategoryL1__c == facilityCategoryL1 && decisionMap.CategoryL2__c == facilityCategoryL2 && decisionMap.CategoryL3__c == facilityCategoryL3){                
                templateNames.add(decisionMap.ActionPlanTemplateName__c);
            }
        }
        
        if (!foodFacilityServices.isEmpty()) {
            for (PHOCSActionPlanTemplateDecisionMap__mdt dm : decisionMaps) {
                if (dm.AttributeType__c != null && foodFacilityServices.contains(dm.AttributeType__c)){                        
                    templateNames.add(dm.ActionPlanTemplateName__c);
                }
            }
        }
        return templateNames;
    }
    
    public class FlowInputs {
        @InvocableVariable public Id inspId; 
    }
    
    public static void addTestSignatureItemIds(Set<Id> ids) {
        testSignatureItemIds.addAll(ids);
    }
}