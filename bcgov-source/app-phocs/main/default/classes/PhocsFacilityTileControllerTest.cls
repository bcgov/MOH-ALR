@isTest
private class PhocsFacilityTileControllerTest {
    @TestSetup
    static void setupTestData() {
        
          // Create RegulatoryAuthorizationType
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(
         Name = 'test reg type'
        );
        insert reg;
       
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Facilityone',
            LicenseType__c = reg.Id,
            Status__c ='Open'
        );
        insert testAccount;
        
  		Account testAccounttwo = new Account(
            Name = 'Test Facilitytwo',
            LicenseType__c = reg.Id,
            Status__c ='Pending'
        );
        insert testAccounttwo;
        
        Account testAccountthree = new Account(
            Name = 'Test Facilitythree',
            LicenseType__c = reg.Id,
            Status__c ='Cancelled'
        );
        insert testAccountthree;
        
        
    }
    
    @isTest
    static void getAccounts(){
        Test.startTest();
        List<Account> results = PhocsFacilityTileController.getfacilities();
        Test.stopTest();
        
         System.assertEquals(2,results.size(),'Only Open and Pending accounts should be returned');
        
        for(Account acc : results) {
            System.assert(acc.Status__c == 'Open' || acc.Status__c == 'Pending','Unexpected status returned');
        }
        System.assertEquals('Test Facilitytwo', results[0].Name);
        System.assertEquals('Test Facilityone', results[1].Name);
        
    }

}