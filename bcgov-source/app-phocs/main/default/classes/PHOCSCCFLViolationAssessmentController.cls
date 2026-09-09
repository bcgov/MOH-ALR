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
* @date 2026-08-31
* @description Retrieves the latest completed Risk Assessment for the supplied Facility and
*                 returns the open top-level Regulatory Code Violations for the supplied Inspection.
*                 When a current violation's Assessment Indicator/Task combination matches a violation
*                 from the completed Assessment, the completed violation's own data is displayed
*                 (with Scope/Severity prepopulated and selected = true) instead of the current
*                 violation. Unmatched slots fall back to displaying the current violation as-is.
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
            List<Assessment> assessments = [SELECT Id, ResponseContextId, AccountId, Type, AssessmentStatus, CreatedDate FROM Assessment
                                            WHERE AccountId = :facilityId AND RecordTypeId = :ASSESSMENT_RTID AND Type = 'Risk Assessment'
                                            AND AssessmentStatus = 'Completed' ORDER BY CreatedDate DESC LIMIT 1];
            
            if (assessments.isEmpty()) {
                return response;
            }
            
            response.hasCompletedAssessment = true;
            response.completedAssessmentId = assessments[0].Id;
            
            Id responseContextId = assessments[0].ResponseContextId;
            
            Map<String, RegulatoryCodeViolation> completedViolationMap = new Map<String, RegulatoryCodeViolation>();
            
            if (responseContextId != null) {
                List<RegulatoryCodeViolation> completedViolations = [SELECT Id, RegulatoryCode.Name, RegulatoryCode.Description, Name, Scope__c, Severity__c,
                                                                     InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.Name,
                                                                     InspectionAssmntInd.AssessmentTaskId, InspectionAssmntInd.AssessmentTask.Name,
                                                                     InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId FROM RegulatoryCodeViolation
                                                                     WHERE InspectionId = :responseContextId AND IsChildViolation__c = false AND Status = 'Open'
                                                                     AND InspectionAssmntInd.AssessmentTask.Name != 'Operating or advertising without a licence'];
                
                for (RegulatoryCodeViolation violation : completedViolations) {
                    if (violation.InspectionAssmntInd == null || violation.InspectionAssmntInd.AssessmentIndDefinitionId == null || violation.InspectionAssmntInd.AssessmentTask == null || violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId == null) {
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
                
                if (violation.InspectionAssmntInd != null && violation.InspectionAssmntInd.AssessmentIndDefinitionId != null && violation.InspectionAssmntInd.AssessmentTask != null && violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId != null) {
                    violationKey = buildViolationKey(violation.InspectionAssmntInd.AssessmentIndDefinitionId, violation.InspectionAssmntInd.AssessmentTask.AssessmentTaskDefinitionId);
                }
                
                if (violationKey != null && completedViolationMap.containsKey(violationKey)) {
                    RegulatoryCodeViolation previousViolation = completedViolationMap.get(violationKey);
                    ViolationWrapper wrapper = new ViolationWrapper(previousViolation);
                    wrapper.selected = previousViolation.Scope__c != null && previousViolation.Severity__c != null;
                    response.violations.add(wrapper);
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