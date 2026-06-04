/**********************************************************************************************
* @Author:      Accenture 
* @Date:        17 Dec 2025
* @Description: The purpose of this class is to Display selected canned comments details on parent violation.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                17 Dec -  PHOCS-2873        -  Accenture   -  Display selected canned comments details on parent violation.
                28 May -  EHIS-2668         -  Accenture   -  Fetch child violation hierarchy with associated canned comments.
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
            
            List<RegulatoryCodeViolation> relatedViolations = [SELECT Id, Name, InspectionId, InspectionAssmntIndId, RegulatoryCodeId, RegulatoryCode.Name, RegulatoryCode.Subject, RegulatoryCode.Description, InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.Name
                                                               FROM RegulatoryCodeViolation WHERE InspectionId =: inspectionId AND InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c =: parentAssessmentDefId 
                                                               ORDER BY CreatedDate DESC];
            
            return relatedViolations;
        }catch (Exception ex) {
            LogService.logAndPublish(className, 'getRelatedViolations', 'recordId=' + String.valueOf(recordId), ex);
            return new List<RegulatoryCodeViolation>();            
        }
    }
    
/**
* @author: Deepak
* @date: 28 May 2026
* @description: Fetch child violation hierarchy with associated canned comments.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled(cacheable=true)
    public static List<ViolationHierarchyWrapper> getViolationHierarchy(Id recordId) {
        Set<Id> allAssessmentDefIds = new Set<Id>();
        Map<String, List<CannedCommentWrapper>> cannedCommentMap = new Map<String, List<CannedCommentWrapper>>();
        Map<Id, Set<Id>> inspectionToChildDefIds = new Map<Id, Set<Id>>();
        Map<String, List<Id>> inspectionDefToAssmntIndIds = new Map<String, List<Id>>();        
        try {            
            if (recordId == null) {
                return new List<ViolationHierarchyWrapper>();
            }
            
            List<RegulatoryCodeViolation> childViolations = [SELECT Id, Name, CreatedDate, ComplianceDueDate, InspectionId, Inspection.Name, DaysOpen, Inspection.Owner.Name,
                                                             Status, CorrectiveActionDescription, InspectionAssmntIndId, InspectionAssmntInd.AssessmentIndDefinitionId, 
                                                             InspectionAssmntInd.PHOCSInspectionComments__c, InspectionAssmntInd.AssessmentIndDefinition.Name FROM RegulatoryCodeViolation 
                                                             WHERE PHOCSParentId__c = :recordId ORDER BY CreatedDate DESC];
            
            if (childViolations.isEmpty()) {
                return new List<ViolationHierarchyWrapper>();
            }
            
            for (RegulatoryCodeViolation vio : childViolations) {
                if (vio.InspectionId == null || vio.InspectionAssmntInd == null || vio.InspectionAssmntInd.AssessmentIndDefinitionId == null){
                    continue;
                }                
                Id defId = vio.InspectionAssmntInd.AssessmentIndDefinitionId;
                
                if(!inspectionToChildDefIds.containsKey(vio.InspectionId)){
                    inspectionToChildDefIds.put(vio.InspectionId, new Set<Id>());
                }
                inspectionToChildDefIds.get(vio.InspectionId).add(defId);
                allAssessmentDefIds.add(defId);
                
                String childKey = vio.InspectionId + '-' + defId;
                if (!inspectionDefToAssmntIndIds.containsKey(childKey)) {
                    inspectionDefToAssmntIndIds.put(childKey, new List<Id>());
                }
                inspectionDefToAssmntIndIds.get(childKey).add(vio.InspectionAssmntIndId);
            }
            
            List<RegulatoryCodeViolation> relatedViolations = [SELECT Id, InspectionId, RegulatoryCodeId, RegulatoryCode.Name, RegulatoryCode.Subject, InspectionAssmntIndId,
                                                               InspectionAssmntInd.AssessmentIndDefinitionId, InspectionAssmntInd.AssessmentIndDefinition.Name,
                                                               InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c FROM RegulatoryCodeViolation 
                                                               WHERE InspectionId IN :inspectionToChildDefIds.keySet() AND 
                                                               InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c IN :allAssessmentDefIds ORDER BY CreatedDate DESC];
            
            for (RegulatoryCodeViolation rv : relatedViolations) {
                Id phOCSParentId = rv.InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c;
                
                if (!inspectionToChildDefIds.containsKey(rv.InspectionId)) continue;
                if (!inspectionToChildDefIds.get(rv.InspectionId).contains(phOCSParentId)) continue;
                
                String childKey = rv.InspectionId + '-' + phOCSParentId;
                List<Id> childAssmntIndIds = inspectionDefToAssmntIndIds.get(childKey);
                
                CannedCommentWrapper cc = new CannedCommentWrapper();
                cc.assessmentIndicatorName   = rv.InspectionAssmntInd.AssessmentIndDefinition.Name;
                cc.regulatoryCodeName        = rv.RegulatoryCode != null ? rv.RegulatoryCode.Name    : '';
                cc.regulatoryCodeDescription = rv.RegulatoryCode != null ? rv.RegulatoryCode.Subject : '';
                
                for (Id childAssmntIndId : childAssmntIndIds) {
                    String key = rv.InspectionId + '-' + phOCSParentId + '-' + childAssmntIndId;
                    if (!cannedCommentMap.containsKey(key)) {
                        cannedCommentMap.put(key, new List<CannedCommentWrapper>());
                    }
                    cannedCommentMap.get(key).add(cc);
                }
            }
            
            List<ViolationHierarchyWrapper> results = new List<ViolationHierarchyWrapper>();
            
            for(RegulatoryCodeViolation vio : childViolations){                
                ViolationHierarchyWrapper wrapper = new ViolationHierarchyWrapper();                
                wrapper.violationId = vio.Id;                
                wrapper.violationName = vio.Name;                
                wrapper.violationUrl = '/' + vio.Id;                
                wrapper.inspectionName = vio.Inspection != null ? vio.Inspection.Name : '';
                wrapper.inspectionUrl = vio.InspectionId != null ? '/' + vio.InspectionId : '';                
                wrapper.status = vio.Status;
                wrapper.createdDate = vio.CreatedDate;                
                wrapper.daysOpen = vio.DaysOpen;                
                wrapper.complianceDueDate = vio.ComplianceDueDate;
                wrapper.questionName = vio.InspectionAssmntInd != null && vio.InspectionAssmntInd.AssessmentIndDefinition != null ? vio.InspectionAssmntInd.AssessmentIndDefinition.Name : '';
                wrapper.officerName = vio.Inspection.Owner != null ? vio.Inspection.Owner.Name : '';
                wrapper.observations = vio.InspectionAssmntInd.PHOCSInspectionComments__c != null ? vio.InspectionAssmntInd.PHOCSInspectionComments__c : '';
                wrapper.correctiveActionDescription = vio.CorrectiveActionDescription != null ? vio.CorrectiveActionDescription : '';                
                
                String key = vio.InspectionId + '-' + vio.InspectionAssmntInd.AssessmentIndDefinitionId + '-' + vio.InspectionAssmntIndId;
                wrapper.cannedComments = cannedCommentMap.containsKey(key) ? cannedCommentMap.get(key) : new List<CannedCommentWrapper>();               
                results.add(wrapper);
            }
            
            return results;
            
        } catch (Exception ex) {
           LogService.logAndPublish(className, 'getViolationHierarchy', 'recordId=' + String.valueOf(recordId), ex);            
            return new List<ViolationHierarchyWrapper>();
        }
    }
    
    public class ViolationHierarchyWrapper {        
        @AuraEnabled public Id violationId;        
        @AuraEnabled public String violationName;
        @AuraEnabled public String violationUrl;       
        @AuraEnabled public String inspectionName;
        @AuraEnabled public String inspectionUrl;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Integer daysOpen;
        @AuraEnabled public Datetime complianceDueDate;
        @AuraEnabled public String questionName;
        @AuraEnabled public List<CannedCommentWrapper> cannedComments;
        @AuraEnabled public String officerName;
        @AuraEnabled public String observations;        
        @AuraEnabled public String correctiveActionDescription;
    }
    
    public class CannedCommentWrapper {
        @AuraEnabled public String assessmentIndicatorName;
        @AuraEnabled public String regulatoryCodeName;
        @AuraEnabled public String regulatoryCodeDescription;
    }
}