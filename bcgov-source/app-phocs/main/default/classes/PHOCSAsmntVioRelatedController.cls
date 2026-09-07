/**********************************************************************************************
* @Author:      Accenture
* @Date:        25 Aug 2026
* @Description: Controller for displaying Regulatory Code Violations related to an Assessment.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
**********************************************************************************************/
public with sharing class PHOCSAsmntVioRelatedController {
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Retrieves the selected Regulatory Code Violations stored against the Assessment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled(cacheable=true)
    public static RelatedViolationsResponse getRelatedViolations(Id assessmentId) {
        RelatedViolationsResponse response = new RelatedViolationsResponse();
        response.violations = new List<ViolationWrapper>();
        response.isRiskReAssessment = false;
        
        if (assessmentId == null) {
            return response;
        }
        
        List<Assessment> assessments = [SELECT Id, ResponseContextId, SelectedViolationsJSON__c, Type FROM Assessment WHERE Id = :assessmentId LIMIT 1];
        
        if (assessments.isEmpty()) {
            return response;
        }
        
        Assessment assessment = assessments[0];
        response.isRiskReAssessment = assessment.Type == 'Risk Re-assessment';
        
        if (String.isBlank(assessment.SelectedViolationsJSON__c)) {
            return response;
        }
        
        List<Object> selectedViolations = (List<Object>) JSON.deserializeUntyped(assessment.SelectedViolationsJSON__c);
        Set<Id> violationIds = new Set<Id>();
        
        for (Object selectedViolationObject : selectedViolations) {
            Map<String, Object> selectedViolation = (Map<String, Object>) selectedViolationObject;
            
            if (!selectedViolation.containsKey('violationId') || selectedViolation.get('violationId') == null) {
                continue;
            }
            
            try {
                violationIds.add(Id.valueOf(String.valueOf(selectedViolation.get('violationId'))));
            } catch (Exception ex) {
                continue;
            }
        }
        
        if (violationIds.isEmpty()) {
            return response;
        }
        
        Map<Id, RegulatoryCodeViolation> violationMap = new Map<Id, RegulatoryCodeViolation>([SELECT Id, Name, RegulatoryCode.Name, 
                                                                                              InspectionAssmntInd.AssessmentIndDefinition.Name 
                                                                                              FROM RegulatoryCodeViolation WHERE Id IN :violationIds]);
        
        for (Object selectedViolationObject : selectedViolations) {
            Map<String, Object> selectedViolation = (Map<String, Object>) selectedViolationObject;
            
            if (!selectedViolation.containsKey('violationId') || selectedViolation.get('violationId') == null) {
                continue;
            }
            
            Id violationId;
            
            try {
                violationId = Id.valueOf(String.valueOf(selectedViolation.get('violationId')));
            } catch (Exception ex) {
                continue;
            }
            
            RegulatoryCodeViolation violation = violationMap.get(violationId);
            
            if (violation != null) {
                response.violations.add(new ViolationWrapper(violation, selectedViolation));
            }
        }
        
        return response;
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Wrapper containing selected violation data and Assessment Type information.
*/
    public class RelatedViolationsResponse {
        @AuraEnabled
        public List<ViolationWrapper> violations { get; set; }        
        @AuraEnabled
        public Boolean isRiskReAssessment { get; set; }
    }
    
    /**
* @description: Lightweight wrapper exposing selected violation data to the LWC layer.
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
        public String inspectionQuestion;        
        @AuraEnabled
        public String scope;        
        @AuraEnabled
        public String severity;        
        @AuraEnabled
        public String comment;
        
        public ViolationWrapper(RegulatoryCodeViolation violation, Map<String, Object> selectedViolation) {
            id = violation.Id;
            violationName = violation.Name;
            category = getStringValue(selectedViolation, 'category');
            regulatoryCode = getStringValue(selectedViolation, 'regulatoryCode');
            inspectionQuestion = getStringValue(selectedViolation, 'inspectionQuestion');
            scope = getStringValue(selectedViolation, 'scope');
            severity = getStringValue(selectedViolation, 'severity');
            comment = getStringValue(selectedViolation, 'comments');
        }
    }
    
    private static String getStringValue(Map<String, Object> values, String key) {
        if (values == null || !values.containsKey(key) || values.get(key) == null) {
            return null;
        }
        
        return String.valueOf(values.get(key));
    }
}