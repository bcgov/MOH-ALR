public with sharing class PhocsHealthAuthorityHandler {    
    /**
     * Generic method to populate HealthAuthority__c on any child object
     * Config driven via PHOCSHealthAuthorityConfig__mdt custom metadata
     */
    public static final String CLASS_NAME = 'PhocsHealthAuthorityHandler';

    // Cache record type map to avoid repeated SOQL across trigger calls
    private static Map<String, Map<String, Id>> objectRecordTypeCache = 
                                                new Map<String, Map<String, Id>>();

    // Cache metadata config to avoid repeated queries
    private static Map<String, PHOCSHealthAuthorityConfig__mdt> metadataConfigCache = 
                                                                 new Map<String, PHOCSHealthAuthorityConfig__mdt>();

    public static void populateHealthAuthority(List<SObject> childRecords) {

        // Step 1 — Check bypass switch from Custom Setting
        PHOCSBypassHealthAuthorityHandler__c bypassSetting = 
            PHOCSBypassHealthAuthorityHandler__c.getInstance();
        
        if (bypassSetting != null && bypassSetting.BypassHealthAuthorityHandler__c) {
            return;
        }

        try {
            // Step 2 — Get object type from first record
            String objectApiName = childRecords[0].getSObjectType()
                                                  .getDescribe()
                                                  .getName();

            // Step 3 — Load metadata config for this object (cached)
            if (!metadataConfigCache.containsKey(objectApiName)) {
                List<PHOCSHealthAuthorityConfig__mdt> configs = [
                    SELECT ObjectAPIName__c,
                           AllowedRecTypeDevName__c,
                           ParentIdFieldAPIName__c,
                           IsActive__c
                    FROM PHOCSHealthAuthorityConfig__mdt
                    WHERE ObjectAPIName__c = :objectApiName
                    AND   IsActive__c      = true
                    LIMIT 1
                ];
                // Store null if no config found — so we don't query again
                metadataConfigCache.put(
                    objectApiName,
                    configs.isEmpty() ? null : configs[0]
                );
            }

            PHOCSHealthAuthorityConfig__mdt config = metadataConfigCache.get(objectApiName);

            // No active config for this object — skip silently
            if (config == null) return;

            String parentIdField = config.ParentIdFieldAPIName__c;

            // Step 4 — Build allowed Record Type Ids from metadata (cached)
            if (!objectRecordTypeCache.containsKey(objectApiName)) {
                Map<String, Id> rtMap = new Map<String, Id>();
                for (RecordType rt : [
                    SELECT Id, DeveloperName 
                    FROM RecordType 
                    WHERE SObjectType = :objectApiName
                    AND   IsActive    = true
                ]) {
                    rtMap.put(rt.DeveloperName, rt.Id);
                }
                objectRecordTypeCache.put(objectApiName, rtMap);
            }

            Map<String, Id> recordTypeMap = objectRecordTypeCache.get(objectApiName);

            // Parse comma-separated record type names from metadata
            Set<Id> allowedRTIds = new Set<Id>();
            if (String.isNotBlank(config.AllowedRecTypeDevName__c)) {
                for (String rtName : config.AllowedRecTypeDevName__c.split(',')) {
                    rtName = rtName.trim(); // handle spaces around commas
                    if (recordTypeMap.containsKey(rtName)) {
                        allowedRTIds.add(recordTypeMap.get(rtName));
                    }
                }
            }

            // Step 5 — Collect parent IDs from qualifying records only
            Set<Id> parentIds = new Set<Id>();
            for (SObject rec : childRecords) {
                Id parentId       = (Id) rec.get(parentIdField);
                String existingHA = (String) rec.get('HealthAuthority__c');
                Id recordTypeId   = (Id) rec.get('RecordTypeId');

                if (String.isBlank(existingHA) == false) continue;
                if (parentId == null)                    continue;
                if (!allowedRTIds.isEmpty() && 
                    !allowedRTIds.contains(recordTypeId)) continue;

                parentIds.add(parentId);
            }

            if (parentIds.isEmpty()) return;

            // Step 6 — Query parent Account HealthAuthority__c
            Map<Id, Account> parentAccounts = new Map<Id, Account>([
                SELECT Id, HealthAuthority__c
                FROM Account
                WHERE Id IN :parentIds
            ]);

            // Step 7 — Populate HA on qualifying records only
            for (SObject rec : childRecords) {
                Id parentId       = (Id) rec.get(parentIdField);
                String existingHA = (String) rec.get('HealthAuthority__c');
                Id recordTypeId   = (Id) rec.get('RecordTypeId');

                if (parentId == null)                                      continue;
                if (String.isBlank(existingHA) == false)                   continue;
                if (!allowedRTIds.isEmpty() && 
                    !allowedRTIds.contains(recordTypeId))                  continue;
                if (!parentAccounts.containsKey(parentId))                 continue;

                rec.put(
                    'HealthAuthority__c',
                    parentAccounts.get(parentId).HealthAuthority__c
                );
            }

        } catch (Exception e) {
            LogService.logAndPublish(CLASS_NAME, 'populateHealthAuthority', null, e);
            for (SObject rec : childRecords) {
                rec.addError('Unable to populate Health Authority: ' + e.getMessage());
            }
        }
    }
}