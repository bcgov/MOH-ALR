/**
 * @description Controller for saving and retrieving inspection assessment responses
 * @author PHOCS Team
 * @version 2.0
 * @date 2025-12-14
 * 
 */
public with sharing class PHOCSInspectionAssessmentIndControllerV2 {

    private static final String CLASS_NAME = 'PHOCSInspectionAssessmentIndControllerV2';

    /**
     * @description Saves multiple assessment responses in a single bulk operation
     * @param responses List of AssessmentResponseWrapper containing response data
     * @return SaveResponsesResult with success status and created/updated record IDs
     */
    @AuraEnabled
    public static SaveResponsesResult saveAssessmentResponses(List<AssessmentResponseWrapper> responses) {
        SaveResponsesResult result = new SaveResponsesResult();
        
        if (responses == null || responses.isEmpty()) {
            result.success = true;
            result.message = 'No responses to save';
            return result;
        }

        try {
            // Build set of keys to query existing records
            Set<Id> definitionIds = new Set<Id>();
            Set<Id> taskIds = new Set<Id>();
            
            for (AssessmentResponseWrapper resp : responses) {
                if (resp.definitionId != null) definitionIds.add(resp.definitionId);
                if (resp.assessmentTaskId != null) taskIds.add(resp.assessmentTaskId);
            }

            // Query existing InspectionAssessmentInd records
            Map<String, InspectionAssessmentInd> existingRecordsMap = new Map<String, InspectionAssessmentInd>();
            
            if (!definitionIds.isEmpty() && !taskIds.isEmpty()) {
                for (InspectionAssessmentInd rec : [
                    SELECT Id, AssessmentIndDefinitionId, AssessmentTaskId, 
                           PHOCSInspectionComments__c, Result, PHOCSCheckboxResponse__c,Priority__c,ComplianceDueDate__c,CorrectiveActionDescription__c,CorrectedDuringInspection__c
                    FROM InspectionAssessmentInd
                    WHERE AssessmentIndDefinitionId IN :definitionIds
                    AND AssessmentTaskId IN :taskIds
                    WITH SECURITY_ENFORCED
                ]) {
                    String key = String.valueOf(rec.AssessmentIndDefinitionId) + '|' + String.valueOf(rec.AssessmentTaskId);
                    existingRecordsMap.put(key, rec);
                }
            }

            // Get RecordType ID for new records
            Id recordTypeId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName()
                .get('PHOCSInspectionAssessmentInd')
                .getRecordTypeId();

            // Build list of records to upsert
            List<InspectionAssessmentInd> recordsToUpsert = new List<InspectionAssessmentInd>();
            Map<String, Integer> keyToIndexMap = new Map<String, Integer>();

            for (AssessmentResponseWrapper resp : responses) {
                                       

                if (resp.definitionId == null || resp.assessmentTaskId == null) {
                    continue;
                }

                String key = String.valueOf(resp.definitionId) + '|' + String.valueOf(resp.assessmentTaskId);
                InspectionAssessmentInd rec;

                // Check if record exists
                if (existingRecordsMap.containsKey(key)) {
                    rec = existingRecordsMap.get(key);
                } else {
                    rec = new InspectionAssessmentInd();
                    rec.AssessmentIndDefinitionId = resp.definitionId;
                    rec.AssessmentTaskId = resp.assessmentTaskId;
                    rec.RecordTypeId = recordTypeId;
                }

                // Update fields
                rec.PHOCSInspectionComments__c = resp.comment;
                rec.Result = resp.result;
                rec.Priority__c = resp.selectPriority;
                rec.ComplianceDueDate__c = resp.preferredDateTime;
                rec.CorrectedDuringInspection__c = resp.correctedDuringInspection;
                rec.CorrectiveActionDescription__c = resp.actionDescription;
                
                if (resp.checkboxValue != null) {
                    rec.PHOCSCheckboxResponse__c = resp.checkboxValue;
                }

                keyToIndexMap.put(key, recordsToUpsert.size());
                recordsToUpsert.add(rec);
                                        

            }

            // Perform CRUD/FLS check and upsert
            if (!recordsToUpsert.isEmpty()) {
                // Check permissions
                if (!Schema.sObjectType.InspectionAssessmentInd.isCreateable() || 
                    !Schema.sObjectType.InspectionAssessmentInd.isUpdateable()) {
                    throw new AuraHandledException('Insufficient permissions to create/update InspectionAssessmentInd records');
                }

                // Strip inaccessible fields for security
                SObjectAccessDecision securityDecision = Security.stripInaccessible(
                    AccessType.UPSERTABLE, 
                    recordsToUpsert
                );
                List<InspectionAssessmentInd> sanitizedRecords = (List<InspectionAssessmentInd>) securityDecision.getRecords();

                Database.UpsertResult[] upsertResults = Database.upsert(sanitizedRecords, false);

                // Process results and build return map
                Integer index = 0;
                for (String key : keyToIndexMap.keySet()) {
                    Integer recIndex = keyToIndexMap.get(key);
                    if (recIndex < upsertResults.size() && upsertResults[recIndex].isSuccess()) {
                        result.definitionToRecordIdMap.put(key, upsertResults[recIndex].getId());
                        
                        // Also map by definition ID alone for easier lookup
                        Id defId = sanitizedRecords[recIndex].AssessmentIndDefinitionId;
                        result.definitionIdToRecordIdMap.put(defId, upsertResults[recIndex].getId());
                    } else if (recIndex < upsertResults.size()) {
                        for (Database.Error err : upsertResults[recIndex].getErrors()) {
                            result.errors.add('Error for ' + key + ': ' + err.getMessage());
                        }
                    }
                }
            }

            result.success = result.errors.isEmpty();
            result.message = result.success 
                ? 'Successfully saved ' + result.definitionToRecordIdMap.size() + ' response(s)'
                : 'Saved with ' + result.errors.size() + ' error(s)';

        } catch (Exception ex) {
            result.success = false;
            result.message = 'Error saving responses: ' + ex.getMessage();
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
        for (InspectionAssessmentInd rec : [
            SELECT AssessmentIndDefinitionId, AssessmentTaskId, 
                   PHOCSInspectionComments__c, PHOCSCheckboxResponse__c, Result, Priority__c,ComplianceDueDate__c,CorrectiveActionDescription__c,CorrectedDuringInspection__c
            FROM InspectionAssessmentInd
            WHERE AssessmentIndDefinitionId IN :cleanDefIds
            AND AssessmentTaskId IN :cleanTaskIds
            WITH SECURITY_ENFORCED
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
    public static void linkFilesToAssessmentRecords(
        Map<String, List<String>> definitionIdToContentDocIds,
        Map<String, String> definitionIdToAssessmentIndId
    ) {
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
     * @description Result wrapper for saveAssessmentResponses
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
		public static void updateRegulatoryCodeViolations(
    		List<RegulatoryCodeViolationWrapper> rcodevio
		) {
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

    
}