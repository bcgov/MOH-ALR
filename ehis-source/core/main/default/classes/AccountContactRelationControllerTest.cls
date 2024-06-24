/**
* @Name              : AccountContactRelationControllerTest
* @Description       : Test class for AccountContactRelationController
* @Author            : Suman Dey (Accenture)
* @StoryNo           : ALR-666
* Modification done as part of EHIS-228 Story by Chaitai Gatkine (Accenture) Dated: 21-June-2024.
**/
@isTest
private class AccountContactRelationControllerTest {

    /*test class
    to get all the related contacts associated with the account
    */
@isTest
   static void testGetAllRelatedContacts() {
        RegulatoryAuthorizationType regAuthType = TestDataFactory.createRegAuthTypeACR('Test Authorization Type', true);
        
        Account testAccount = TestDataFactory.createAccount(
            'Test Account' + System.currentTimeMillis(), 
            regAuthType.Id, 
            true
        );
        
        Contact testContact = TestDataFactory.createContact(
            testAccount.Id,
            'Test',
            'Contact',
            'test@example.com',
            '1234567890',
            true
        );

        List<AccountContactRelation> existingRelations = [
            SELECT Id
            FROM AccountContactRelation
            WHERE AccountId = :testAccount.Id AND ContactId = :testContact.Id WITH SECURITY_ENFORCED
        ];
        if (existingRelations.isEmpty()) {
            AccountContactRelation testRelation = TestDataFactory.createAccountContactRelation(
                testAccount.Id,
                testContact.Id,
                true,
                'Role1',
                true
            );
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