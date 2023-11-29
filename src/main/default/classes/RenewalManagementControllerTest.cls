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
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', true);
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
        Database.Insert(unitRec3);
    }
    //method to call the batch class
    @isTest
    static void execRenewalBatchTest() {
        List<String> accNames = new List<String>{'residenceAccount3'};
        List<Id> accIds = new List<Id>();
        for(Account accId : [SELECT Id from Account where Name IN: accNames LIMIT 10]) {
            accIds.add(accId.Id);
        }
        Test.startTest(); 
        Database.executeBatch(new RenewalManagementControllerBatch(accIds));
        Test.stopTest();
    }
    //invocable method in RenewalManagementController
    @isTest
    static void getAccountIdsTest() {
        Test.startTest();
        RenewalManagementController.getAccountIds();
        Test.stopTest();
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
    }
}