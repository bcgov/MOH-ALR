/**********************************************************************************************
* @Author: Accenture
* @Date: 2026-08-24
* @Description: The purpose of this Controller supporting the CCFL Violation Assessment LWC. Retrieves
*                top-level (non-child) Regulatory Code Violation records for a given Inspection, for
*                display in a category-grouped violation list.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                21 Aug -  PHOCS-4817        -  Accenture   -  supporting the CCFL Violation Assessment LWC
                24 Aug -  PHOCS-271         -  Deepak      -  removed parentAssessmentDefId param, filter on IsChildViolation__c = false.
                31 Aug -  PHOCS-271         -  Deepak      -  matched violations now display the completed violation's own data instead of overlaying scope/severity onto the current violation.
                31 Aug -  PHOCS-271         -  Deepak      -  completedViolations query no longer filters on Scope/Severity; selected is now true only when the matched violation has both populated.
                03 Sep -  PHOCS-271         -  Deepak      -  getReassessmentViolations restores the composite-key match against the completed Inspection's violations to find the parent violation, then layers Assessment.SelectedViolationsJSON__c on top: first matching the parent violation's Id as violationId in the saved JSON, falling back to a category/inspectionQuestion text match against the current violation's Assessment Task/Indicator Definition names, and falling back to the plain current violation if neither JSON match is found.
***********************************************************************************************/
public with sharing class PHOCSCCFLViolationAssessmentController {
    public static final Id ASSESSMENT_RTID = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
    
    /**
* @author Deepak
* @date 2026-08-24
* @description Retrieves top-level (non-child) Regulatory Code Violations for the
*                 given Inspection, for display in a category-grouped violation list.
* @param inspectionId Id of the Inspection record to filter violations by. Required.
* @return  List<ViolationWrapper> wrapped violation data for LWC consumption.
*/
    @AuraEnabled(cacheable=true)
    public static List<ViolationWrapper> getViolations(Id inspectionId) {
        try {
            if (inspectionId == null) {
                throwError('Inspection Id is required.');
            }
            
            List<RegulatoryCodeViolation> violations = [SELECT Id, RegulatoryCode.Name, RegulatoryCode.Description, Name, Scope__c, Severity__c,
                                                        InspectionAssmntInd.AssessmentIndDefinition.Name, InspectionAssmntInd.AssessmentTask.Name
                                                        FROM RegulatoryCodeViolation WHERE InspectionId = :inspectionId AND Status = 'Open' 
                                                        AND IsChildViolation__c = false AND InspectionAssmntInd.AssessmentTask.Name != 'Operating or advertising without a licence'];
            
            List<ViolationWrapper> results = new List<ViolationWrapper>();
            
            for (RegulatoryCodeViolation violation : violations) {
                results.add(new ViolationWrapper(violation));
            }            
            return results;
            
        } catch (Exception ex) {
            throwError(ex.getMessage());
            return new List<ViolationWrapper>();
        }
    }
    
    /**
* @author Deepak
* @date 2026-09-03
* @description Retrieves the latest completed Risk Assessment for the supplied Facility and
*                 returns the open top-level Regulatory Code Violations for the supplied Inspection.
*                 A current violation is first matched to a parent violation on the completed
*                 Inspection via a composite AssessmentIndDefinitionId/AssessmentTaskDefinitionId
*                 key. If a parent violation is found, its own data is displayed (per the
*                 established pattern), and its Scope/Severity/Comment are prepopulated from the
*                 completed Assessment's SelectedViolationsJSON__c: first by looking up the
*                 parent violation's Id as violationId in the saved JSON, then, if that misses,
*                 by matching a JSON entry's category/inspectionQuestion against the current
*                 violation's Assessment Task/Indicator Definition names. If neither JSON match
*                 is found, or the composite key itself never matched, the current violation is
*                 returned as-is with no prepopulation.
* @param inspectionId Id of the current Inspection record.
* @param facilityId Id of the Facility associated with the Assessment.
* @return  ReassessmentResponse containing Assessment status, completed Assessment and violation data.
*/
    @AuraEnabled(cacheable=true)
    public static ReassessmentResponse getReassessmentViolations(Id inspectionId, Id facilityId) {
        try {
            if (inspectionId == null) {
                throwError('Inspection Id is required.');
            }
            
            ReassessmentResponse response = new ReassessmentResponse();
            response.hasCompletedAssessment = false;
            response.completedAssessmentId = null;
            response.violations = new List<ViolationWrapper>();            
            List<Assessment> assessments = [SELECT Id, ResponseContextId, AccountId, Type, AssessmentStatus, CreatedDate, SelectedViolationsJSON__c FROM Assessment
                                            WHERE AccountId = :facilityId AND RecordTypeId = :ASSESSMENT_RTID AND Type = 'Risk Assessment'
                                            AND AssessmentStatus = 'Completed' ORDER BY CreatedDate DESC LIMIT 1];
            
            if (assessments.isEmpty()) {
                return response;
            }
            
            response.hasCompletedAssessment = true;
            response.completedAssessmentId = assessments[0].Id;
            
            Id responseContextId = assessments[0].ResponseContextId;
            List<Map<String, Object>> savedViolations = parseSelectedViolationsJson(assessments[0].SelectedViolationsJSON__c);
            Map<String, Map<String, Object>> savedViolationsByViolationId = new Map<String, Map<String, Object>>();
            
            for (Map<String, Object> savedViolation : savedViolations) {
                Object violationIdObj = savedViolation.get('violationId');
                
                if (violationIdObj != null) {
                    savedViolationsByViolationId.put(String.valueOf(violationIdObj), savedViolation);
                }
            }
            
            Map<String, RegulatoryCodeViolation> completedViolationMap = new Map<String, RegulatoryCodeViolation>();
            
            if (responseContextId != null) {
                List<RegulatoryCodeViolation> completedViolations = [SELECT Id, RegulatoryCode.Name, RegulatoryCode.Description, Name, Scope__c, Severity__c,
                                                                     InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.Name,
                                                                     InspectionAssmntInd.AssessmentTaskId, InspectionAssmntInd.AssessmentTask.Name,
                                                                     InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId FROM RegulatoryCodeViolation
                                                                     WHERE InspectionId = :responseContextId AND IsChildViolation__c = false AND Status = 'Open'
                                                                     AND InspectionAssmntInd.AssessmentTask.Name != 'Operating or advertising without a licence'];
                
                for (RegulatoryCodeViolation violation : completedViolations) {
                    if (violation.InspectionAssmntInd == null || violation.InspectionAssmntInd.AssessmentIndDefinitionId == null ||
                        violation.InspectionAssmntInd.AssessmentTask == null || violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId == null) {
                        continue;
                    }                    
                    String violationKey = buildViolationKey(violation.InspectionAssmntInd.AssessmentIndDefinitionId, violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId);
                    completedViolationMap.put(violationKey, violation);
                }
            }
            
            List<RegulatoryCodeViolation> violations = [SELECT Id, RegulatoryCode.Name, RegulatoryCode.Description, Name, InspectionId, Scope__c, Severity__c,
                                                        InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.Name,
                                                        InspectionAssmntInd.AssessmentTaskId, InspectionAssmntInd.AssessmentTask.Name, 
                                                        InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId FROM RegulatoryCodeViolation 
                                                        WHERE InspectionId = :inspectionId AND Status = 'Open' AND IsChildViolation__c = false 
                                                        AND InspectionAssmntInd.AssessmentTask.Name != 'Operating or advertising without a licence'];
            
            for (RegulatoryCodeViolation violation : violations) {
                String violationKey = null;
                
                if (violation.InspectionAssmntInd != null && violation.InspectionAssmntInd.AssessmentIndDefinitionId != null &&
                    violation.InspectionAssmntInd.AssessmentTask != null && violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId != null) {
                    violationKey = buildViolationKey(violation.InspectionAssmntInd.AssessmentIndDefinitionId, violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId);
                }
                
                if (violationKey != null && completedViolationMap.containsKey(violationKey)) {
                    RegulatoryCodeViolation previousViolation = completedViolationMap.get(violationKey);
                    
                    Map<String, Object> jsonMatch = savedViolationsByViolationId.get(String.valueOf(previousViolation.Id));
                    
                    if (jsonMatch == null) {
                        String currentTaskName = violation.InspectionAssmntInd?.AssessmentTask?.Name;
                        String currentIndicatorName = violation.InspectionAssmntInd?.AssessmentIndDefinition?.Name;
                        jsonMatch = findSavedViolationByCategoryAndQuestion(savedViolations, currentTaskName, currentIndicatorName);
                    }
                    
                    if (jsonMatch != null) {
                        ViolationWrapper wrapper = new ViolationWrapper(previousViolation);
                        Object scopeObj = jsonMatch.get('scope');
                        Object severityObj = jsonMatch.get('severity');
                        Object commentObj = jsonMatch.containsKey('comments') ? jsonMatch.get('comments') : jsonMatch.get('comment');
                        
                        wrapper.scope = scopeObj == null ? null : String.valueOf(scopeObj);
                        wrapper.severity = severityObj == null ? null : String.valueOf(severityObj);
                        wrapper.comment = commentObj == null ? null : String.valueOf(commentObj);
                        wrapper.selected = wrapper.scope != null && wrapper.severity != null;
                        
                        response.violations.add(wrapper);
                    } else {
                        response.violations.add(new ViolationWrapper(violation));
                    }
                } else {
                    response.violations.add(new ViolationWrapper(violation));
                }
            }            
            return response;
            
        } catch (Exception ex) {
            throwError(ex.getMessage());
            return new ReassessmentResponse();
        }
    }
    
    /**
* @author Deepak
* @date 2026-09-03
* @description Deserializes the SelectedViolationsJSON__c JSON array into a list of maps.
*                 Returns an empty list for a blank or malformed JSON string, and skips any
*                 array entry that is not a JSON object.
* @param selectedViolationsJson The raw JSON string from Assessment.SelectedViolationsJSON__c.
* @return  List of saved violation data maps.
*/
    private static List<Map<String, Object>> parseSelectedViolationsJson(String selectedViolationsJson) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        if (String.isBlank(selectedViolationsJson)) {
            return result;
        }
        
        List<Object> parsed;
        try {
            parsed = (List<Object>) JSON.deserializeUntyped(selectedViolationsJson);
        } catch (Exception ex) {
            return result;
        }
        
        for (Object entry : parsed) {
            if (entry instanceof Map<String, Object>) {
                result.add((Map<String, Object>) entry);
            }
        }
        
        return result;
    }
    
    /**
* @author Deepak
* @date 2026-09-03
* @description Fallback lookup used when a saved violation cannot be matched by violationId -
*                 finds the first saved violation entry whose category and inspectionQuestion
*                 both match the supplied Assessment Task name and Assessment Indicator
*                 Definition name.
* @param savedViolations The parsed list of saved violation data maps.
* @param taskName The current violation's InspectionAssmntInd.AssessmentTask.Name.
* @param indicatorName The current violation's InspectionAssmntInd.AssessmentIndDefinition.Name.
* @return  The matching saved violation data map, or null if none matches.
*/
    private static Map<String, Object> findSavedViolationByCategoryAndQuestion(List<Map<String, Object>> savedViolations, String taskName, String indicatorName) {
        if (String.isBlank(taskName) || String.isBlank(indicatorName)) {
            return null;
        }
        
        for (Map<String, Object> savedViolation : savedViolations) {
            Object categoryObj = savedViolation.get('category');
            Object inspectionQuestionObj = savedViolation.get('inspectionQuestion');
            
            String category = categoryObj == null ? null : String.valueOf(categoryObj);
            String inspectionQuestion = inspectionQuestionObj == null ? null : String.valueOf(inspectionQuestionObj);
            
            if (taskName.equals(category) && indicatorName.equals(inspectionQuestion)) {
                return savedViolation;
            }
        }
        
        return null;
    }
    
    /**
* @author Deepak
* @date 2026-08-31
* @description Builds a unique key for matching violations between the completed Assessment
*                 Inspection and the current Inspection.
* @param assessmentIndDefinitionId Assessment Indicator Definition Id.
* @param assessmentTaskDefinitionId Assessment Task Definition Id.
* @return  Composite key used for violation matching.
*/
    private static String buildViolationKey(Id assessmentIndDefinitionId, Id assessmentTaskDefinitionId) {
        if (assessmentIndDefinitionId == null || assessmentTaskDefinitionId == null) {
            return null;
        }        
        return String.valueOf(assessmentIndDefinitionId) + '_' + String.valueOf(assessmentTaskDefinitionId);
    }
    
    /**
* @author Deepak
* @date 2026-08-24
* @description Throws an AuraHandledException with a client-visible message.
* @param message Error message to surface to the calling LWC.
*/
    private static void throwError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        throw ex;
    }
    
    /**
* @description Response wrapper containing completed Assessment status, completed Assessment and violation data.
*/
    public class ReassessmentResponse {
        @AuraEnabled
        public Boolean hasCompletedAssessment;        
        @AuraEnabled
        public String completedAssessmentId;        
        @AuraEnabled
        public List<ViolationWrapper> violations;
    }
    
    /**
* @description Lightweight wrapper exposing violation data to the LWC layer.
*/
    public class ViolationWrapper {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String violationName;
        @AuraEnabled
        public String category;
        @AuraEnabled
        public String regulatoryCode;
        @AuraEnabled
        public String regulatoryCodeDescription;
        @AuraEnabled
        public String inspectionQuestion;
        @AuraEnabled
        public Boolean selected;
        @AuraEnabled
        public String scope;
        @AuraEnabled
        public String severity;
        @AuraEnabled
        public String comment;
        
        public ViolationWrapper(RegulatoryCodeViolation violation) {
            id = violation.Id;
            violationName = violation.Name;
            category = violation.InspectionAssmntInd?.AssessmentTask?.Name;
            regulatoryCode = violation.RegulatoryCode?.Name;
            regulatoryCodeDescription = violation.RegulatoryCode?.Description;
            inspectionQuestion = violation.InspectionAssmntInd?.AssessmentIndDefinition?.Name;
            selected = false;
            scope = violation.Scope__c;
            severity = violation.Severity__c;
            comment = null;
        }
    }
}