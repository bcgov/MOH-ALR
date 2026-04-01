@isTest
public class PHOCSInspectionsHelperTest {
    
    @TestSetup
    static void setupTestData() {
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(
            Name = 'test reg type'
        );
        insert reg;
        
        Account testAccount = new Account(
            Name = 'Test Facility',
            LicenseType__c = reg.Id
        );
        insert testAccount;
        
        ContactPointAddress cpa = new ContactPointAddress(
            Name = 'Test Address',
            Street = '123 Test Lane',
            City = 'Alberta',
            State = 'AL',
            Country = 'Canada',
            PostalCode = '500001'
        );
        insert cpa;
        
        Visit testVisit = new Visit(
            AccountId = testAccount.Id,
            PlaceId = cpa.Id,
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(2)
        );
        insert testVisit;
    }
    
    @isTest
    static void getInspection(){
        Visit inspeciton; 
        Test.startTest();
        inspeciton = PHOCSInspectionsHelper.getInspection([Select id, AccountId from visit].Id);
        Test.stopTest();
        
        System.assertEquals(inspeciton.AccountId, [Select id, AccountId from visit].AccountId);
    }
	@isTest
	static void testGetInspection_ReturnNull() {

    Visit v = [SELECT Id FROM Visit LIMIT 1];
    delete v;

    Test.startTest();
    Visit result = PHOCSInspectionsHelper.getInspection(v.Id);
    Test.stopTest();

    System.assertEquals(null, result);
}    
}