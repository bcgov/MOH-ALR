/**
* @Name              : RegulatoryTrxnFeeNewTriggerTest
* @Description       : Test class for RegulatoryTrxnFeeNewTrigger
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-1289
**/

@isTest
private class RegulatoryTrxnFeeNewTriggerTest {

    static testMethod void testTrigger() {
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, Status__c = 'Registered Inactive'));
        }
        insert testAccounts;
        
        List<RegulatoryTrxnFee> testFees = new List<RegulatoryTrxnFee>();
        for(Account acc : testAccounts) {
            testFees.add(new RegulatoryTrxnFee(AccountId = acc.Id, FeeType__c = 'Renewal Unit Fee', Status = 'Due'));
        }
        testFees[0].Status = 'Paid';
        insert testFees;
        
        testFees[1].Status = 'Paid';
        update testFees;
        
        List<Account> updatedAccounts = [SELECT Status__c FROM Account WHERE Id IN :testAccounts];
        System.assertEquals('Registered Active', updatedAccounts[1].Status__c, 'Account status should change to "Registered Active" if all fees are paid');
          }
}