/**********************************************************************************************
* @Author:      Accenture
* @Date:        17 Jul 2026
* @Description: Generic handler that populates HealthAuthority__c on any child object by looking
*               up the value from a related parent Account. Behavior is driven by
*               PHOCSHealthAuthorityConfig__mdt custom metadata, allowing new objects to be
*               supported without code changes.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public with sharing class PhocsHealthAuthorityHandler {
    
    public static final String CLASS_NAME = 'PhocsHealthAuthorityHandler';
    
    // Cache record type map to avoid repeated SOQL across trigger calls
    private static Map<String, Map<String, Id>> objectRecordTypeCache = new Map<String, Map<String, Id>>();
    
    // Cache metadata config to avoid repeated queries
    private static Map<String, PHOCSHealthAuthorityConfig__mdt> metadataConfigCache = new Map<String, PHOCSHealthAuthorityConfig__mdt>();
    
/**
* @author: Accenture
* @date: 17 Jul 2026
* @description: Populates HealthAuthority__c on qualifying child records by resolving each
*               record's parent Account (per metadata config) and copying its
*               HealthAuthority__c value. Records that already have a value, have no parent,
*               or don't match an allowed record type are skipped. Respects a bypass custom
*               setting for disabling the handler entirely.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void populateHealthAuthority(List<SObject> childRecords) {
        
        PHOCSBypassHealthAuthorityHandler__c bypassSetting = PHOCSBypassHealthAuthorityHandler__c.getInstance();
        
        if (bypassSetting != null && bypassSetting.BypassHealthAuthorityHandler__c) {
            return;
        }
        
        try {
            String objectApiName = childRecords[0].getSObjectType().getDescribe().getName();
            
            if (!metadataConfigCache.containsKey(objectApiName)) {
                List<PHOCSHealthAuthorityConfig__mdt> configs = [SELECT ObjectAPIName__c, AllowedRecTypeDevName__c, ParentIdFieldAPIName__c,
                                                                 IsActive__c FROM PHOCSHealthAuthorityConfig__mdt 
                                                                 WHERE ObjectAPIName__c = :objectApiName AND IsActive__c = true LIMIT 1];
                
                metadataConfigCache.put(objectApiName, configs.isEmpty() ? null : configs[0]);                
            }
            
            PHOCSHealthAuthorityConfig__mdt config = metadataConfigCache.get(objectApiName);
            
            if (config == null) {
                return;
            }
            
            String parentIdField = config.ParentIdFieldAPIName__c;
            
            if (!objectRecordTypeCache.containsKey(objectApiName)) {
                Map<String, Id> rtMap = new Map<String, Id>();
                
                for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = :objectApiName AND IsActive = true]) {
                    rtMap.put(rt.DeveloperName, rt.Id);
                }
                objectRecordTypeCache.put(objectApiName, rtMap);
            }
            
            Map<String, Id> recordTypeMap = objectRecordTypeCache.get(objectApiName);
            
            Set<Id> allowedRTIds = new Set<Id>();
            
            if (String.isNotBlank(config.AllowedRecTypeDevName__c)) {
                for (String rtName : config.AllowedRecTypeDevName__c.split(',')) {
                    rtName = rtName.trim();
                    
                    if (recordTypeMap.containsKey(rtName)) {
                        allowedRTIds.add(recordTypeMap.get(rtName));
                    }
                }
            }
            
            Set<Id> parentIds = new Set<Id>();            
            for (SObject rec : childRecords) {
                Id parentId = (Id) rec.get(parentIdField);
                String existingHA = (String) rec.get('HealthAuthority__c');
                Id recordTypeId = (Id) rec.get('RecordTypeId');
                
                if (String.isNotBlank(existingHA)) {
                    continue;
                }
                if (parentId == null) {
                    continue;
                }
                if (!allowedRTIds.isEmpty() && !allowedRTIds.contains(recordTypeId)) {
                    continue;
                }                
                parentIds.add(parentId);
            }
            
            if (parentIds.isEmpty()) {
                return;
            }
            
            Map<Id, Account> parentAccounts = new Map<Id, Account>([SELECT Id, HealthAuthority__c FROM Account WHERE Id IN :parentIds]);
            
            for (SObject rec : childRecords) {
                Id parentId = (Id) rec.get(parentIdField);
                String existingHA = (String) rec.get('HealthAuthority__c');
                Id recordTypeId = (Id) rec.get('RecordTypeId');
                
                if (parentId == null) {
                    continue;
                }
                if (String.isNotBlank(existingHA)) {
                    continue;
                }
                if (!allowedRTIds.isEmpty() && !allowedRTIds.contains(recordTypeId)) {
                    continue;
                }
                if (!parentAccounts.containsKey(parentId)) {
                    continue;
                }                
                rec.put('HealthAuthority__c', parentAccounts.get(parentId).HealthAuthority__c);
            }
            
        } catch (Exception e) {
            LogService.logAndPublish(CLASS_NAME, 'populateHealthAuthority', null, e);
            
            for (SObject rec : childRecords) {
                rec.addError('Unable to populate Health Authority: ' + e.getMessage());
            }
        }
    }
}