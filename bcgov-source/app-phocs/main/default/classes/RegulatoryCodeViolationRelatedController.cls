/**********************************************************************************************
* @Author:      Accenture 
* @Date:        17 Dec 2025
* @Description: The purpose of this class is to Display selected canned comments details on parent violation.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
17 Dec -  PHOCS-2873        -  Accenture   -  Display selected canned comments details on parent violation.
***********************************************************************************************/
public with sharing class RegulatoryCodeViolationRelatedController {
    public static String className = 'RegulatoryCodeViolationRelatedController';
/**
* @author: Deepak
* @date: 17 Dec 2025
* @description: The purpose of this method is to Display selected canned comments details on parent violation.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/   
    @AuraEnabled(cacheable=true)
    public static List<RegulatoryCodeViolation> getRelatedViolations(Id recordId) {
        try{            
            RegulatoryCodeViolation parentViolation = [SELECT Id, InspectionId, InspectionAssmntIndId, InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c
                                                       FROM RegulatoryCodeViolation WHERE Id =: recordId LIMIT 1];
            
            if(parentViolation.InspectionId == null || parentViolation.InspectionAssmntInd == null || parentViolation.InspectionAssmntInd.AssessmentIndDefinition == null){
                return new List<RegulatoryCodeViolation>();
            }
            
            Id inspectionId = parentViolation.InspectionId;
            Id parentAssessmentDefId = parentViolation.InspectionAssmntInd.AssessmentIndDefinitionId;
            
            List<RegulatoryCodeViolation> relatedViolations = [SELECT Id, Name, InspectionId, InspectionAssmntIndId, RegulatoryCodeId, RegulatoryCode.Name, RegulatoryCode.Description, InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.Name
                                                               FROM RegulatoryCodeViolation WHERE InspectionId =: inspectionId AND InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c =: parentAssessmentDefId 
                                                               ORDER BY CreatedDate DESC];
            
            return relatedViolations;
        }catch (Exception ex) {
            LogService.logAndPublish(className, 'getRelatedViolations', 'recordId=' + String.valueOf(recordId), ex);
            return new List<RegulatoryCodeViolation>();            
        }
    }
}