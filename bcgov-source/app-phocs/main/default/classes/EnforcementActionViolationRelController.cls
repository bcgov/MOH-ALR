/**********************************************************************************************
* @Author:      Accenture 
* @Date:        22 May 2026
* @Description: The purpose of this class is to fetch the related records to display in lwc.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                26 May -  EHIS-3688         -  Accenture   -  fetch the related records.
***********************************************************************************************/
public with sharing class EnforcementActionViolationRelController {
/**
* @author: Deepak
* @date: 26 May 2026
* @description: The purpose of this method is to fetch the related records to display in lwc.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    @AuraEnabled
    public static List<EnforcementActionViolation__c> getRelatedViolations(Id recordId) {
        List<EnforcementActionViolation__c> violations = new List<EnforcementActionViolation__c>();
        
        try{
            if(recordId == null){
                return violations;
            }
            
            violations = [SELECT Id, Name, RegulatoryCodeViolation__c, RegulatoryCodeViolation__r.Name, RegulatoryCodeViolation__r.InspectionId, RegulatoryCodeViolation__r.Inspection.Name, 
                          RegulatoryCodeViolation__r.InspectionAssmntInd.AssessmentIndDefinition.Name, RegulatoryCodeViolation__r.Status, RegulatoryCodeViolation__r.ComplianceDueDate,
                          RegulatoryCodeViolation__r.DaysOpen FROM EnforcementActionViolation__c WHERE ViolationEnforcementAction__c = :recordId 
                          ORDER BY RegulatoryCodeViolation__r.Status ASC, RegulatoryCodeViolation__r.ComplianceDueDate ASC];
        } catch(Exception ex){            
            System.debug(LoggingLevel.ERROR, 'Error in EnforcementActionViolationRelController.getRelatedViolations: '  + ex.getMessage());
        }        
        return violations;
    }
}