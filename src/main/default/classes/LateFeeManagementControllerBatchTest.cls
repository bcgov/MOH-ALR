/**
* @Name              : LateFeeManagementControllerBatchTest
* @Description       : Test Class to cover batch class LateFeeManagementControllerBatch
* @Author            : Komal Gupta (Accenture)
* @StoryNo           : ALR-997
**/
@isTest
public class LateFeeManagementControllerBatchTest {

    @testSetup public static void setupData() {

        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);

        Account parentRec = new Account(Id = residenceRec1.ParentId,
                                        BillingStreet = 'csd');
        update parentRec;

        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        
        ContentVersion contentVersionRec = TestDataFactory.createContentVer('title value 1', residenceRec1.Id, true);
        Contact contactRec = TestDataFactory.createContactRecord(residenceRec1.Id, 'test@xyz.com', 'fname1', 'lname1', true);
        contactRec.Phone = '8856589554';
        contactRec.MobilePhone = '8856589554';
        update contactRec;
        
        AccountContactRelation acRec = [SELECT Id, ContactId, AccountId from AccountContactRelation LIMIT 1];
        acRec.PrimaryContact__c = true;
        acRec.isActive = true;
        update acRec;
        //AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, residenceRec1.ParentId, '58659', 'BL RECORD 1', true);

        Schema.Location locRec = new Schema.Location(
        Name = 'test',
        LocationType = 'Residence');
        Insert locRec;

        Schema.Address addressRec = new Schema.Address(
            City = 'bl',
            Country = 'TT',
            State = 'JK',
            PostalCode = '885588',
            ParentId = locRec.Id,
            LocationType = 'Residence'
        );
        Insert addressRec;
        locRec.VisitorAddressId = addressRec.Id;
        update locRec;

        Schema.AssociatedLocation asLoc = new Schema.AssociatedLocation(
        ParentRecordId = residenceRec1.Id,
        LocationId = locRec.Id);
        Insert asLoc;

    }
     @isTest
    static void getsendEmailTestTest1() {
        List<BusinessLicense> blRec = [SELECT Id, Account.Name from BusinessLicense];
        List<Asset> assetRec = [SELECT Id, Account.Name from Asset];
        AccountContactRelation acRec = [SELECT Id, ContactId, AccountId, isActive, PrimaryContact__c from AccountContactRelation LIMIT 1];

        List<String> accNames = new List<String>{'residenceAccount1'};
        List<Id> accIds = new List<Id>();
        List<Id> blaIds = new List<Id>();
        for(Account accId : [SELECT Id from Account where Name IN: accNames LIMIT 10]) {
            for(BusinessLicenseApplication blaRec : accId.BusinessLicenseApplicationAccount){
                if(blaRec.Status == 'Excluded'){
                    blaRec.Late_Fee_Status__c = blaRec.Status;
                }else if(BLArec.Status == 'Cancelled'){
                        BLArec.Late_Fee_Status__c = blaRec.Status;
                }
                blaIds.add(blaRec.Id);
            }
            accIds.add(accId.Id);
        }
        Test.startTest(); 
        LateFeeManagementControllerBatch.FlowInputs accntIds = new LateFeeManagementControllerBatch.FlowInputs();
        accntIds.ConId = accIds;
        LateFeeManagementControllerBatch.sendEmailTest(new List<LateFeeManagementControllerBatch.FlowInputs>{accntIds});
        Test.stopTest();
        List<RegulatoryTrxnFeeItem> regTrans = [SELECT Id from RegulatoryTrxnFeeItem LIMIT 10];
        Assert.isNotNull(regTrans.size());
    }
    
    }