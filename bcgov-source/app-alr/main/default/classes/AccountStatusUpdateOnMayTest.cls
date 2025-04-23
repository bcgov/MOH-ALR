/**
* @Name              : AccountStatusUpdateOnMay
* @Description       : Test Class for Updating Account Status on May 1st 
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

@isTest
public class AccountStatusUpdateOnMayTest {
    
@isTest
        static void testExecute() {
         RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
         Account residenceRec1 = TestDataFactory.createResidence('Residence', 'Test Residence', regAuth.Id, true);
        residenceRec1.Status__c = BCMOH_Constants.AccUnRegisteredStatus;
            Database.Update(residenceRec1,false);
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'Account2', regAuth.Id, true);
       residenceRec2.ParentId =residenceRec1.Id;
           Database.Update(residenceRec2,false); 
        BusinessLicenseApplication bla = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);  
       

        Test.startTest();
         AccountStatusUpdateOnMay send=new AccountStatusUpdateOnMay();
        send.execute(null);

        Test.stopTest();

         Account updatedAccount = [SELECT Id, Status__c FROM Account WHERE Id = :residenceRec1.Id];
        System.assertEquals(BCMOH_Constants.AccUnRegisteredStatus, updatedAccount.Status__c, 'Account status should have been updated.');
}
}