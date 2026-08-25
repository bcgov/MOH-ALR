/**********************************************************************************************
* @Author:      Accenture
* @Date:        25 Aug 2026
* @Description: Controller for displaying Regulatory Code Violations related to an Assessment.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public with sharing class PHOCSAsmntVioRelatedController {
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Retrieves qualifying Regulatory Code Violations for the Inspection associated with the Assessment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled(cacheable=true)
    public static List<RegulatoryCodeViolation> getRelatedViolations(Id assessmentId) {
        if (assessmentId == null) {
            return new List<RegulatoryCodeViolation>();
        }
        
        List<Assessment> assessments = [SELECT ResponseContextId FROM Assessment WHERE Id = :assessmentId LIMIT 1];
        
        if (assessments.isEmpty() || assessments[0].ResponseContextId == null) {
            return new List<RegulatoryCodeViolation>();
        }
        
        Id inspectionId = assessments[0].ResponseContextId;
        
        return [SELECT Id, Name, RegulatoryCode.Name, RegulatoryCode.Subject, InspectionAssmntInd.AssessmentIndDefinition.Name, Scope__c, Severity__c FROM RegulatoryCodeViolation
                WHERE InspectionId = :inspectionId AND Scope__c != NULL AND Severity__c != NULL AND IsChildViolation__c = false ORDER BY InspectionAssmntInd.AssessmentTask.Name];
    }
}