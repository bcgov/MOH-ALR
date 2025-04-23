/**
* @Name              : AccountStatusUpdate
* @Description       : Test Class for Updating Account Status on April 1st and May 1st
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

@isTest
private class AccountStatusUpdateTest {

        @isTest
        static void testExecute() {
         RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
         Account residenceRec1 = TestDataFactory.createResidence('Residence', 'Test Residence', regAuth.Id, true);
         residenceRec1.Status__c= BCMOH_Constants.accountStatus;
        Database.Update(residenceRec1,false);
        BusinessLicenseApplication bla = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);  
       

        Test.startTest();
         AccountStatusUpdate send=new AccountStatusUpdate();
        send.execute(null);

        Test.stopTest();

         Account updatedAccount = [SELECT Id, Status__c FROM Account WHERE Id = :residenceRec1.Id];
        System.assertEquals(BCMOH_Constants.accountStatus, updatedAccount.Status__c, 'Account status should have been updated.');
      
    }
}