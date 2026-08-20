/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 May 2026
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                28 May -  EHIS-2668         -  Accenture   -  Close subsequent child records.
***********************************************************************************************/
public with sharing class RegulatoryCodeViolationHandler {
    public static String className = 'RegulatoryCodeViolationHandler';
    public static final String STATUS_RESOLVED = 'Resolved';
    public static Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
    
/**
* @author: Deepak
* @date: 28 May 2026
* @description: The purpose of this method is to Close subsequent child records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static void syncChildViolationStatus(List<RegulatoryCodeViolation> newList, Map<Id, RegulatoryCodeViolation> oldMap){
        Set<Id> parentViolationIds = new Set<Id>();
        Map<Id, String> parentStatusMap = new Map<Id, String>();
        Map<Id, Id> parentResolvedInMap = new Map<Id, Id>();
        try{
            for(RegulatoryCodeViolation newRec : newList){
                RegulatoryCodeViolation oldRec =oldMap.get(newRec.Id);
                
                if(oldRec == null || oldRec.Status == newRec.Status || newRec.recordtypeId != recordTypePHOCSRegulatoryCodeViolation){
                    continue;
                }
                
                if(newRec.PHOCSParentId__c == null && newRec.Status == STATUS_RESOLVED){
                    parentViolationIds.add(newRec.Id);
                    parentStatusMap.put(newRec.Id,newRec.Status);
                    parentResolvedInMap.put(newRec.Id,newRec.ResolvedIn__c);
                }
            }
            
            if (parentViolationIds.isEmpty()) {
                return;
            }        
            List<RegulatoryCodeViolation> childViolations = [SELECT Id, Status, PHOCSParentId__c, DateResolved, ResolvedIn__c FROM RegulatoryCodeViolation WHERE PHOCSParentId__c IN: parentViolationIds];
            
            if(childViolations.isEmpty()){
                return;
            }
            
            for(RegulatoryCodeViolation child : childViolations){
                String parentStatus = parentStatusMap.get(child.PHOCSParentId__c);
                
                if(parentStatus != null && child.Status != parentStatus){
                    child.Status = parentStatus;
                    child.DateResolved = System.Now();
                    child.ResolvedIn__c = parentResolvedInMap.get(child.PHOCSParentId__c);
                }
            }
            
            if(!childViolations.isEmpty()){
                update childViolations;
            }
        }catch (Exception ex) {
            LogService.logAndPublish(className, 'syncChildViolationStatus', String.valueOf(newList), ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 28 May 2026
* @description: The purpose of this method is to update recurrence count based on child records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    public static void updateRecurrenceCount(List<RegulatoryCodeViolation> newList){
        Set<Id> parentViolationIds = new Set<Id>();
        Map<Id, Integer>recurrenceCountMap = new Map<Id, Integer>();
        Map<Id, DateTime> complianceDueDateMap = new Map<Id, DateTime>();
        List<RegulatoryCodeViolation> parentsToUpdate = new List<RegulatoryCodeViolation>();
        try{
            for (RegulatoryCodeViolation newRec : newList) {
                if (newRec.RecordTypeId != recordTypePHOCSRegulatoryCodeViolation || newRec.PHOCSParentId__c == null){
                    continue;
                }
                parentViolationIds.add(newRec.PHOCSParentId__c);
            }
            
            if (parentViolationIds.isEmpty()) {
                return;
            }
            
            AggregateResult[] childCounts = [SELECT PHOCSParentId__c parentId, COUNT(Id) childCount, MAX(ComplianceDueDate) latestComplianceDueDate
                                             FROM RegulatoryCodeViolation WHERE PHOCSParentId__c IN: parentViolationIds 
                                             AND  RecordTypeId = :recordTypePHOCSRegulatoryCodeViolation AND Status = 'Open' GROUP BY PHOCSParentId__c];       
            
            if (childCounts.isEmpty()) {
                return;
            }
            
            for (AggregateResult ar : childCounts) {
                Id parentId = (Id) ar.get('parentId');
                recurrenceCountMap.put(parentId, (Integer) ar.get('childCount'));
                complianceDueDateMap.put(parentId, (DateTime) ar.get('latestComplianceDueDate'));
            }
            
            for (Id parentId : parentViolationIds) {
                parentsToUpdate.add(new RegulatoryCodeViolation(Id = parentId, ComplianceDueDate = complianceDueDateMap.get(parentId),
                                                                RecurrenceCount = recurrenceCountMap.containsKey(parentId) ? recurrenceCountMap.get(parentId) : 0));
            }
            
            if (!parentsToUpdate.isEmpty()) {
                update parentsToUpdate;
            } 
        }catch (Exception ex) {
            LogService.logAndPublish(className, 'updateRecurrenceCount', String.valueOf(newList), ex);
            throw ex;
        }
    }
}