/**
* @Name              : RenewalManagementControllerTest
* @Description       : Test class for RenewalManagementController and RenewalManagementControllerBatch
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-36
**/
@isTest
public class RenewalManagementControllerTest {
    //test data setup
    @testSetup public static void setupData() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        //account with asset and bla
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1',true);
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec1.Id, true);
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.ClassType__c, residenceRec1.Id, true); 
        //account with parent asset
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'residenceAccount2', true);
        Asset unitRec2 = TestDataFactory.createUnit('2', 'Public', 3, residenceRec2.Id, false);
        unitRec2.recordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Database.Insert(unitRec2);
        //account with parent asset
        Account residenceRec3 = TestDataFactory.createResidence('Residence', 'residenceAccount3',true);
        Asset unitRec3 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec3.Id, false);
        unitRec3.recordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        unitRec3.Amount__c = 'Unit Fee';
        Database.Insert(unitRec3);
    }
    //invocable method in RenewalManagementController
    @isTest
    static void getAccountIdsTest() {
        Test.startTest();
        List<String> accIdCount = RenewalManagementController.getAccountIds();
        Test.stopTest();
        Assert.isTrue(Integer.valueOf(accIdCount[0]) > 0);
    }
    //invocable method in RenewalManagementControllerBatch
    @isTest
    static void getsendEmailTestTest() {
        List<String> accNames = new List<String>{'residenceAccount3'};
        List<Id> accIds = new List<Id>();
        for(Account accId : [SELECT Id from Account where Name IN: accNames LIMIT 10]) {
            accIds.add(accId.Id);
        }
        RenewalManagementControllerBatch.FlowInputs accntIds = new RenewalManagementControllerBatch.FlowInputs();
        accntIds.ConId = accIds;
        Test.startTest(); 
        RenewalManagementControllerBatch.sendEmailTest(new List<RenewalManagementControllerBatch.FlowInputs>{accntIds});
        Test.stopTest();
        List<RegulatoryTrxnFeeItem> regTrans = [SELECT Id from RegulatoryTrxnFeeItem LIMIT 10];
        Assert.isNotNull(regTrans.size());
    }
}