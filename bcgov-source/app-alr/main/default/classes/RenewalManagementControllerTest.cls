/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Test class for RenewalManagementController and RenewalManagementControllerBatch
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-36             Sweta           License renewal initiation
***********************************************************************************************/
@isTest
public class RenewalManagementControllerTest {
    //test data setup
    @testSetup public static void setupData() {
        //fetch record type Ids
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);

        //account - insert scenario
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        residenceRec1.Status__c = 'Registered Active';
        update residenceRec1;
        //registrant billing address
        Account parentRec = new Account(Id = residenceRec1.ParentId,
                                        BillingStreet = 'csd');
        update parentRec;
        //bla
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, false); 
        String blaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
        blaRec.recordTypeId = blaRecTypeId;
        blaRec.AccountId = residenceRec1.Id;
        blaRec.LicenseTypeId = residenceRec1.LicenseType__c;
        blaRec.Status = 'Cancelled';
        blaRec.AppliedDate = DateTime.now();
        blaRec.RenewalYear__c = String.valueOf(Date.today().year());
        Database.Insert(blaRec);
        
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
        
        AccountContactRelation acRec = [SELECT Id, ContactId, AccountId FROM AccountContactRelation LIMIT 1];
        system.debug('csdcsd'+acRec);
        acRec.PrimaryContact__c = true;
        acRec.isActive = true;
        update acRec;
        //AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, residenceRec1.ParentId, '58659', 'BL RECORD 1', true);
        
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
        locRec.VisitorAddressId = addressRec.Id;
        update locRec;
        //associate location
        Schema.AssociatedLocation asLoc = new Schema.AssociatedLocation(
        ParentRecordId = residenceRec1.Id,
        LocationId = locRec.Id);
        Insert asLoc;
        system.debug('cscds AssociatedLocation '+asLoc);
        
        //account 2
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'Account2', regAuth.Id, true);
        
        
    }
    //RenewalManagementControllerBatch coverage
     @isTest
    static void getsendEmailTestTest1() {
        //List<BusinessLicense> blRec = [SELECT Id, Account.Name FROM BusinessLicense];
        List<Asset> assetRec = [SELECT Id, Account.Name FROM Asset];
        AccountContactRelation acRec = [SELECT Id, ContactId, AccountId, isActive, PrimaryContact__c FROM AccountContactRelation LIMIT 1];
        
        system.debug('csd'+acRec+' '+assetRec);
        List<String> accNames = new List<String>{'residenceAccount1'};
        List<Id> accIds = new List<Id>();
        for(Account accId : [SELECT Id FROM Account WHERE Name IN: accNames LIMIT 10]) {
            accIds.add(accId.Id);
        }
        system.debug('csd'+accIds);
        Test.startTest(); 
        RenewalManagementController.fetchAccounts();
        RenewalManagementControllerBatch.enqueueJob(accIds);
        //accntIds.ConId = accIds;
        //RenewalManagementControllerBatch.sendEmailTest(new List<RenewalManagementControllerBatch.FlowInputs>{accntIds});
        Test.stopTest();
        List<RegulatoryTrxnFeeItem> regTrans = [SELECT Id FROM RegulatoryTrxnFeeItem LIMIT 10];
        Assert.isNotNull(regTrans.size());
    }
    //Annual Renewal Fee - added for an account included in the renewal when the License Type has the fee configured
    @isTest
    static void annualRenewalFeeAddedForIncludedAccountTest() {
        RegulatoryAuthorizationType licenseType = [SELECT Id FROM RegulatoryAuthorizationType LIMIT 1];
        licenseType.AnnualRenewalFee__c = 500;
        update licenseType;
        List<Id> accIds = new List<Id>();
        for(Account accRec : [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1]) {
            accIds.add(accRec.Id);
        }
        Test.startTest();
        RenewalManagementControllerBatch.enqueueJob(accIds);
        Test.stopTest();
        List<RegulatoryTrxnFeeItem> annualItems = [SELECT Id, Name, Amount__c, Quantity__c, FeeAmount, FeeType__c, Unit__c, RegulatoryTrxnFee.FeeType__c
                                                   FROM RegulatoryTrxnFeeItem WHERE Name =: BCMOH_Constants.annualRenewalFeeType];
        Assert.areEqual(1, annualItems.size(), 'One Annual Renewal Fee item expected for the included account');
        Assert.areEqual(500, annualItems[0].Amount__c);
        Assert.areEqual(1, annualItems[0].Quantity__c);
        Assert.areEqual(500, annualItems[0].FeeAmount);
        Assert.areEqual(BCMOH_Constants.annualRenewalFeeType, annualItems[0].FeeType__c);
        Assert.isNull(annualItems[0].Unit__c);
        Assert.areEqual(BCMOH_Constants.feeType, annualItems[0].RegulatoryTrxnFee.FeeType__c, 'Item must sit on the Renewal Unit Fee header');
        //unit fee items are still created as before
        Assert.isTrue([SELECT COUNT() FROM RegulatoryTrxnFeeItem WHERE FeeType__c =: BCMOH_Constants.feeType AND Unit__c != NULL] > 0);
    }
    //Annual Renewal Fee - not added for an account that is not included in the renewal (Excluded)
    @isTest
    static void annualRenewalFeeNotAddedForExcludedAccountTest() {
        RegulatoryAuthorizationType licenseType = [SELECT Id FROM RegulatoryAuthorizationType LIMIT 1];
        licenseType.AnnualRenewalFee__c = 500;
        update licenseType;
        Test.startTest();
        RenewalManagementControllerBatch.enqueueJob(new List<Id>());
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM RegulatoryTrxnFeeItem WHERE Name =: BCMOH_Constants.annualRenewalFeeType]);
        //unit fee items are still created as before
        Assert.isTrue([SELECT COUNT() FROM RegulatoryTrxnFeeItem WHERE FeeType__c =: BCMOH_Constants.feeType AND Unit__c != NULL] > 0);
    }
    //Annual Renewal Fee - not added when the License Type does not have the fee configured
    @isTest
    static void annualRenewalFeeNotAddedWhenNotConfiguredTest() {
        List<Id> accIds = new List<Id>();
        for(Account accRec : [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1]) {
            accIds.add(accRec.Id);
        }
        Test.startTest();
        RenewalManagementControllerBatch.enqueueJob(accIds);
        Test.stopTest();
        Assert.areEqual(0, [SELECT COUNT() FROM RegulatoryTrxnFeeItem WHERE Name =: BCMOH_Constants.annualRenewalFeeType]);
        Assert.isTrue([SELECT COUNT() FROM RegulatoryTrxnFeeItem WHERE FeeType__c =: BCMOH_Constants.feeType AND Unit__c != NULL] > 0);
    }
    //invocable method in RenewalManagementController
    @isTest
    static void getAccountIdsTest() {
        Test.startTest();
        List<Account> accIdCount = RenewalManagementController.getAccountIds();
        Test.stopTest();
        Assert.isNotNull(accIdCount.size());
    }
}