/**********************************************************************************************
* @Author:      Accenture 
* @Date:        06 Aug 2026
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-269         -  Accenture   -  Update the RiskAssessmentEligibility__c on Account.
***********************************************************************************************/
public with Sharing class VisitTriggerHandler {
    public static Id recordTypeALRInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('Inspection').getRecordTypeId();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public static final String VISIT_TYPE_ROUTINE = 'Routine';
    public static final String VISIT_TYPE_ROUTINE_FOLLOW_UP = 'Routine Follow-up';
    public static final String CLASS_NAME = 'VisitTriggerHandler';
    
    public static void afterUpdate(List<Visit> newList, Map<Id, Visit> oldMap) {
        Set<Id> completedInspectionIds = new Set<Id>();
        for (Visit insp : newList) {
            Visit oldInsp = oldMap.get(insp.Id);
            if (insp.Status == 'Completed' && oldInsp.Status != 'Completed') {
                if (insp.RecordTypeId == recordTypeALRInspection) {
                    RCVCreationHelper.createRegulatoryCodeViolations(insp.Id);
                }

                if (insp.RecordTypeId == recordTypePHOCSInspection) {
                    completedInspectionIds.add(insp.Id);
                }
            }
        }
        
        if (!completedInspectionIds.isEmpty()) {
            PHOCSInspectionAssessmentIndBatch.delInsInd(completedInspectionIds);
            updateRiskAssessmentEligibility(completedInspectionIds);
        }
    }

/**
* @author: Deepak
* @date: 06 Aug 2026
* @description: The purpose of this method is to update the RiskAssessmentEligibility__c on respective account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static void updateRiskAssessmentEligibility(Set<Id> completedInspectionIds) {
        try{
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>();            
            List<Visit> inspections = [SELECT Id, AccountId, Account.RiskAssessmentEligibility__c, VisitTypeId,
                                       VisitType.Name FROM Visit WHERE Id IN: completedInspectionIds];
            
            for (Visit inspection : inspections) {
                if (inspection.AccountId == null || inspection.Account.RiskAssessmentEligibility__c || inspection.VisitType == null) {
                    continue;
                }
                
                if (inspection.VisitType.Name == 'Routine' || inspection.VisitType.Name == 'Routine Follow-up') {
                    accountsToUpdate.put(inspection.AccountId, new Account(Id = inspection.AccountId, RiskAssessmentEligibility__c = true));
                }
            }
            
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate.values();
            }
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'updateRiskAssessmentEligibility', null, ex);
            throw ex;
        }
    }
}