/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 May 2026
* @Description: The purpose of this class is to return the Map<Id, OpenViolationWrapper> to Inspection lwc.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                28 May -  EHIS-2668         -  Accenture   -  Close subsequent child records.
***********************************************************************************************/
public with sharing class PHOCSInspectionOpenViolationController {

/**
* @author: Deepak
* @date: 28 May 2026
* @description: The purpose of this method is to return the Map<Id, OpenViolationWrapper>.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @AuraEnabled(cacheable=true)
    public static Map<Id, OpenViolationWrapper> getParentQuestionsWithOpenViolations(Id visitId, List<Id> parentQuestionIds){
        Map<Id, OpenViolationWrapper> result = new Map<Id, OpenViolationWrapper>();
        List<RegulatoryCodeViolation> violations = new List<RegulatoryCodeViolation>();
        
        try {
            if (visitId == null || parentQuestionIds == null || parentQuestionIds.isEmpty()){
                return result;
            }
            
            Visit insp = [SELECT Id, AccountId, ContextId, Account.Type FROM Visit WHERE Id = :visitId LIMIT 1];
            
            if (insp.AccountId == null) {
                return result;
            }
            
            Boolean isRecreationalWater = insp.Account.Type == 'Recreational Water';            
            
            if (isRecreationalWater && insp.ContextId != null){
                violations = [SELECT Id, InspectionAssmntInd.AssessmentIndDefinitionId FROM RegulatoryCodeViolation WHERE Asset__c =: insp.ContextId
                              AND Status = 'Open' AND PHOCSParentId__c = NULL AND InspectionAssmntInd.AssessmentIndDefinitionId IN: parentQuestionIds];
            }else{
                violations = [SELECT Id, InspectionAssmntInd.AssessmentIndDefinitionId FROM RegulatoryCodeViolation WHERE Inspection.AccountId =: insp.AccountId
                              AND Status = 'Open' AND PHOCSParentId__c = NULL AND InspectionAssmntInd.AssessmentIndDefinitionId IN: parentQuestionIds];
            }
            
            for (RegulatoryCodeViolation vio : violations){
                Id questionDefId = vio.InspectionAssmntInd.AssessmentIndDefinitionId;
                
                if (questionDefId != null && !result.containsKey(questionDefId)){
                    result.put(questionDefId, new OpenViolationWrapper(true, vio.Id));
                }
            }
            
        } catch (Exception e) {
            System.debug('Error in getParentQuestionsWithOpenViolations: '+ e.getMessage());
        }        
        return result;
    }
    
    public class OpenViolationWrapper {
        @AuraEnabled public Boolean hasOpenViolation { get; set; }
        @AuraEnabled public Id parentViolationId { get; set; }
        
        public OpenViolationWrapper(Boolean hasViolation, Id violationId){
            this.hasOpenViolation = hasViolation;
            this.parentViolationId = violationId;
        }
    }
}