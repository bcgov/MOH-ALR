/**
* @Name              : GenerateFeeRecordsTest
* @Description       : Test class for GenerateFeeRecords
* @Author            : Siddharth (Accenture)
* @StoryNo           : ALR-660
**/

@isTest
public class GenerateFeeRecordsTest {
    @isTest
    public static void getRTFIdTest(){
        //test data setup
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        //residence account with bla
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        List<Id> blaIds = new List<String>();
        blaIds.add(blaRec.Id);
        //invocable method in GenerateFeeRecords
        Test.startTest();
        List<String> RTFIds = GenerateFeeRecords.recordCreations(blaIds);
        Test.stopTest();
        Assert.isNotNull(RTFIds.size());
    }
}