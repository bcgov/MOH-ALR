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
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);        
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec1.Id, true);
        system.debug('csvcsdsdc'+unitRec1+' '+unitRec1.AccountId);
        //account with parent asset
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'residenceAccount2', regAuth.Id, true);
        Asset unitRec2 = TestDataFactory.createUnit('2', 'Public', 3, residenceRec2.Id, false);
        unitRec2.recordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Database.Insert(unitRec2);
        //account with parent asset
        Account residenceRec3 = TestDataFactory.createResidence('Residence', 'residenceAccount3', regAuth.Id, true);
        Asset unitRec3 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec3.Id, false);
        unitRec3.recordTypeId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        unitRec3.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec3);
        //content version
        ContentVersion contentVersionRec = TestDataFactory.createContentVer('title value 1', blaRec.Id, true);
        DocumentTemplate docTemp = new DocumentTemplate();
        docTemp.Name = 'test template';
        //other data
        //Account residenceRec2 = TestDataFactory.createResidence('Residence', 'residenceAccount2', regAuth.Id, true);
        Contact contactRec = TestDataFactory.createContactRecord(residenceRec2.Id, 'test@xyz.com', 'fname1', 'lname1', true);
		AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);
        //Asset unitRec2 = TestDataFactory.createUnit('3', 'Public', 2, residenceRec1.Id, true);
        //BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, '58659', 'BL RECORD 1', true);
        BusinessLicense blRec2 = TestDataFactory.createBlRecord(regAuth.Id, residenceRec2.Id, '58659', 'BL RECORD 2', true);
        BusinessLicense blRec3 = TestDataFactory.createBlRecord(regAuth.Id, residenceRec3.Id, '58659', 'BL RECORD 3', true);
        //Location
        Schema.Location locRec = new Schema.Location(
        Name = 'test',
        LocationType = 'Residence');
        Insert locRec;
        //Address
        Schema.Address addressRec = new Schema.Address(
            City = 'bl',
            Country = 'TT',
            State = 'JK',
            PostalCode = '885588',
            ParentId = locRec.Id,
            LocationType = 'Residence'
        );
        Insert addressRec;
        Schema.AssociatedLocation asLoc = new Schema.AssociatedLocation(
        ParentRecordId = residenceRec1.Id,
        LocationId = locRec.Id);
        Insert asLoc;
        //}
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
    /*@isTest
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
    }*/
    //testing for serversidedocgen
    @isTest
    static void getsendEmailTestTest1() {
        List<BusinessLicense> blRec = [SELECT Id, Account.Name from BusinessLicense];
        List<Asset> assetRec = [SELECT Id, Account.Name from Asset];
        system.debug('csd'+assetRec);
        List<String> accNames = new List<String>{'residenceAccount1'};
        List<Id> accIds = new List<Id>();
        for(Account accId : [SELECT Id from Account where Name IN: accNames LIMIT 10]) {
            accIds.add(accId.Id);
        }
        accIds = new List<Id>();
        RenewalManagementControllerBatch.FlowInputs accntIds = new RenewalManagementControllerBatch.FlowInputs();
        accntIds.ConId = accIds;
        Test.startTest(); 
        RenewalManagementControllerBatch.sendEmailTest(new List<RenewalManagementControllerBatch.FlowInputs>{accntIds});
        Test.stopTest();
        List<RegulatoryTrxnFeeItem> regTrans = [SELECT Id from RegulatoryTrxnFeeItem LIMIT 10];
        Assert.isNotNull(regTrans.size());
    }
}