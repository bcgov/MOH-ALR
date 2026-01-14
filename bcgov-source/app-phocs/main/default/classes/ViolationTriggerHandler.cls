/**
* Class Name  	: ViolationTriggerHandler
* Object      	: RegulatoryCodeViolation
*
* Author      	: Pawan Atri
* Created On  	: 14-Jan-2026
* User Story  	: EHIS-3018
* Title	   		: Mark canned comment violations as resolved when parent violation is resolved by the users
*
* Description :
* This handler class is used by the RegulatoryCodeViolation trigger to
* automatically manage the "Resolved" status and "Date Resolved" field
* for both parent violations (questions) and their related child
* canned comment violations.
*
* Business Logic Implemented:
*
* AC#1:
* - When a parent RegulatoryCodeViolation record's Status changes to "Resolved",
*   the DateResolved field is automatically populated with the current date/time
*   if it is not already set.
*
* AC#2:
* - When a parent violation (question-level violation) is marked as "Resolved",
*   all related child violations (canned comment violations tied to the same
*   inspection and assessment definition) are automatically updated:
*      - Status is set to "Resolved"
*      - DateResolved is set to the current date/time
*
* This ensures that administrators do not have to manually maintain the
* resolution status of child canned comment violations once the parent
* question-level violation is resolved.
*/

public class ViolationTriggerHandler {
    
    // Prevents recursive trigger execution during updates
    private static Boolean isExecuting = false;
    
    //When parent violation is marked Resolved → set Date Resolved
    public static void setResolvedDate(List<RegulatoryCodeViolation> violations, Map<Id, RegulatoryCodeViolation> oldViolationMap) {
        
        for (RegulatoryCodeViolation violation : violations) {
            RegulatoryCodeViolation oldViolation = oldViolationMap.get(violation.Id);
            
            // Check if status changed to Resolved
            if (oldViolation.Status != 'Resolved' && violation.Status == 'Resolved') {
                
                // Set Date Resolved if not already set
                if (violation.DateResolved == null) {
                    violation.DateResolved = System.Now();
                }
            }
        }
    }
    
    //When parent violation is resolved → resolve all child canned comment violations
    public static void resolveChildViolations(List<RegulatoryCodeViolation> violations, Map<Id, RegulatoryCodeViolation> oldViolationMap) {
        
        // Prevent recursive updates
        if (isExecuting) return;
        isExecuting = true;
        
        Set<Id> parentInspectionIds = new Set<Id>();
        Set<Id> parentAssessmentDefIds = new Set<Id>();
        
        // Identify parent violations that were just resolved
        for (RegulatoryCodeViolation parentViolation : violations) {
            RegulatoryCodeViolation oldParentViolation = oldViolationMap.get(parentViolation.Id);
            
            
            System.debug(parentViolation);
            System.debug(parentViolation.InspectionAssmntInd);
            System.debug(parentViolation.InspectionAssmntInd.AssessmentIndDefinition);
            
            if (
                oldParentViolation.Status != 'Resolved' &&
                parentViolation.Status == 'Resolved' &&
                parentViolation.InspectionId != null &&
                parentViolation.InspectionAssmntInd != null &&
                parentViolation.InspectionAssmntInd.AssessmentIndDefinition != null
            ) {
                parentInspectionIds.add(parentViolation.InspectionId);
                parentAssessmentDefIds.add(parentViolation.InspectionAssmntInd.AssessmentIndDefinitionId);
            }
        }
        
        if (parentInspectionIds.isEmpty() && parentAssessmentDefIds.isEmpty()) return;
        
        // Fetch all child violations linked to the same parent question
        List<RegulatoryCodeViolation> childViolations = [
            SELECT Id, Status, DateResolved                                                                 
            FROM RegulatoryCodeViolation 
            WHERE InspectionId IN :parentInspectionIds 
            AND InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c IN :parentAssessmentDefIds 
            AND Status != 'Resolved'                                                                
            ORDER BY CreatedDate DESC            
        ];
        
        // Update child violations
        for (RegulatoryCodeViolation child : childViolations) {
            child.Status = 'Resolved';
            child.DateResolved = System.Now();
        }
        
        if (!childViolations.isEmpty()) {
            update childViolations;
        }
    }
}