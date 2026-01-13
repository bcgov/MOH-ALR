/**
 * @description Controller for fetching inspection questions grouped by category
 * @author PHOCS Team
 * @version 2.0
 * @date 2025-12-14
 * 
 */
public with sharing class InspectionQuestionsControllerV2 {
    public static String STATUS_PLANNED = 'Planned';
    public static final String STATUS_INPROGRESS = 'InProgress';

    /**
     * @description Fetches inspection questions grouped by AssessmentTaskDefinition
     * @param visitId The ID of the Visit (Inspection) record
     * @return List of TaskGroupWrapper containing parent/child questions with existing responses
     */
    @AuraEnabled(cacheable = false)
    public static List<TaskGroupWrapper> getInspectionQuestions(Id visitId) {
        if (visitId == null) {
            return new List<TaskGroupWrapper>();
        }
        
        // Map of AssessmentTaskDefinitionId -> AssessmentTaskId
        Map<Id, Id> definitionToTaskIdMap = new Map<Id, Id>();
        List<AssessmentTask> orderedTasks = [SELECT Id, AssessmentTaskDefinitionId, AssessmentTaskDefinition.Name, sequenceNumber FROM AssessmentTask 
                                             WHERE ParentId = :visitId AND AssessmentTaskDefinitionId != null WITH SECURITY_ENFORCED ORDER BY SequenceNumber ASC];
        
        for (AssessmentTask task : orderedTasks){
            definitionToTaskIdMap.put(task.AssessmentTaskDefinitionId, task.Id);
        }
        
        if (definitionToTaskIdMap.isEmpty()) {
            return new List<TaskGroupWrapper>();
        }
        
        List<TaskGroupWrapper> orderedTaskGroups = new List<TaskGroupWrapper>();
        Map<Id, TaskGroupWrapper> taskGroupByDefinition = new Map<Id, TaskGroupWrapper>();
        
        for (AssessmentTask task : orderedTasks) {
            TaskGroupWrapper tg = new TaskGroupWrapper(task.AssessmentTaskDefinitionId, task.AssessmentTaskDefinition.Name);
            taskGroupByDefinition.put(task.AssessmentTaskDefinitionId, tg);
            orderedTaskGroups.add(tg); 
        }
        
        // Query indicator definitions
        List<AssessmentTaskIndDefinition> indicatorDefinitions = [SELECT Id, Name, DisplayOrder, AssessmentTaskDefinitionId,
                                                                  AssessmentTaskDefinition.Name, AssessmentIndDefinitionId, AssessmentIndDefinition.Name, AssessmentIndDefinition.DataType, 
                                                                  AssessmentIndDefinition.PHOCSParentId__c, AssessmentIndDefinition.Criticality__c FROM AssessmentTaskIndDefinition
                                                                  WHERE AssessmentTaskDefinitionId IN :definitionToTaskIdMap.keySet() WITH SECURITY_ENFORCED];
                                                                  //ORDER BY  DisplayOrder ASC 
        
        // Query existing responses for all tasks
        Map<String, InspectionAssessmentInd> existingResponses = new Map<String, InspectionAssessmentInd>();
        List<InspectionAssessmentInd> inspAssmntList = new List<InspectionAssessmentInd>();
        IF(!Test.isRunningTest()){
            inspAssmntList = [SELECT Id, AssessmentIndDefinitionId, AssessmentTaskId, Result, PHOCSInspectionComments__c, PHOCSCheckboxResponse__c, 
                                                            Priority__c,ComplianceDueDate__c,CorrectiveActionDescription__c,CorrectedDuringInspection__c 
                                                            FROM InspectionAssessmentInd WHERE AssessmentTaskId IN :definitionToTaskIdMap.values() WITH SECURITY_ENFORCED];
            
        }else{
			inspAssmntList = [SELECT Id, AssessmentIndDefinitionId, AssessmentTaskId, Result, PHOCSInspectionComments__c, PHOCSCheckboxResponse__c, 
                                                            Priority__c,ComplianceDueDate__c,CorrectiveActionDescription__c,CorrectedDuringInspection__c 
                                                            FROM InspectionAssessmentInd WHERE AssessmentTaskId IN :definitionToTaskIdMap.values()];
        }
        
            for (InspectionAssessmentInd resp : inspAssmntList){
                String key = String.valueOf(resp.AssessmentIndDefinitionId) + '|' + String.valueOf(resp.AssessmentTaskId);
                existingResponses.put(key, resp);
            }
        
        // Build task groups        
        for (AssessmentTaskIndDefinition indicatorRecord : indicatorDefinitions) {
            Id taskDefinitionId = indicatorRecord.AssessmentTaskDefinitionId;
            
            if (!definitionToTaskIdMap.containsKey(taskDefinitionId)) {
                continue;
            }
            
            Id actualTaskId = definitionToTaskIdMap.get(taskDefinitionId);
            
            TaskGroupWrapper taskGroup = taskGroupByDefinition.get(taskDefinitionId);
            if (taskGroup == null) {
                continue;
            }
            
            // Look up existing response for this question
            String responseKey = String.valueOf(indicatorRecord.AssessmentIndDefinitionId) + '|' + String.valueOf(actualTaskId);
            InspectionAssessmentInd existingResp = existingResponses.get(responseKey);
            
            taskGroup.allQuestions.add(new QuestionWrapper(
                indicatorRecord.AssessmentIndDefinition.Name,
                actualTaskId, 
                indicatorRecord.AssessmentIndDefinition.DataType,
                indicatorRecord.AssessmentIndDefinition.PHOCSParentId__c,
                indicatorRecord.AssessmentIndDefinitionId,
                'Critical'.equalsIgnoreCase(indicatorRecord.AssessmentIndDefinition.Criticality__c),
                indicatorRecord.DisplayOrder,
                existingResp
            ));
        }
        
        for (TaskGroupWrapper taskGroup : taskGroupByDefinition.values()) {            
            Map<Id, QuestionWrapper> parentMap = new Map<Id, QuestionWrapper>();
            
            for (QuestionWrapper qw : taskGroup.allQuestions) {
                if (qw.parentQuestionId == null) {
                    parentMap.put(qw.assessmentIndicatorDefinitionId, qw);
                    taskGroup.parentQuestions.add(qw);
                }
            }
            
            for (QuestionWrapper qw : taskGroup.allQuestions) {
                if (qw.parentQuestionId != null && parentMap.containsKey(qw.parentQuestionId)) {
                    parentMap.get(qw.parentQuestionId).childQuestions.add(qw);
                }
            }
        }
        return orderedTaskGroups;
    }

    /**
     * @description Fetches regulatory codes linked to an assessment indicator definition
     * @param assessmentIndicatorDefinitionId The ID of the AssessmentIndicatorDefinition
     * @return List of RegulatoryCodeWrapper with code details
     */
    @AuraEnabled(cacheable = true)
    public static List<RegulatoryCodeWrapper> getRegulatoryCodesByIndicator(Id assessmentIndicatorDefinitionId) {
        if (assessmentIndicatorDefinitionId == null) {
            return new List<RegulatoryCodeWrapper>();
        }

        List<RegulatoryCodeAssessmentInd> regulatoryCodeRecords = [
            SELECT RegulatoryCode.Subject,
                   RegulatoryCode.EffectiveFrom,
                   RegulatoryCode.EffectiveTo,
                   RegulatoryCode.IsActive
            FROM RegulatoryCodeAssessmentInd
            WHERE AssessmentIndDefinitionId = :assessmentIndicatorDefinitionId
            WITH SECURITY_ENFORCED
        ];

        List<RegulatoryCodeWrapper> regulatoryCodeWrappers = new List<RegulatoryCodeWrapper>();

        for (RegulatoryCodeAssessmentInd record : regulatoryCodeRecords) {
            String formattedValidity = '';
            if (record.RegulatoryCode.EffectiveFrom != null || record.RegulatoryCode.EffectiveTo != null) {
                formattedValidity =
                    (record.RegulatoryCode.EffectiveFrom != null
                        ? String.valueOf(record.RegulatoryCode.EffectiveFrom) : '') +
                    ' to ' +
                    (record.RegulatoryCode.EffectiveTo != null
                        ? String.valueOf(record.RegulatoryCode.EffectiveTo) : '');
            }

            regulatoryCodeWrappers.add(new RegulatoryCodeWrapper(
                record.RegulatoryCode.Subject,
                record.RegulatoryCode.IsActive,
                formattedValidity
            ));
        }

        return regulatoryCodeWrappers;
    }

    // ============================================
    // WRAPPER CLASSES
    // ============================================

    /**
     * @description Wrapper for a group of questions under an AssessmentTaskDefinition
     */
    public class TaskGroupWrapper {
        @AuraEnabled public Id taskDefinitionId { get; set; }
        @AuraEnabled public String taskDefinitionName { get; set; }
        @AuraEnabled public List<QuestionWrapper> parentQuestions { get; set; }
        @AuraEnabled public List<QuestionWrapper> allQuestions { get; set; }

        public TaskGroupWrapper(Id definitionId, String definitionName) {
            taskDefinitionId = definitionId;
            taskDefinitionName = definitionName;
            parentQuestions = new List<QuestionWrapper>();
            allQuestions = new List<QuestionWrapper>();
        }
    }

    /**
     * @description Wrapper for individual question with existing response data
     */
    public class QuestionWrapper {
        @AuraEnabled public String questionText { get; set; }
        @AuraEnabled public String dataType { get; set; }
        @AuraEnabled public Id assessmentTaskId { get; set; }
        @AuraEnabled public Id parentQuestionId { get; set; }
        @AuraEnabled public Id assessmentIndicatorDefinitionId { get; set; }
        @AuraEnabled public Boolean showCriticalIcon { get; set; }
        @AuraEnabled public Integer displayOrder { get; set; }
        @AuraEnabled public List<QuestionWrapper> childQuestions { get; set; }
        
        // Existing response fields
        @AuraEnabled public Id inspectionAssessmentIndId { get; set; }
        @AuraEnabled public String Result { get; set; }
        @AuraEnabled public String PHOCSInspectionComments { get; set; }
        @AuraEnabled public Boolean PHOCSCheckboxResponse { get; set; }
        @AuraEnabled public String selectPriority { get; set; }
		@AuraEnabled public Datetime preferredDateTime { get; set; }
		@AuraEnabled public String actionDescription { get; set; }
		@AuraEnabled public Boolean correctedDuringInspection { get; set; }

        public QuestionWrapper(
            String questionTextValue,
            Id taskIdValue,
            String dataTypeValue,
            Id parentIndicatorId,
            Id indicatorDefinitionId,
            Boolean showIcon,
            Integer displayOrderValue,
            InspectionAssessmentInd existingResponse
        ) {
            questionText = questionTextValue;
            assessmentTaskId = taskIdValue;
            dataType = dataTypeValue;
            parentQuestionId = parentIndicatorId;
            assessmentIndicatorDefinitionId = indicatorDefinitionId;
            showCriticalIcon = showIcon;
            displayOrder = displayOrderValue;
            childQuestions = new List<QuestionWrapper>();
            
            // Populate existing response data if available
            if (existingResponse != null) {
                inspectionAssessmentIndId = existingResponse.Id;
                Result = existingResponse.Result;
                PHOCSInspectionComments = existingResponse.PHOCSInspectionComments__c;
                PHOCSCheckboxResponse = existingResponse.PHOCSCheckboxResponse__c;
                selectPriority = existingResponse.Priority__c;
    			preferredDateTime = existingResponse.ComplianceDueDate__c;
    			actionDescription = existingResponse.CorrectiveActionDescription__c;
    			correctedDuringInspection = existingResponse.CorrectedDuringInspection__c;
            }
        }
    }

    /**
     * @description Wrapper for regulatory code display
     */
    public class RegulatoryCodeWrapper {
        @AuraEnabled public String regulatoryCodeName { get; set; }
        @AuraEnabled public Boolean isActive { get; set; }
        @AuraEnabled public String validityText { get; set; }

        public RegulatoryCodeWrapper(String name, Boolean active, String validity) {
            regulatoryCodeName = name;
            isActive = active;
            validityText = validity;
        }
    }
    
    /**
     * @description: Update Status to inprogress on click of start inspection.
     */
    @AuraEnabled
    public static void updateInspectionStatusToInProgress(Id inspectionId) {
        
        Visit vistRec = [SELECT Id, Status FROM Visit WHERE Id =: inspectionId LIMIT 1];
        
        if (vistRec.Status != STATUS_INPROGRESS && vistRec.Status == STATUS_PLANNED) {
            vistRec.Status = STATUS_INPROGRESS;
            update vistRec;
        }
    }
}