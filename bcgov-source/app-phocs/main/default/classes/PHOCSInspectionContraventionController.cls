global without sharing class PHOCSInspectionContraventionController {
    
    @AuraEnabled(cacheable=true)
    public static List<ViolationWrapper> getRegulatoryViolations(Id caseId) {
        
        List<ViolationWrapper> results = new List<ViolationWrapper>();
        
        if (caseId == null) {
            return results;
        }
        
        Case caseRecord = [
            SELECT Id, RecordType.DeveloperName
            FROM Case
            WHERE Id = :caseId
            LIMIT 1
        ];
        
        if (caseRecord.RecordType.DeveloperName != 'PHOCSComplaint') {
            return results;
        }
        // Get completed inspections for the Case
        Set<Id> inspectionIds = new Set<Id>();
        
        for (Visit inspectionRecord : [
            SELECT Id
            FROM Visit
            WHERE ContextId = :caseId
            AND Status = 'Completed'
            AND VisitType.Name IN ('Complaint', 'Complaint Follow-up')
            AND IsRetracted__c = false
        ]) {
            inspectionIds.add(inspectionRecord.Id);
        }
        
        
        
        if (inspectionIds.isEmpty()) {
            return results;
        }
        
        // Get Regulatory Code Violations
        List<RegulatoryCodeViolation> violations = [
            SELECT Id,
            PHOCSAssessmentIndicatorDefinition__c,
            InspectionAssmntInd.Result,
            InspectionAssmntInd.CorrectiveActionDescription__c,
            RegulatoryCode.Name,
            RegulatoryCode.RegulatoryAuthority.Name,
            InspectionAssmntInd.PHOCSInspectionComments__c,
            PHOCSAssessmentIndDefinitionId__c,
            IsChildViolation__c,
            Corrected_During_Inspection__c,
            InspectionAssmntInd.AssessmentIndDefinitionId,
            InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c
            FROM RegulatoryCodeViolation
            WHERE inspectionid IN :inspectionIds
            AND Corrected_During_Inspection__c = false
            AND PHOCSParentId__c = null
            ORDER BY CreatedDate ASC
        ];
        
        if (violations.isEmpty()) {
            return results;
        }
        
        
        // Map Parent Assessment Indicator Definition Id to wrapper
        Map<Id, ViolationWrapper> parentWrappersByDefinitionId = new Map<Id, ViolationWrapper>();
        
        // Create all PARENT wrappers
        for (RegulatoryCodeViolation violation : violations) {
            if (violation.IsChildViolation__c == true) {
                continue;
            }
            
            ViolationWrapper wrapper = new ViolationWrapper();
            
            wrapper.violationId =
                violation.Id;
            
            wrapper.PHOCSAssessmentIndicatorDefinition =
                violation.PHOCSAssessmentIndicatorDefinition__c;
            
            wrapper.result =
                violation.InspectionAssmntInd.PHOCSInspectionComments__c;
            
            wrapper.actionDescription =
                violation.InspectionAssmntInd.CorrectiveActionDescription__c;
            
            wrapper.RegCode =
                violation.RegulatoryCode.Name;
            
            wrapper.RegAuthority =
                violation.RegulatoryCode.RegulatoryAuthority.Name;
            
            // Add parent to results
            results.add(wrapper);
            
            // Store parent using its Assessment Indicator Definition Id
            if (
                violation.InspectionAssmntInd.AssessmentIndDefinitionId != null
            ) {
                parentWrappersByDefinitionId.put(
                    violation.InspectionAssmntInd.AssessmentIndDefinitionId,
                    wrapper
                );
            }
        }
        
        // Add CHILD questions to parent
        
        for (RegulatoryCodeViolation violation : violations) {
            if (violation.IsChildViolation__c != true) {
                continue;
            }
            
            String childQuestion =
                violation.PHOCSAssessmentIndicatorDefinition__c;
            
            Id parentDefinitionId =
                violation.InspectionAssmntInd
                .AssessmentIndDefinition
                .PHOCSParentId__c;
            
            if (
                parentDefinitionId != null &&
                String.isNotBlank(childQuestion) &&
                parentWrappersByDefinitionId.containsKey(parentDefinitionId)
            ) {
                
                ViolationWrapper parentWrapper =
                    parentWrappersByDefinitionId.get(parentDefinitionId);
                
                // restrict duplicate child
                if (!parentWrapper.childQuestions.contains(childQuestion)) {
                    parentWrapper.childQuestions.add(childQuestion);
                }
            }
        }
        
        
        return results;
    }
    
    
    
    public class ViolationWrapper {
        
        @AuraEnabled
        public Id violationId { get; set; }
        
        @AuraEnabled
        public String PHOCSAssessmentIndicatorDefinition { get; set; }
        
        @AuraEnabled
        public String result { get; set; }
        
        @AuraEnabled
        public String actionDescription { get; set; }
        
        @AuraEnabled
        public String RegCode { get; set; }
        
        @AuraEnabled
        public String RegAuthority { get; set; }
        
        @AuraEnabled
        public List<String> childQuestions { get; set; }
        
        public ViolationWrapper() {
            childQuestions = new List<String>();
        }
    }
}