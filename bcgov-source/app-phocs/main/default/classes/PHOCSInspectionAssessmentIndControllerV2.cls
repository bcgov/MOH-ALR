/**
* @description Controller for saving and retrieving inspection assessment responses
* @author PHOCS Team
* @version 2.0
* @date 2025-12-14
* 
*/
public without sharing class PHOCSInspectionAssessmentIndControllerV2 {    
    private static final String CLASS_NAME = 'PHOCSInspectionAssessmentIndControllerV2';
    
/**
* @description Saves multiple assessment responses in a single bulk operation
* @param responses List of AssessmentResponseWrapper containing response data
* @return SaveResponsesResult with success status and created/updated record IDs
*/   
    @AuraEnabled
    public static SaveResponsesResult saveAssessmentResponses(List<AssessmentResponseWrapper> responses){
        SaveResponsesResult result = new SaveResponsesResult();
        
        if (responses == null || responses.isEmpty()) {
            result.success = true;
            result.message = 'No responses to save';
            return result;
        }
        
        try {
            Set<Id> taskIds = new Set<Id>();
            Set<Id> defIds = new Set<Id>();
            
            for (AssessmentResponseWrapper r : responses) {
                if (r.assessmentTaskId != null) taskIds.add(r.assessmentTaskId);
                if (r.definitionId != null) defIds.add(r.definitionId);
            }
            
            Map<Id, Map<Id, InspectionAssessmentInd>> existingByTaskThenDef = new Map<Id, Map<Id, InspectionAssessmentInd>>();
            
            List<InspectionAssessmentInd> InspAssessmentIndList = [SELECT Id, AssessmentTaskId, AssessmentIndDefinitionId, Result, PHOCSInspectionComments__c, PHOCSCheckboxResponse__c,
                                                                   Priority__c, ComplianceDueDate__c, CorrectiveActionDescription__c, CorrectedDuringInspection__c
                                                                   FROM InspectionAssessmentInd WHERE AssessmentTaskId IN :taskIds AND AssessmentIndDefinitionId IN :defIds];
            
            if (!taskIds.isEmpty() && !defIds.isEmpty() && !InspAssessmentIndList.isEmpty()) {
                for (InspectionAssessmentInd rec : InspAssessmentIndList) {
                    if (!existingByTaskThenDef.containsKey(rec.AssessmentTaskId)) {
                        existingByTaskThenDef.put(rec.AssessmentTaskId, new Map<Id, InspectionAssessmentInd>());
                    }
                    existingByTaskThenDef.get(rec.AssessmentTaskId).put(rec.AssessmentIndDefinitionId, rec);
                }
            }

            Id recordTypeId = Schema.SObjectType.InspectionAssessmentInd .getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
            
            List<InspectionAssessmentInd> recordsToUpsert = new List<InspectionAssessmentInd>();
            
            for (AssessmentResponseWrapper resp : responses) {
                
                if (resp.assessmentTaskId == null || resp.definitionId == null) {
                    continue;
                }
                
                InspectionAssessmentInd rec;
                
                if (existingByTaskThenDef.containsKey(resp.assessmentTaskId) && existingByTaskThenDef.get(resp.assessmentTaskId).containsKey(resp.definitionId)) {
                    rec = existingByTaskThenDef.get(resp.assessmentTaskId).get(resp.definitionId);
                } else {
                    rec = new InspectionAssessmentInd(AssessmentTaskId = resp.assessmentTaskId, AssessmentIndDefinitionId = resp.definitionId, RecordTypeId = recordTypeId);
                }
                
                rec.PHOCSInspectionComments__c = resp.comment;
                
                if (resp.result != null) {
                    String normalized = resp.result.trim();
                    
                    Map<String, String> valueMap = new Map<String, String>{'Not Applicable' => 'N/A (Not Applicable)', 'Not Inspected' => 'N/S (Not Assessed)','Non-compliant'=> 'PHOCSNonCompliant'};
                        
                        if (valueMap.containsKey(normalized)) {
                            normalized = valueMap.get(normalized);
                        }
                    
                    rec.Result = normalized;
                }
                
                if (resp.selectPriority != null) {
                    rec.Priority__c = resp.selectPriority;
                }
                
                if (resp.preferredDateTime != null) {
                    rec.ComplianceDueDate__c = resp.preferredDateTime;
                }
                
                if (resp.actionDescription != null) {
                    rec.CorrectiveActionDescription__c = resp.actionDescription;
                }
                
                if (resp.correctedDuringInspection != null) {
                    rec.CorrectedDuringInspection__c = resp.correctedDuringInspection;
                }
                
                if (resp.checkboxValue != null) {
                    rec.PHOCSCheckboxResponse__c = resp.checkboxValue;
                }
                
                recordsToUpsert.add(rec);
            }
            
            if (!recordsToUpsert.isEmpty()) {
                
                if (!Schema.sObjectType.InspectionAssessmentInd.isCreateable() || !Schema.sObjectType.InspectionAssessmentInd.isUpdateable()) {
                    throw new AuraHandledException('Insufficient permissions to save InspectionAssessmentInd records');
                }
                
                List<InspectionAssessmentInd> finalRecords;
                
                if (!Test.isRunningTest()) {
                    SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, recordsToUpsert);
                    finalRecords = (List<InspectionAssessmentInd>) decision.getRecords();
                }else{
                    finalRecords = recordsToUpsert;
                }
                
                Database.UpsertResult[] results = Database.upsert(finalRecords, false);
                Integer i = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        InspectionAssessmentInd saved = finalRecords[i];
                        result.definitionIdToRecordIdMap.put(saved.AssessmentIndDefinitionId, r.getId());
                    } else {
                        for (Database.Error e : r.getErrors()) {
                            result.errors.add(e.getMessage());
                        }
                    }
                    i++;
                }
            }
            
            result.success = result.errors.isEmpty();
            result.message = result.success ? 'Assessment responses saved successfully' : 'Saved with errors';
            
        } catch (Exception ex) {
            result.success = false;
            result.message = ex.getMessage();
            result.errors.add(ex.getMessage());
            throw new AuraHandledException(result.message);
        }
        
        return result;
    }
    
/**
* @description Retrieves existing comments and checkbox values for given definition/task combinations
* @param defIds List of AssessmentIndicatorDefinition IDs
* @param taskIds List of AssessmentTask IDs
* @return Map of composite key to response data
*/
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getExistingCommentsByDefAndTask(List<Id> defIds, List<Id> taskIds) {
        Map<String, Object> commentsMap = new Map<String, Object>();
        
        if (defIds == null) defIds = new List<Id>();
        if (taskIds == null) taskIds = new List<Id>();
        
        // Remove nulls and deduplicate
        Set<Id> cleanDefIds = new Set<Id>(defIds);
        cleanDefIds.remove(null);
        Set<Id> cleanTaskIds = new Set<Id>(taskIds);
        cleanTaskIds.remove(null);
        
        if (cleanDefIds.isEmpty() || cleanTaskIds.isEmpty()) {
            return commentsMap;
        }
        
        // Query for matching responses
        for (InspectionAssessmentInd rec : [SELECT AssessmentIndDefinitionId, AssessmentTaskId, PHOCSInspectionComments__c, PHOCSCheckboxResponse__c, Result, Priority__c,
                                            ComplianceDueDate__c,CorrectiveActionDescription__c,CorrectedDuringInspection__c
                                            FROM InspectionAssessmentInd WHERE AssessmentIndDefinitionId IN :cleanDefIds AND AssessmentTaskId IN :cleanTaskIds
                                            //WITH SECURITY_ENFORCED
                                           ]) {
                                               String key = String.valueOf(rec.AssessmentIndDefinitionId) + '|' + String.valueOf(rec.AssessmentTaskId);
                                               
                                               commentsMap.put(key, new Map<String, Object>{
                                                   'comment' => rec.PHOCSInspectionComments__c,
                                                       'checkbox' => rec.PHOCSCheckboxResponse__c,
                                                       'result' => rec.Result,
                                                       'priority' => rec.Priority__c,
                                                       'preferredDateTime' => rec.ComplianceDueDate__c,
                                                       'actionDescription' => rec.CorrectiveActionDescription__c,
                                                       'correctedDuringInspection' => rec.CorrectedDuringInspection__c
                                                       });
                                           }
        
        return commentsMap;
    }
    
/**
* @description Links uploaded files (ContentDocuments) to InspectionAssessmentInd records
* @param definitionIdToContentDocIds Map of DefinitionId to list of ContentDocumentIds
* @param definitionIdToAssessmentIndId Map of DefinitionId to InspectionAssessmentInd Id
*/
    @AuraEnabled
    public static void linkFilesToAssessmentRecords(Map<String, List<String>> definitionIdToContentDocIds, Map<String, String> definitionIdToAssessmentIndId) {
        if (definitionIdToContentDocIds == null || definitionIdToContentDocIds.isEmpty()) {
            return;
        }
        
        List<ContentDocumentLink> linksToCreate = new List<ContentDocumentLink>();
        
        for (String defId : definitionIdToContentDocIds.keySet()) {
            String assessmentIndId = definitionIdToAssessmentIndId.get(defId);
            
            if (String.isNotBlank(assessmentIndId)) {
                List<String> contentDocIds = definitionIdToContentDocIds.get(defId);
                
                if (contentDocIds != null) {
                    for (String contentDocId : contentDocIds) {
                        if (String.isNotBlank(contentDocId)) {
                            linksToCreate.add(new ContentDocumentLink(
                                LinkedEntityId = Id.valueOf(assessmentIndId),
                                ContentDocumentId = Id.valueOf(contentDocId),
                                ShareType = 'V', // Viewer permission
                                Visibility = 'AllUsers'
                            ));
                        }
                    }
                }
            }
        }
        
        if (!linksToCreate.isEmpty()) {
            // Check permissions
            if (!Schema.sObjectType.ContentDocumentLink.isCreateable()) {
                throw new AuraHandledException('Insufficient permissions to link files');
            }
            
            try {
                insert linksToCreate;
            } catch (DmlException ex) {
                throw new AuraHandledException('Error linking files: ' + ex.getMessage());
            }
        }
    }
    
    // ============================================
    // WRAPPER CLASSES
    // ============================================
    
/**
* @description Wrapper for assessment response data from LWC
*/
    public class AssessmentResponseWrapper {
        @AuraEnabled public Id inspectionAssessmentIndId { get; set; }
        @AuraEnabled public Id assessmentTaskId { get; set; }
        @AuraEnabled public Id definitionId { get; set; }
        @AuraEnabled public String comment { get; set; }
        @AuraEnabled public String result { get; set; }
        @AuraEnabled public Boolean checkboxValue { get; set; }
        @AuraEnabled public Boolean correctedDuringInspection { get; set; }
        @AuraEnabled public String selectPriority { get; set; }
        @AuraEnabled public Datetime preferredDateTime { get; set; }
        @AuraEnabled public String actionDescription { get; set; }
    }
    
/**
* @description Result wrapper for SaveResponsesResult
*/
    public class SaveResponsesResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Map<String, Id> definitionToRecordIdMap { get; set; }
        @AuraEnabled public Map<Id, Id> definitionIdToRecordIdMap { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<String> errors { get; set; }
        
        public SaveResponsesResult() {
            this.success = false;
            this.definitionToRecordIdMap = new Map<String, Id>();
            this.definitionIdToRecordIdMap = new Map<Id, Id>();
            this.message = '';
            this.errors = new List<String>();
        }
    }
    
/**
* Priority and compliance due date save response wrapper  
*/
    
    @AuraEnabled(cacheable=true)
    public static Map<Id, RegulatoryCodeViolation> getViolationsFromInspection(Id visitId) {
        Map<Id, RegulatoryCodeViolation> result = new Map<Id, RegulatoryCodeViolation>();
        List<RegulatoryCodeViolation> violations = [
            SELECT Id,
            InspectionAssmntIndId,
            Priority,
            ComplianceDueDate,
            CorrectiveActionDescription
            FROM RegulatoryCodeViolation
            WHERE InspectionId = :visitId
            AND InspectionAssmntIndId != null
        ];
        
        Set<Id> inspectionIndIds = new Set<Id>();
        for (RegulatoryCodeViolation v : violations) {
            inspectionIndIds.add(v.InspectionAssmntIndId);
        }
        
        
        Map<Id, Id> indToDefMap = new Map<Id, Id>();
        for (InspectionAssessmentInd ind : [
            SELECT Id, AssessmentIndDefinitionId
            FROM InspectionAssessmentInd
            WHERE Id IN :inspectionIndIds
        ]) {
            indToDefMap.put(ind.Id, ind.AssessmentIndDefinitionId);
        }
        
        for (RegulatoryCodeViolation v : violations) {
            Id defId = indToDefMap.get(v.InspectionAssmntIndId);
            if (defId != null) {
                result.put(defId, v);
            }
        }
        
        return result;
    }
    
    
    public class RegulatoryCodeViolationWrapper {
        @AuraEnabled public Id regcodvioId { get; set; }
        @AuraEnabled public Datetime preferredDateTime { get; set; }
        @AuraEnabled public String selectPriority { get; set; }
        @AuraEnabled public String actionDescription { get; set; }
    }
    
    
    @AuraEnabled
    public static void updateRegulatoryCodeViolations(List<RegulatoryCodeViolationWrapper> rcodevio){
        if (rcodevio == null || rcodevio.isEmpty()) {
            return;
        }
        
        Set<Id> violationIds = new Set<Id>();
        for (RegulatoryCodeViolationWrapper w : rcodevio) {
            if (w.regcodvioId != null) {
                violationIds.add(w.regcodvioId);
            }
        }
        
        if (violationIds.isEmpty()) {
            return;
        }
        
        Map<Id, RegulatoryCodeViolation> violationMap =
            new Map<Id, RegulatoryCodeViolation>([
                SELECT Id,
                InspectionAssmntIndId,
                InspectionAssmntInd.Priority__c,
                InspectionAssmntInd.ComplianceDueDate__c,
                InspectionAssmntInd.CorrectiveActionDescription__c
                FROM RegulatoryCodeViolation
                WHERE Id IN :violationIds
                AND InspectionAssmntIndId != null
            ]);
        
        List<RegulatoryCodeViolation> recordsToUpdate =
            new List<RegulatoryCodeViolation>();
        
        
        for (RegulatoryCodeViolation vio : violationMap.values()) {
            
            InspectionAssessmentInd resp = vio.InspectionAssmntInd;
            if (resp == null) {
                continue;
            }
            
            RegulatoryCodeViolation rec = new RegulatoryCodeViolation(
                Id = vio.Id,
                Priority = resp.Priority__c,
                ComplianceDueDate = resp.ComplianceDueDate__c,
                CorrectiveActionDescription = resp.CorrectiveActionDescription__c
            );
            
            recordsToUpdate.add(rec);
        }
        
        
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
    
/**
* @description Update the inspection status to complete & closing comments.
*/    
    @AuraEnabled
    public static void completeInspection(Id visitId, String closingComments, String timeSpent, Boolean followUpInspectionRequired) {
        Visit visitRec = [SELECT Id, Status, StatusRemarks, ActualVisitEndTime FROM Visit WHERE Id =: visitId LIMIT 1];
        
        visitRec.Status = 'Completed';
        visitRec.StatusRemarks = closingComments;
        visitRec.ActualVisitEndTime = System.now();
        visitRec.PHOCSIsDraft__c = false; 
        visitRec.TimeSpentMinutes__c = timeSpent;
        visitRec.FollowUpInspectionRequired__c = followUpInspectionRequired;
        update visitRec;
    }    
    
/**
* @description: return the inspection record with PHOCSIsDraft__c.
*/     
    @AuraEnabled(cacheable=true)
    public static Visit getVisitMeta(Id visitId) {
        return [SELECT Id, PHOCSIsDraft__c, Status, ownerId FROM Visit WHERE Id = :visitId LIMIT 1];
    }
    
    
/**
* @description: Update PHOCSIsDraft__c to true on click of Save For Later.
*/    
    @AuraEnabled
    public static void markInspectionAsDraft(Id visitId) {
        if (visitId == null) return;
        
        Visit v = [SELECT Id, PHOCSIsDraft__c, Status FROM Visit WHERE Id = :visitId LIMIT 1];        
        v.PHOCSIsDraft__c = true;        
        update v;
    }
    
/**
* @description: Update Child Responses For Compliant Parent Responses.
*/      
    @AuraEnabled
    public static void resetChildResponsesForCompliantParents(Id visitId) {
        if (visitId == null) return;
        
        List<InspectionAssessmentInd> compliantParents = [SELECT Id, AssessmentTaskId, AssessmentIndDefinitionId
                                                          FROM InspectionAssessmentInd WHERE AssessmentTask.ParentId = :visitId AND Result = 'Compliant' AND AssessmentIndDefinition.PHOCSParentId__c = null];
        
        if (compliantParents.isEmpty()) return;
        
        Map<Id, Set<Id>> taskToParentDefIds = new Map<Id, Set<Id>>();
        
        for (InspectionAssessmentInd parent : compliantParents) {
            if (!taskToParentDefIds.containsKey(parent.AssessmentTaskId)) {
                taskToParentDefIds.put(parent.AssessmentTaskId, new Set<Id>());
            }
            taskToParentDefIds.get(parent.AssessmentTaskId).add(parent.AssessmentIndDefinitionId);
        }
        
        Set<Id> allParentDefIds = new Set<Id>();
        for (Set<Id> defIds : taskToParentDefIds.values()) {
            allParentDefIds.addAll(defIds);
        }        
        
        Set<Id> relevantDefIds = new Set<Id>();
        for (AssessmentIndicatorDefinition def : [SELECT Id FROM AssessmentIndicatorDefinition WHERE Id IN :allParentDefIds]) {
            relevantDefIds.add(def.Id);
        }
        
        List<InspectionAssessmentInd> childrenToReset = [SELECT Id, Result, PHOCSCheckboxResponse__c FROM InspectionAssessmentInd
                                                         WHERE AssessmentTaskId IN :taskToParentDefIds.keySet() AND AssessmentIndDefinition.PHOCSParentId__c IN :relevantDefIds];
        
        if (childrenToReset.isEmpty()) return;
        
        for (InspectionAssessmentInd child : childrenToReset) {
            child.Result = null;
            child.PHOCSCheckboxResponse__c = false;
        }
        
        update childrenToReset;
    }

/**
* @description: ownership enforcement at Resume Inspection.
*/       
    @AuraEnabled
    public static void validateResumeInspection(Id visitId) {
        if (visitId == null) {
            throw new AuraHandledException('Invalid inspection record.');
        }
        
        Visit visitRec = [SELECT Id, OwnerId, PHOCSIsDraft__c, Status FROM Visit WHERE Id = :visitId LIMIT 1];
        
        Boolean isStatusInProgress = visitRec.Status == 'InProgress';
        Boolean isNotOwner = visitRec.OwnerId != UserInfo.getUserId();
        
        if(visitRec.PHOCSIsDraft__c && isStatusInProgress && isNotOwner){
            throw new AuraHandledException('Only the Officer who started the inspection can resume this inspection');
        }
    }
    
}