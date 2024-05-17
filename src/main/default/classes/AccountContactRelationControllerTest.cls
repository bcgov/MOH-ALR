/**
* @Name              : AccountContactRelationControllerTest
* @Description       : Test class for AccountContactRelationController
* @Author            : Suman Dey (Accenture)
* @StoryNo           : ALR-666
**/
@isTest
private class AccountContactRelationControllerTest {

    @isTest
    static void testGetAllRelatedContacts() {
        // Create test RegulatoryAuthorizationType record
        RegulatoryAuthorizationType regAuthType = new RegulatoryAuthorizationType(Name = 'Test Authorization Type');
        insert regAuthType;
        
        // Create test Account with RegulatoryAuthorizationType field populated
        Account testAccount = new Account(
            Name = 'Test Account' + System.currentTimeMillis(), 
            LicenseType__c = regAuthType.Id
        );
        insert testAccount;
        
        // Create test Contact and associate it with the Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            Phone = '1234567890',
            AccountId = testAccount.Id // Associate the contact with the account during creation
        );
        insert testContact;

        // Check for existing AccountContactRelation records
        List<AccountContactRelation> existingRelations = [
            SELECT Id
            FROM AccountContactRelation
            WHERE AccountId = :testAccount.Id AND ContactId = :testContact.Id
        ];

        // If no existing relations, create a new one
        if (existingRelations.isEmpty()) {
            AccountContactRelation testRelation = new AccountContactRelation(
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                isActive = true,
                Roles = 'Role1' // Ensure uniqueness if required
            );
            insert testRelation;
        }

        // Call the method to test
        Test.startTest();
        List<AccountContactRelationController.AccountContactRelationWrapper> result = AccountContactRelationController.getAllRelatedContacts(testAccount.Id);
        Test.stopTest();

        // Assert that the correct number of records are returned
        System.assertEquals(1, result.size(), 'Incorrect number of related contacts returned');

        // Assert that the returned record is the expected one
        if (!existingRelations.isEmpty()) {
    		System.assertEquals(String.valueOf(existingRelations[0].Id), String.valueOf(result[0].relation.Id), 'Incorrect related contact returned');

		}
    }
}