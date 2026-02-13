/**
 * @description Service class for creating violations from non-compliant inspection questions
 * @author PHOCS Dev Team
 * @date 2025-12-14
 */
public with sharing class InspectionViolationService {
    public static Id recordTypePHOCSInspectionAssessmentInd = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
    public static Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
    public static final String RESULT_NON_COMPLIANT = 'PHOCSNonCompliant';    
    public static String className = 'InspectionViolationService';

    /**
     * @description Creates violations for all non-compliant questions and selected canned comments in an inspection
     * @param visitId The ID of the Visit (Inspection) record
     * @return ViolationResult containing created violation IDs and counts
     */
    @AuraEnabled
    public static ViolationResult createViolationsForInspection(Id visitId) {
        ViolationResult result = new ViolationResult();
        
        if (visitId == null) {
            result.message = 'Visit ID is required';
            return result;
        }

        try {
            // Get the Visit record
            Visit visitRecord = [
                SELECT Id, AccountId, Account.Name
                FROM Visit 
                WHERE Id = :visitId 
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            // Get all InspectionAssessmentInd records for this visit with their definitions
            // Including both parent (non-compliant) and child (selected canned comments) records
            List<InspectionAssessmentInd> allResponses = [
                SELECT Id, 
                       AssessmentTaskId,
                       AssessmentTask.Name,
                       AssessmentTask.ParentId,
                       AssessmentIndDefinitionId,
                       AssessmentIndDefinition.Name,
                       AssessmentIndDefinition.PHOCSParentId__c,
                       Result,
                       PHOCSInspectionComments__c,
                       PHOCSCheckboxResponse__c
                FROM InspectionAssessmentInd
                WHERE AssessmentTask.ParentId = :visitId
                WITH SECURITY_ENFORCED
            ];

            if (allResponses.isEmpty()) {
                result.message = 'No assessment responses found';
                return result;
            }

            // Separate parent questions (non-compliant) and canned comments (checkbox selected)
            List<InspectionAssessmentInd> parentNonCompliant = new List<InspectionAssessmentInd>();
            Map<Id, List<InspectionAssessmentInd>> selectedCannedCommentsByParentDefId = new Map<Id, List<InspectionAssessmentInd>>();

            for (InspectionAssessmentInd response : allResponses) {
                Id parentDefId = response.AssessmentIndDefinition?.PHOCSParentId__c;
                
                if (parentDefId == null) {
                    // This is a parent question
                    if (response.Result == 'PHOCSNonCompliant') {
                        parentNonCompliant.add(response);
                    }
                } else {
                    // This is a canned comment (child question)
                    // Only include if checkbox is selected (true)
                    if (response.PHOCSCheckboxResponse__c == true) {
                        if (!selectedCannedCommentsByParentDefId.containsKey(parentDefId)) {
                            selectedCannedCommentsByParentDefId.put(parentDefId, new List<InspectionAssessmentInd>());
                        }
                        selectedCannedCommentsByParentDefId.get(parentDefId).add(response);
                    }
                }
            }

            if (parentNonCompliant.isEmpty()) {
                result.success = true;
                result.message = 'No non-compliant questions found';
                return result;
            }

            // Get regulatory codes for all assessment indicator definitions
            Set<Id> definitionIds = new Set<Id>();
            for (InspectionAssessmentInd response : parentNonCompliant) {
                if (response.AssessmentIndDefinitionId != null) {
                    definitionIds.add(response.AssessmentIndDefinitionId);
                }
            }
            // Also add child definition IDs
            for (List<InspectionAssessmentInd> children : selectedCannedCommentsByParentDefId.values()) {
                for (InspectionAssessmentInd child : children) {
                    if (child.AssessmentIndDefinitionId != null) {
                        definitionIds.add(child.AssessmentIndDefinitionId);
                    }
                }
            }

            // Map of definition ID to regulatory code ID
            Map<Id, Id> defToRegCodeId = new Map<Id, Id>();
            if (!definitionIds.isEmpty()) {
                List<RegulatoryCodeAssessmentInd> regCodeLinks = [
                    SELECT AssessmentIndDefinitionId, RegulatoryCodeId
                    FROM RegulatoryCodeAssessmentInd
                    WHERE AssessmentIndDefinitionId IN :definitionIds
                    WITH SECURITY_ENFORCED
                ];

                for (RegulatoryCodeAssessmentInd link : regCodeLinks) {
                    // Use first regulatory code found for each definition
                    if (!defToRegCodeId.containsKey(link.AssessmentIndDefinitionId)) {
                        defToRegCodeId.put(link.AssessmentIndDefinitionId, link.RegulatoryCodeId);
                    }
                }
            }

            // Create parent violations first
            List<RegulatoryCodeViolation> parentViolationsToInsert = new List<RegulatoryCodeViolation>();
            Map<Id, InspectionAssessmentInd> defIdToParentResponse = new Map<Id, InspectionAssessmentInd>();
            
            for (InspectionAssessmentInd response : parentNonCompliant) {
                RegulatoryCodeViolation parentViolation = createViolationRecord(
                    visitId,
                    visitRecord.AccountId,
                    response,
                    defToRegCodeId.get(response.AssessmentIndDefinitionId),
                    null // No parent violation for parent questions
                );
                parentViolationsToInsert.add(parentViolation);
                defIdToParentResponse.put(response.AssessmentIndDefinitionId, response);
            }

            // Insert parent violations
            if (!parentViolationsToInsert.isEmpty()) {
                if (!Schema.sObjectType.RegulatoryCodeViolation.isCreateable()) {
                    throw new AuraHandledException('Insufficient permissions to create RegulatoryCodeViolation records');
                }

                Database.SaveResult[] parentResults = Database.insert(parentViolationsToInsert, false);
                
                // Build map of parent definition ID to created violation ID
                Map<Id, Id> parentDefIdToViolationId = new Map<Id, Id>();
                Integer parentIndex = 0;
                
                for (InspectionAssessmentInd response : parentNonCompliant) {
                    if (parentIndex < parentResults.size() && parentResults[parentIndex].isSuccess()) {
                        Id violationId = parentResults[parentIndex].getId();
                        result.violationIds.add(violationId);
                        result.parentViolationIds.add(violationId);
                        parentDefIdToViolationId.put(response.AssessmentIndDefinitionId, violationId);
                    } else {
                        for (Database.Error err : parentResults[parentIndex].getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'Error creating parent violation: ' + err.getMessage());
                            result.failedViolations.add('Parent: ' + err.getMessage());
                        }
                    }
                    parentIndex++;
                }

                // Now create canned comment violations with parent violation link
                List<RegulatoryCodeViolation> cannedCommentViolationsToInsert = new List<RegulatoryCodeViolation>();
                
                for (Id parentDefId : selectedCannedCommentsByParentDefId.keySet()) {
                    Id parentViolationId = parentDefIdToViolationId.get(parentDefId);
                    
                    // Only create canned comment violations if parent violation was created
                    if (parentViolationId != null) {
                        List<InspectionAssessmentInd> cannedComments = selectedCannedCommentsByParentDefId.get(parentDefId);
                        
                        for (InspectionAssessmentInd cannedComment : cannedComments) {
                            RegulatoryCodeViolation childViolation = createViolationRecord(
                                visitId,
                                visitRecord.AccountId,
                                cannedComment,
                                defToRegCodeId.get(cannedComment.AssessmentIndDefinitionId),
                                parentViolationId // Link to parent violation
                            );
                            cannedCommentViolationsToInsert.add(childViolation);
                        }
                    }
                }

                // Insert canned comment violations
                if (!cannedCommentViolationsToInsert.isEmpty()) {
                    // CRUD check for child violations
                    if (!Schema.sObjectType.RegulatoryCodeViolation.isCreateable()) {
                        throw new AuraHandledException('Insufficient permissions to create RegulatoryCodeViolation records');
                    }
                    
                    Database.SaveResult[] childResults = Database.insert(cannedCommentViolationsToInsert, false);
                    
                    for (Integer i = 0; i < childResults.size(); i++) {
                        if (childResults[i].isSuccess()) {
                            result.violationIds.add(childResults[i].getId());
                            result.cannedCommentViolationIds.add(childResults[i].getId());
                        } else {
                            for (Database.Error err : childResults[i].getErrors()) {
                                System.debug(LoggingLevel.ERROR, 'Error creating canned comment violation: ' + err.getMessage());
                                result.failedViolations.add('Canned comment: ' + err.getMessage());
                            }
                        }
                    }
                }
            }

            result.success = true;
            result.violationCount = result.violationIds.size();
            result.message = 'Successfully created ' + result.parentViolationIds.size() + ' violation(s)';

        } catch (Exception ex) {
            LogService.logAndPublish(className, 'createViolationsForInspection', String.valueOf(visitId), ex);
            result.success = false;
            result.message = 'Error creating violations: ' + ex.getMessage();
            throw new AuraHandledException(result.message);
        }

        return result;
    }

    /**
     * @description Creates a RegulatoryCodeViolation record with the specified field mappings
     * @param visitId The Inspection (Visit) ID
     * @param accountId The Account ID
     * @param assessmentInd The InspectionAssessmentInd record
     * @param regulatoryCodeId The Regulatory Code ID (can be null)
     * @param parentViolationId The Parent Violation ID for canned comments (can be null for parent questions)
     * @return RegulatoryCodeViolation record ready for insert
     */
    private static RegulatoryCodeViolation createViolationRecord(Id visitId, Id accountId, InspectionAssessmentInd assessmentInd, Id regulatoryCodeId, Id parentViolationId) {
        RegulatoryCodeViolation newViolation = new RegulatoryCodeViolation();
        
        // Required field mappings per user story
        // InspectionId: Lookup to Visit (Inspection)
        newViolation.InspectionId = visitId;
        
        // PHOCSParentAccountID__c: Account relationship
        newViolation.PHOCSParentAccountID__c = accountId;
        
        // InspectionAssmntIndId: Lookup to InspectionAssessmentInd
        newViolation.InspectionAssmntIndId = assessmentInd.Id;
        
        // RegulatoryCodeId: Regulatory Code (from Assessment Indicator Definition)
        if (regulatoryCodeId != null) {
            newViolation.RegulatoryCodeId = regulatoryCodeId;
        }
        
        // PHOCSParentId__c: Parent Violation (for canned comment violations)
        if (parentViolationId != null) {
            newViolation.PHOCSParentId__c = parentViolationId;
        }
        	newViolation.DateCreated = System.now();
        
        // Set description with violation info and comments
        String violationName = assessmentInd.AssessmentIndDefinition != null 
            ? assessmentInd.AssessmentIndDefinition.Name 
            : 'Inspection Violation';
        String description = violationName + ' - Non-compliant finding from inspection.';
        if (String.isNotBlank(assessmentInd.PHOCSInspectionComments__c)) {
            description += '\n\nInspector Comments: ' + assessmentInd.PHOCSInspectionComments__c;
        }
        newViolation.Description = description;
        
        // Set status
        newViolation.Status = 'Open';
        
        return newViolation;
    }
    
/**
* @author: Deepak
* @date: 19 Jan 2026
* @description: The purpose of this method is to Create Violations for PHOCS InspectionAssessmentInd records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled
    public static ViolationResult createRegulatoryCodeViolationsForInspection(Id visitId) {
        ViolationResult result = new ViolationResult();
        
        if (visitId == null) {
            result.success = false;
            result.message = 'Visit ID is required';
            return result;
        }
        
        try {            
            // Get all InspectionAssessmentInd records for this visit with their definitions
            // Including both parent (non-compliant) and child (selected canned comments) records
            List<InspectionAssessmentInd> allResponses = [SELECT Id, RecordTypeId, AssessmentTaskId, AssessmentTask.Name, AssessmentTask.ParentId, AssessmentIndDefinitionId,
                AssessmentIndDefinition.Name, AssessmentIndDefinition.PHOCSParentId__c, Result, PHOCSInspectionComments__c,CorrectedDuringInspection__c,
                PHOCSCheckboxResponse__c FROM InspectionAssessmentInd WHERE AssessmentTask.ParentId = :visitId WITH SECURITY_ENFORCED];
            
            if (allResponses.isEmpty()) {
                result.success = true;
                result.message = 'No assessment responses found';
                return result;
            }
            List<InspectionAssessmentInd> filteredInsAsmntIndList = new List<InspectionAssessmentInd>();
            Set<Id> assessmentIndDefIds = new Set<Id>();
            Set<Id> assessmentTaskIds = new Set<Id>();
            Map<Id, List<RegulatoryCodeAssessmentInd>> regMap = new Map<Id, List<RegulatoryCodeAssessmentInd>>();
            
            for (InspectionAssessmentInd ind : allResponses) {
                if(ind.RecordTypeId == recordTypePHOCSInspectionAssessmentInd && ind.Result == RESULT_NON_COMPLIANT && ind.AssessmentIndDefinitionId != null && ind.AssessmentTaskId != null){
                    filteredInsAsmntIndList.add(ind);
                    assessmentIndDefIds.add(ind.AssessmentIndDefinitionId);
                    assessmentTaskIds.add(ind.AssessmentTaskId);
                }
            }
            
            if (filteredInsAsmntIndList.isEmpty()){
                result.success = true;
                result.message = 'No non-compliant assessment indicators found';
                return result;
            }
            
            Map<Id, AssessmentTask> taskMap = new Map<Id, AssessmentTask>([SELECT Id, ParentId, Parent.AccountId FROM AssessmentTask WHERE Id IN :assessmentTaskIds]);           
            
            List<RegulatoryCodeAssessmentInd> regCodeAsmntList = [SELECT Id, AssessmentIndDefinitionId, RegulatoryCodeId FROM RegulatoryCodeAssessmentInd WHERE AssessmentIndDefinitionId IN :assessmentIndDefIds];
            
            for (RegulatoryCodeAssessmentInd rca : regCodeAsmntList) {
                if (!regMap.containsKey(rca.AssessmentIndDefinitionId)) {
                    regMap.put(rca.AssessmentIndDefinitionId, new List<RegulatoryCodeAssessmentInd>());
                }
                regMap.get(rca.AssessmentIndDefinitionId).add(rca);
            }
            
            List<RegulatoryCodeViolation> violationsToInsert = new List<RegulatoryCodeViolation>();
            List<InspectionAssessmentInd> violationSourceInds = new List<InspectionAssessmentInd>();
            
            for (InspectionAssessmentInd ind : filteredInsAsmntIndList) {
                List<RegulatoryCodeAssessmentInd> mappings = regMap.get(ind.AssessmentIndDefinitionId);
                if (mappings == null){
                    continue;
                }
                Id inspectionId = taskMap.get(ind.AssessmentTaskId)?.ParentId;
                Id inspectionAccountId = taskMap.get(ind.AssessmentTaskId)?.Parent?.AccountId;
                
                for (RegulatoryCodeAssessmentInd mapItem : mappings) {
                    RegulatoryCodeViolation vio = new RegulatoryCodeViolation();
                    vio.RecordTypeId = recordTypePHOCSRegulatoryCodeViolation;
                    vio.InspectionAssmntIndId = ind.Id;
                    vio.InspectionId = inspectionId;
                    vio.PHOCSParentAccountID__c = inspectionAccountId;
                    vio.DateCreated = System.now();
                    vio.RegulatoryCodeId = mapItem.RegulatoryCodeId;
                    vio.Corrected_During_Inspection__c = ind.CorrectedDuringInspection__c;
                    vio.Status = 'Open'; //ind.CorrectedDuringInspection__c == true ? 'Resolved' :'Open';
                    
                    violationsToInsert.add(vio);
                    violationSourceInds.add(ind);
                }
            }
            
            if (violationsToInsert.isEmpty()) {
                result.success = true;
                result.message = 'No violations to create';
                return result;
            }
            
            if (!Schema.sObjectType.RegulatoryCodeViolation.isCreateable()) {
                throw new AuraHandledException('Insufficient permissions to create violations');
            }
            
            Database.SaveResult[] srList = Database.insert(violationsToInsert, false);
            
            for (Integer i = 0; i < srList.size(); i++) {
                if (srList[i].isSuccess()) {
                    Id vioId = srList[i].getId();
                    result.violationIds.add(vioId);
                    
                    InspectionAssessmentInd ind = violationSourceInds[i];
                    if (ind.AssessmentIndDefinition.PHOCSParentId__c == null) {
                        result.parentViolationIds.add(vioId);
                    } else {
                        result.cannedCommentViolationIds.add(vioId);
                    }
                } else {
                    for (Database.Error err : srList[i].getErrors()) {
                        result.failedViolations.add(err.getMessage());
                    }
                }
            }
            
            result.success = result.failedViolations.isEmpty();
            result.violationCount = result.violationIds.size();
            result.message = 'Created ' + result.violationCount + ' violation(s).';
            
        } catch (Exception ex) {
            LogService.logAndPublish(className, 'createRegulatoryCodeViolations', String.valueOf(visitId), ex);
            result.success = false;
            result.message = ex.getMessage();
        }        
        return result;
    }    

    /**
     * @description Wrapper class for violation creation result
     */
    public class ViolationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public List<Id> violationIds { get; set; }
        @AuraEnabled public List<Id> parentViolationIds { get; set; }
        @AuraEnabled public List<Id> cannedCommentViolationIds { get; set; }
        @AuraEnabled public Integer violationCount { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<String> failedViolations { get; set; }

        public ViolationResult() {
            this.success = false;
            this.violationIds = new List<Id>();
            this.parentViolationIds = new List<Id>();
            this.cannedCommentViolationIds = new List<Id>();
            this.violationCount = 0;
            this.message = '';
            this.failedViolations = new List<String>();
        }
    }
}
