/**********************************************************************************************
* @Author:      Accenture
* @Date:        29/10/2026
* @Description: Handler for AssetTrigger. Copies HealthAuthority__c from the parent Asset's
*               Account to child Assets (record types listed in HA_COPY_RECORD_TYPES) when the
*               child has no AccountId and ParentId is populated or changed.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public with sharing class AssetTriggerHandler {
    @TestVisible
    private static final Set<String> HA_COPY_RECORD_TYPES = new Set<String>{'Treatment_Method'};
        
/**
* @author      Deepak
* @date        29/10/2026
* @description Handles after insert logic for Asset
* @param       newAssets - Trigger.new
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
        public static void afterInsert(List<Asset> newAssets) {
            copyHealthAuthorityFromParent(newAssets, null);
        }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Handles after update logic for Asset
* @param       newAssets - Trigger.new
* @param       oldMap - Trigger.oldMap
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void afterUpdate(List<Asset> newAssets, Map<Id, Asset> oldMap) {
        copyHealthAuthorityFromParent(newAssets, oldMap);
    }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Copies ParentId.AccountId.HealthAuthority__c into HealthAuthority__c of
*              qualifying Assets (AccountId blank, ParentId populated, or changed on update)
* @param       newAssets - Trigger.new
* @param       oldMap - Trigger.oldMap (null on insert)
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void copyHealthAuthorityFromParent(List<Asset> newAssets, Map<Id, Asset> oldMap) {
        try {
            Map<Id, Schema.RecordTypeInfo> rtInfoById = Schema.SObjectType.Asset.getRecordTypeInfosById();
            Boolean isInsert = (oldMap == null);
            
            List<Asset> candidates = new List<Asset>();
            Set<Id> parentIds = new Set<Id>();
            
            for (Asset a : newAssets) {
                Schema.RecordTypeInfo rtInfo = rtInfoById.get(a.RecordTypeId);
                if (rtInfo == null || !HA_COPY_RECORD_TYPES.contains(rtInfo.getDeveloperName())) {
                    continue;
                }
                if (a.AccountId != null || a.ParentId == null) {
                    continue;
                }
                if (!isInsert && a.ParentId == oldMap.get(a.Id).ParentId) {
                    continue;
                }
                candidates.add(a);
                parentIds.add(a.ParentId);
            }
            
            if (candidates.isEmpty()) {
                return;
            }
            
            List<Asset> parentList = [SELECT Id, Account.HealthAuthority__c FROM Asset WHERE Id IN :parentIds WITH USER_MODE];
            Map<Id, Asset> parents = new Map<Id, Asset>(parentList);
            
            List<Asset> toUpdate = new List<Asset>();
            for (Asset a : candidates) {
                Asset parent = parents.get(a.ParentId);
                if (parent == null || parent.Account == null || parent.Account.HealthAuthority__c == null) {
                    continue;
                }
                if (a.HealthAuthority__c != parent.Account.HealthAuthority__c) {
                    toUpdate.add(new Asset(Id = a.Id, HealthAuthority__c = parent.Account.HealthAuthority__c));
                }
            }
            
            if (!toUpdate.isEmpty()) {
                SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, toUpdate);
                List<Database.SaveResult> results = Database.update(decision.getRecords(), false);
                for (Database.SaveResult sr : results) {
                    if (!sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'AssetTriggerHandler update failed: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AssetTriggerHandler.copyHealthAuthorityFromParent error: ' + e.getMessage() + ' | ' + e.getStackTraceString());
        }
    }
}