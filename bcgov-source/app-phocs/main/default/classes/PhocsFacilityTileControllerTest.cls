@isTest(SeeAllData=true)
private class PhocsFacilityTileControllerTest {
    
    @isTest
    static void getAccounts() {
        
        User portalUser = [
            SELECT Id, AccountId
            FROM User
            WHERE Profile.Name = 'Customer Community Operator'
            LIMIT 1
        ];
        
        Test.startTest();
        
        System.runAs(portalUser) {
            List<Account> facilities = PhocsFacilityTileController.getfacilities();
            
            System.assert(facilities.size() > 0,'Expected at least one facility.');
            
            for (Account acc : facilities) {
                System.assertNotEquals(null, acc.Id);
                System.assertNotEquals(null, acc.Name);
            }
        }
        
        Test.stopTest();
    }
}