public with sharing class InspectionQuestionsController {
    public static String STATUS_PLANNED = 'Planned';
    public static final String STATUS_INPROGRESS = 'InProgress';

    @AuraEnabled(cacheable = false)
    public static List<TaskGroupWrapper> getInspectionQuestions(Id visitId) {
        if (visitId == null) {
            return new List<TaskGroupWrapper>();
        }

        Map<Id, Id> definitionToTaskIdMap = new Map<Id, Id>();

        for (AssessmentTask task : [
            SELECT Id, AssessmentTaskDefinitionId
            FROM AssessmentTask
            WHERE ParentId = :visitId
            AND AssessmentTaskDefinitionId != null
        ]) {
            definitionToTaskIdMap.put(task.AssessmentTaskDefinitionId, task.Id);
        }

        if (definitionToTaskIdMap.isEmpty()) {
            return new List<TaskGroupWrapper>();
        }

       List<AssessmentTaskIndDefinition> indicatorDefinitions = [
            SELECT Id,
                   Name,
                   DisplayOrder,
                   AssessmentTaskDefinitionId,
                   AssessmentTaskDefinition.Name,
                   AssessmentIndDefinitionId,
                   AssessmentIndDefinition.Name,
                   AssessmentIndDefinition.DataType,
                   AssessmentIndDefinition.PHOCSParentId__c,
           		   AssessmentIndDefinition.Criticality__c
            FROM AssessmentTaskIndDefinition
            WHERE AssessmentTaskDefinitionId IN :definitionToTaskIdMap.keySet()
            ORDER BY AssessmentTaskDefinition.Name, DisplayOrder ASC
        ];

        Map<Id, TaskGroupWrapper> taskGroupByDefinition = new Map<Id, TaskGroupWrapper>();

        for (AssessmentTaskIndDefinition indicatorRecord : indicatorDefinitions) {
            Id taskDefinitionId = indicatorRecord.AssessmentTaskDefinitionId;

            if (!definitionToTaskIdMap.containsKey(taskDefinitionId)) {
                continue;
            }

            Id actualTaskId = definitionToTaskIdMap.get(taskDefinitionId);

            if (!taskGroupByDefinition.containsKey(taskDefinitionId)) {
                taskGroupByDefinition.put(taskDefinitionId, new TaskGroupWrapper(
                    taskDefinitionId,
                    indicatorRecord.AssessmentTaskDefinition.Name
                ));
            }

            TaskGroupWrapper taskGroup = taskGroupByDefinition.get(taskDefinitionId);

            taskGroup.allQuestions.add(new QuestionWrapper(
                indicatorRecord.AssessmentIndDefinition.Name,
                actualTaskId, 
                indicatorRecord.AssessmentIndDefinition.DataType,
                indicatorRecord.AssessmentIndDefinition.PHOCSParentId__c,
                //indicatorRecord.AssessmentIndDefinitionId
                indicatorRecord.AssessmentIndDefinitionId,
                'Critical'.equalsIgnoreCase(indicatorRecord.AssessmentIndDefinition.Criticality__c)
            ));
        }

        for (TaskGroupWrapper taskGroup : taskGroupByDefinition.values()) {
            Map<Id, QuestionWrapper> parentQuestionMap = new Map<Id, QuestionWrapper>();
            List<QuestionWrapper> parentQuestionList = new List<QuestionWrapper>();

            for (QuestionWrapper questionWrapper : taskGroup.allQuestions) {
                if (questionWrapper.parentQuestionId == null) {
                    parentQuestionMap.put(questionWrapper.assessmentIndicatorDefinitionId, questionWrapper);
                    parentQuestionList.add(questionWrapper);
                }
            }

            for (QuestionWrapper questionWrapper : taskGroup.allQuestions) {
                if (questionWrapper.parentQuestionId != null &&
                    parentQuestionMap.containsKey(questionWrapper.parentQuestionId)) {
                    parentQuestionMap
                        .get(questionWrapper.parentQuestionId)
                        .childQuestions
                        .add(questionWrapper);
                }
            }

            taskGroup.parentQuestions = parentQuestionList;
        }

        return taskGroupByDefinition.values();
    }

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

   @AuraEnabled
    public static void createInspectionAssessments(List<AssessmentResponseWrapper> responses) {
        Map<String, Object> inptKeyVsValue = new Map<string, Object>();
        Map<String, Object> output1KeyVsValue = new Map<string, Object>();
        Map<String, Object> output2KeyVsValue = new Map<string, Object>();
        if (responses == null || responses.isEmpty()) return;

        List<InspectionAssessmentInd> recordsToInsert = new List<InspectionAssessmentInd>();

        for (AssessmentResponseWrapper response : responses) {
            if (response.assessmentTaskId == null || response.assessmentIndicatorDefinitionId == null) {
                continue;
            }
            String dt = response.questionDataType != null ? response.questionDataType.trim().toUpperCase() : 'TEXT';

            InspectionAssessmentInd record = new InspectionAssessmentInd();
            record.AssessmentTaskId = response.assessmentTaskId;
            record.AssessmentIndDefinitionId = response.assessmentIndicatorDefinitionId;
            record.Result = response.assessmentResult;
            //record.TextFieldResponse = response.assessmentResult;
            if(response.questionDataType == 'BOOLEAN'){
                record.PHOCSCheckboxResponse__c = (response.assessmentResult != null && (response.assessmentResult.equalsIgnoreCase('true') ||
                                                  response.assessmentResult.equalsIgnoreCase('checked') || response.assessmentResult.equalsIgnoreCase('yes')));
            }else{
                  record.TextFieldResponse = response.assessmentResult;
                }
            if (String.isNotBlank(response.inspectionComments)) {
                record.PHOCSInspectionComments__c = response.inspectionComments;
            }
            recordsToInsert.add(record);
            
            inptKeyVsValue.put('AssessmentTaskId', response.assessmentTaskId);
            inptKeyVsValue.put('AssessmentIndDefinitionId', response.assessmentIndicatorDefinitionId);
            inptKeyVsValue.put('Result', response.assessmentResult);
            inptKeyVsValue.put('TextFieldResponse', response.assessmentResult);
            inptKeyVsValue.put('PHOCSInspectionComments__c', response.inspectionComments);
        }

        if (!recordsToInsert.isEmpty()) {
            try {
               //insert recordsToInsert;               
            } catch (DmlException ex) {
                System.debug('DML Error: ' + ex.getDmlMessage(0));
                throw new AuraHandledException('Unable to create inspection assessments: ' + ex.getDmlMessage(0));
            }
        }
        		

        
        if(!inptKeyVsValue.isEmpty()) {
             if (Test.isRunningTest()) {
        		System.debug('Skipping storeResponses in test mode');
        	return;
    }
            PublicSectrSltn.AssessmentResponses.storeResponses(inptKeyVsValue, output1KeyVsValue, output2KeyVsValue);
            }
    }
    
    @AuraEnabled
    public static void updateInspectionStatusToInProgress(Id inspectionId) {
        
        Visit vistRec = [SELECT Id, Status FROM Visit WHERE Id =: inspectionId LIMIT 1];
        
        if (vistRec.Status != STATUS_INPROGRESS && vistRec.Status == STATUS_PLANNED) {
            vistRec.Status = STATUS_INPROGRESS;
            update vistRec;
        }
    }


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

    public class QuestionWrapper {
        @AuraEnabled public String questionText { get; set; }
        @AuraEnabled public String dataType { get; set; }
        @AuraEnabled public Id assessmentTaskId { get; set; }
        @AuraEnabled public Id parentQuestionId { get; set; }
        @AuraEnabled public Id assessmentIndicatorDefinitionId { get; set; }
        @AuraEnabled public Boolean showCriticalIcon { get; set; }
        @AuraEnabled public List<QuestionWrapper> childQuestions { get; set; }

        public QuestionWrapper(
            String questionTextValue,
            Id taskIdValue,
            String dataTypeValue,
            Id parentIndicatorId,
            Id indicatorDefinitionId,
            Boolean showIcon
        ) {
            questionText = questionTextValue;
            assessmentTaskId = taskIdValue;
            dataType = dataTypeValue;
            parentQuestionId = parentIndicatorId;
            assessmentIndicatorDefinitionId = indicatorDefinitionId;
            showCriticalIcon = showIcon;
            childQuestions = new List<QuestionWrapper>();
        }
    }

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

    public class AssessmentResponseWrapper {
        @AuraEnabled public Id assessmentTaskId { get; set; }
        @AuraEnabled public Id assessmentIndicatorDefinitionId { get; set; }
        @AuraEnabled public String assessmentResult { get; set; }
        @AuraEnabled public String inspectionComments { get; set; }
        @AuraEnabled public String questionDataType { get; set; }        
    }
}