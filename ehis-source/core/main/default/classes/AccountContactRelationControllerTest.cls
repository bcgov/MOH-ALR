/**
* @Name              : AccountContactRelationControllerTest
* @Description       : Test class for AccountContactRelationController
* @Author            : Suman Dey (Accenture)
* @StoryNo           : ALR-666
* Modification done as part of EHIS-228 Story by Chaitai Gatkine (Accenture) Dated: 21-June-2024.
**/
@isTest
private class AccountContactRelationControllerTest {

    @isTest
    static void testGetAllRelatedContacts() {
        RegulatoryAuthorizationType regAuthType = new RegulatoryAuthorizationType(Name = 'Test Authorization Type');
        insert regAuthType;
        
        Account testAccount = new Account(
            Name = 'Test Account' + System.currentTimeMillis(), 
            LicenseType__c = regAuthType.Id
        );
        insert testAccount;
        
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '1234567890',
            AccountId = testAccount.Id
        );
        insert testContact;

        List<AccountContactRelation> existingRelations = [
            SELECT Id
            FROM AccountContactRelation
            WHERE AccountId = :testAccount.Id AND ContactId = :testContact.Id
        ];
        if (existingRelations.isEmpty()) {
            AccountContactRelation testRelation = new AccountContactRelation(
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                isActive = true,
                Roles = 'Role1'
            );
            insert testRelation;
        }
        Test.startTest();
        AccountContactRelationController.AccountContactRelationWrapper result = AccountContactRelationController.getAllRelatedContacts(testAccount.Id);
        Test.stopTest();
        System.assertEquals(1, result.relations.size(), 'Incorrect number of related contacts returned');

        // Assert that the returned record is the expected one
        if (!existingRelations.isEmpty()) {
			System.assertEquals(existingRelations[0].Id, result.relations[0].Id, 'Incorrect related contact returned');
		}
    }
}