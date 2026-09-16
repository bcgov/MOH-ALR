global without sharing class PHOCSInspectionContraventionController {
    
    @AuraEnabled(cacheable=true)
    public static List<ViolationWrapper> getRegulatoryViolations(Id caseId) {
        
        List<ViolationWrapper> results = new List<ViolationWrapper>();
        
        if (caseId == null) {
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
            	   Corrected_During_Inspection__c
            FROM RegulatoryCodeViolation
            WHERE inspectionid IN :inspectionIds
            AND Corrected_During_Inspection__c = false
            ORDER BY CreatedDate ASC
        ];
        
        
        
        if (violations.isEmpty()) {
            return results;
        }
        
        // Keep track of the current parent violation
        ViolationWrapper currentParent = null;
        
        for (RegulatoryCodeViolation violation : violations) {
            
            // CHILD VIOLATION
            if (violation.IsChildViolation__c == true) {
                
                if (currentParent != null) {
                    currentParent.childQuestions.add(
                        violation.PHOCSAssessmentIndicatorDefinition__c
                    );
                }
                
                continue;
            }
            
            // PARENT VIOLATION
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
            
            // Make this the current parent
            currentParent = wrapper;
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