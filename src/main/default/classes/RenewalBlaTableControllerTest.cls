@isTest
public class RenewalBlaTableControllerTest {

    //test data setup
    @testSetup public static void setupData() {
        //fetch record type Ids
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        
        //account - insert scenario
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        //registrant billing address
        Account parentRec = new Account(Id = residenceRec1.ParentId,
                                        BillingStreet = 'csd');
        update parentRec;
        //bla
        //BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        //asset parent
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 5, residenceRec1.Id, false);
        unitRec1.recordTypeId = parentAssetRTId;
        unitRec1.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec1);
        system.debug('cs'+unitRec1);
        
        //asset child
        Asset unitRec2 = TestDataFactory.createUnit('1', 'Private', 3, residenceRec1.Id, false);
        unitRec2.recordTypeId = childAssetRTId;
        unitRec2.parentId = unitRec1.Id;
        Database.Insert(unitRec2);
        system.debug('cs d '+unitRec2);
        
        //asset parent Public
        Asset unitRec3 = TestDataFactory.createUnit('1', 'Public', 5, residenceRec1.Id, false);
        unitRec3.recordTypeId = parentAssetRTId;
        unitRec3.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec3);
        system.debug('cs'+unitRec3);
        
        //asset child Public
        Asset unitRec4 = TestDataFactory.createUnit('1', 'Public', 3, residenceRec1.Id, false);
        unitRec4.recordTypeId = childAssetRTId;
        unitRec4.parentId = unitRec3.Id;
        Database.Insert(unitRec4);
        system.debug('cs d '+unitRec4);
        
        //asset parent Per Diem
        Asset unitRec5 = TestDataFactory.createUnit('1', 'Per Diem', 5, residenceRec1.Id, false);
        unitRec5.recordTypeId = parentAssetRTId;
        unitRec5.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec5);
        system.debug('cs'+unitRec5);
        
        //asset child Public
        Asset unitRec6 = TestDataFactory.createUnit('1', 'Per Diem', 3, residenceRec1.Id, false);
        unitRec6.recordTypeId = childAssetRTId;
        unitRec6.parentId = unitRec5.Id;
        Database.Insert(unitRec6);
        system.debug('cs d '+unitRec6);
        
        //asset parent Per Diem
        Asset unitRec7 = TestDataFactory.createUnit('1', 'Independent Living', 5, residenceRec1.Id, false);
        unitRec7.recordTypeId = parentAssetRTId;
        unitRec7.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec7);
        system.debug('cs'+unitRec7);
        
        //asset child Public
        Asset unitRec8 = TestDataFactory.createUnit('1', 'Independent Living', 3, residenceRec1.Id, false);
        unitRec8.recordTypeId = childAssetRTId;
        unitRec8.parentId = unitRec7.Id;
        Database.Insert(unitRec8);
        system.debug('cs d '+unitRec8);
        
        ContentVersion contentVersionRec = TestDataFactory.createContentVer('title value 1', residenceRec1.Id, true);
        Contact contactRec = TestDataFactory.createContactRecord(residenceRec1.Id, 'test@xyz.com', 'fname1', 'lname1', true);
        contactRec.Phone = '8856589554';
        contactRec.MobilePhone = '8856589554';
        update contactRec;
        
        AccountContactRelation acRec = [SELECT Id, ContactId, AccountId from AccountContactRelation LIMIT 1];
        system.debug('csdcsd'+acRec);
        acRec.PrimaryContact__c = true;
        acRec.isActive = true;
        update acRec;
		//AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, '58659', 'BL RECORD 1', true);
        
        //Location
        Schema.Location locRec = new Schema.Location(
        Name = 'test',
        LocationType = 'Residence');
        Insert locRec;
        system.debug('cscds'+locRec);
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
        system.debug('cscds addressRec '+addressRec);
        Schema.AssociatedLocation asLoc = new Schema.AssociatedLocation(
        ParentRecordId = residenceRec1.Id,
        LocationId = locRec.Id);
        Insert asLoc;
        system.debug('cscds AssociatedLocation '+asLoc);
        
        //account 2
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'residenceAccount2', regAuth.Id, true);
        
        
    }
     @isTest
    static void getsendEmailTestTest1() {
        List<BusinessLicense> blRec = [SELECT Id, Account.Name from BusinessLicense];
        List<Asset> assetRec = [SELECT Id, Account.Name from Asset];
        AccountContactRelation acRec = [SELECT Id, ContactId, AccountId, isActive, PrimaryContact__c from AccountContactRelation LIMIT 1];
        
        system.debug('csd'+acRec+' '+assetRec);
        List<String> accNames = new List<String>{'residenceAccount1'};
        List<Id> accIds = new List<Id>();
        for(Account accId : [SELECT Id from Account where Name IN: accNames LIMIT 10]) {
            accIds.add(accId.Id);
        }
        system.debug('csd'+accIds);
        Test.startTest(); 
        RenewalManagementControllerBatch.FlowInputs accntIds = new RenewalManagementControllerBatch.FlowInputs();
        accntIds.ConId = accIds;
        RenewalManagementControllerBatch.sendEmailTest(new List<RenewalManagementControllerBatch.FlowInputs>{accntIds});
        Test.stopTest();
        List<RegulatoryTrxnFeeItem> regTrans = [SELECT Id from RegulatoryTrxnFeeItem LIMIT 10];
        Assert.isNotNull(regTrans.size());
    }
}