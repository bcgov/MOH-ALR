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
   @testSetup public static void setupData() {
        RegulatoryAuthorizationType regAuthType = TestDataFactory.createRegAuthTypeACR('Test Authorization Type', true);
        
        Account testAccount = TestDataFactory.createAccount(
            'TestAccount' + System.currentTimeMillis(), 
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
   }
       @isTest
       static void testGetAllRelatedContacts() {
		Account acc = [Select Id from Account where Name Like 'TestAccount%' Limit 1];
        Test.startTest();
        AccountContactRelationController.AccountContactRelationWrapper result = AccountContactRelationController.getAllRelatedContacts(acc.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.relations.size(), 'Incorrect number of related contacts returned');

        
       }
    
}