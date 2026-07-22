public class PhocsHealthAuthorityHandler {    
    /**
     * Generic method to populate HealthAuthority__c on any child object
     * @param childRecords  - Trigger.new records
     * @param parentIdField - API name of the parent lookup field on child 
     *                        e.g. 'Account__c', 'Facility__c'
     */
    public static void populateHealthAuthority(
        List<SObject> childRecords,
        String parentIdField
    ) {
        // Step 1 — Collect parent IDs from child records
        Set<Id> parentIds = new Set<Id>();
        for (SObject rec : childRecords) {
            Id parentId = (Id) rec.get(parentIdField);
            if (parentId != null) {
                parentIds.add(parentId);
            }
        }

        if (parentIds.isEmpty()) return;

        // Step 2 — Query parent Account HealthAuthority__c
        Map<Id, Account> parentAccounts = new Map<Id, Account>([
            SELECT Id, HealthAuthority__c
            FROM Account
            WHERE Id IN :parentIds
        ]);

        // Step 3 — Populate HA on child records
        for (SObject rec : childRecords) {
            Id parentId = (Id) rec.get(parentIdField);
            if (parentId != null && parentAccounts.containsKey(parentId)) {
                rec.put(
                    'HealthAuthority__c',
                    parentAccounts.get(parentId).HealthAuthority__c
                );
            }
        }
    }


}