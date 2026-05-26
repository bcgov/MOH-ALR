/**********************************************************************************************
* @Author:      Accenture 
* @Date:        22 May 2026
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                22 May -  EHIS-3688         -  Accenture   -  Prevents duplicate records records.
***********************************************************************************************/
public with sharing class EnforcementActionViolationHandler {
    
/**
* @author: Deepak
* @date: 22 May 2026
* @description: The purpose of this method is to Prevent duplicate records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static void validateDuplicateRecords(List<EnforcementActionViolation__c> newRecords, Map<Id, EnforcementActionViolation__c> oldMap){
        try{
            Set<Id> enforcementActionIds = new Set<Id>();
            Set<Id> regulatoryViolationIds = new Set<Id>();
            Set<String> uniqueKeys = new Set<String>();
            Set<String> existingKeys = new Set<String>();
            
            for(EnforcementActionViolation__c rec : newRecords){
                if (rec.ViolationEnforcementAction__c == null || rec.RegulatoryCodeViolation__c == null) {
                    continue;
                }
                
                if (oldMap != null && oldMap.containsKey(rec.Id)) {
                    EnforcementActionViolation__c oldRec = oldMap.get(rec.Id);
                    if (oldRec.ViolationEnforcementAction__c == rec.ViolationEnforcementAction__c && oldRec.RegulatoryCodeViolation__c == rec.RegulatoryCodeViolation__c) {
                        continue;
                    }
                }                
                enforcementActionIds.add(rec.ViolationEnforcementAction__c);
                regulatoryViolationIds.add(rec.RegulatoryCodeViolation__c);
                
                String key = rec.ViolationEnforcementAction__c + '-' + rec.RegulatoryCodeViolation__c;
                
                if (uniqueKeys.contains(key)) {
                    rec.addError(label.PHOCS_EAV_InsertErrorMsg);
                }
                uniqueKeys.add(key);
            }
            
            if (enforcementActionIds.isEmpty() || regulatoryViolationIds.isEmpty()) {
                return;
            }
            
            List<EnforcementActionViolation__c> existingRecords = [SELECT Id, ViolationEnforcementAction__c, RegulatoryCodeViolation__c FROM EnforcementActionViolation__c
                                                                   WHERE ViolationEnforcementAction__c IN :enforcementActionIds AND RegulatoryCodeViolation__c IN :regulatoryViolationIds];
            
            
            for (EnforcementActionViolation__c existing : existingRecords) {
                String key = existing.ViolationEnforcementAction__c + '-' + existing.RegulatoryCodeViolation__c;                
                existingKeys.add(key);
            }
            
            for (EnforcementActionViolation__c rec : newRecords) {
                
                if (rec.ViolationEnforcementAction__c == null || rec.RegulatoryCodeViolation__c == null) {
                    continue;
                }
                
                String key = rec.ViolationEnforcementAction__c + '-' + rec.RegulatoryCodeViolation__c;                
                Boolean isSelfUpdate = false;
                
                if (oldMap != null && oldMap.containsKey(rec.Id)) {
                    EnforcementActionViolation__c oldRec = oldMap.get(rec.Id);                    
                    String oldKey = oldRec.ViolationEnforcementAction__c + '-' + oldRec.RegulatoryCodeViolation__c;
                    
                    if (oldKey == key) {
                        isSelfUpdate = true;
                    }
                }
                
                if (existingKeys.contains(key) && !isSelfUpdate) {
                    rec.addError(label.PHOCS_EAV_UpdateErrorMsg);
                }
            }
        }catch(Exception ex){        
            System.debug(LoggingLevel.ERROR, 'Error in EnforcementActionViolationHandler: ' + ex.getMessage());        
            throw ex;
        }
    }
}