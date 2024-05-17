/**
 * @Name              : AccountContactRelationController
 * @Description       : This class fetches related Account Contact Relation records.
 * @Author            : Suman Dey (Accenture)
 * @StoryNo           : ALR-666
 **/
public with sharing class AccountContactRelationController {
    
    /**
     * Fetches related Account Contact Relation records for a given Account Id.
     * @param accountId The Id of the Account to fetch related contacts for.
     * @return A list of AccountContactRelationWrapper objects.
     **/
    @AuraEnabled(cacheable=true)
    public static List<AccountContactRelationWrapper> getAllRelatedContacts(Id accountId) {
        List<AccountContactRelation> relations = new List<AccountContactRelation>();
        try {
            relations = [
                SELECT Id, Contact.Id, Contact.Name, Contact.Phone, Contact.Email, isActive, PrimaryContact__c, Roles
                FROM AccountContactRelation
                WHERE AccountId = :accountId AND IsActive = true
                ORDER BY CreatedDate DESC
                LIMIT 3
            ];
        } catch (QueryException err) {
            System.debug('An error occurred while querying AccountContactRelations: ' + err.getMessage());
        }

        return createWrappers(relations);
    }

    /**
     * Creates wrappers for AccountContactRelation records.
     * @param relations List of AccountContactRelation records to wrap.
     * @return A list of AccountContactRelationWrapper objects.
     **/
    private static List<AccountContactRelationWrapper> createWrappers(List<AccountContactRelation> relations) {
        List<AccountContactRelationWrapper> wrappers = new List<AccountContactRelationWrapper>();
        for (AccountContactRelation relation : relations) {
            wrappers.add(new AccountContactRelationWrapper(relation));
        }
        return wrappers;
    }

    /**
     * Wrapper class for AccountContactRelation records.
     **/
    public class AccountContactRelationWrapper {
        @AuraEnabled public AccountContactRelation relation { get; set; }

        public AccountContactRelationWrapper(AccountContactRelation relation) {
            this.relation = relation;
        }
    }
}