/**
 * @Name              : AccountContactRelationController
 * @Description       : This class fetches related Account Contact Relation records.
 * @Author            : Suman Dey (Accenture)
 * @StoryNo           : ALR-666
 * Modification done as part of EHIS-228 Story by Chaitai Gatkine (Accenture) Dated: 21-June-2024.
 **/
public with sharing class AccountContactRelationController {

    @AuraEnabled(cacheable=true)
    public static AccountContactRelationWrapper getAllRelatedContacts(Id accountId) {
        List<AccountContactRelation> relations = new List<AccountContactRelation>();
        String accountRecordTypeId;
        String accountRecordTypeName;

        try {
            Account account = [SELECT RecordTypeId, RecordType.Name FROM Account WHERE Id = :accountId LIMIT 1];
            accountRecordTypeId = account.RecordTypeId;
            accountRecordTypeName = account.RecordType.Name;

            relations = [
                SELECT Id, Contact.Id, Contact.Name, Contact.Phone, Contact.Email, IsActive, PrimaryContact__c, Roles
                FROM AccountContactRelation
                WHERE AccountId = :accountId AND IsActive = true
                ORDER BY PrimaryContact__c DESC
                LIMIT 3
            ];
        } catch (QueryException err) {
            System.debug('An error occurred while querying AccountContactRelations: ' + err.getMessage());
        }

        return new AccountContactRelationWrapper(relations, accountRecordTypeId, accountRecordTypeName);
    }

    public class AccountContactRelationWrapper {
        @AuraEnabled public List<AccountContactRelation> relations { get; set; }
        @AuraEnabled public String accountRecordTypeId { get; set; }
        @AuraEnabled public String accountRecordTypeName { get; set; }

        public AccountContactRelationWrapper(List<AccountContactRelation> relations, String accountRecordTypeId, String accountRecordTypeName) {
            this.relations = relations;
            this.accountRecordTypeId = accountRecordTypeId;
            this.accountRecordTypeName = accountRecordTypeName;
        }
    }
}