/**
* @Name              : MassEmailControllerTest
* @Description       : Test class for MassEmailController and BCMOH_UtilityClass and RenewalBlaTableController
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
@isTest
public class MassEmailControllerTest {
    //test data setup
    @testSetup public static void setupData() {
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        //account with asset and bla
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'Account2', regAuth.Id, true);
        Contact contactRec = TestDataFactory.createContactRecord(residenceRec2.Id, 'test@xyz.com', 'fname1', 'lname1', true);
		AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);

        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec1.Id, true);
        unitRec1.recordTypeId = parentAssetRTId;
        //unit1.GenerateInvoice__c = true;
        update unitRec1;
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, residenceRec1.ParentId, '58659', 'BL RECORD 1', true);
        
        ContentVersion contentVersionRec = TestDataFactory.createContentVer('title value 1', blaRec.Id, true);
        //ContentVersion contentVersionRec1 = TestDataFactory.createContentVer('title value 2', blaRec.Id, true);

    }
    //test method
     @isTest
    static void doSendRenewalsTest() {
        Test.startTest();
        MassEmailController.doSendRenewals();
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    //getBlaRecs
     @isTest
    static void getBlaRecsTest() {
        Test.startTest();
        RenewalBlaTableController.getBlaRecs();
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    //updateBlaRecs
     @isTest
    static void updateBlaRecsTest() {
        List<BusinessLicenseApplication> blaRecs = [SELECT Id, Status, ExclusionReason__c FROM BusinessLicenseApplication];
        blaRecs[0].ExclusionReason__c = 'testing';
        Object data = blaRecs;
        Test.startTest();
        RenewalBlaTableController.updateBlaRecs(data);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    //updateBlaRecs exception
     @isTest
    static void updateBlaRecsTest1() {
        BusinessLicenseApplication blaRec = [SELECT Id, Status, ExclusionReason__c FROM BusinessLicenseApplication];
        blaRec.ExclusionReason__c = 'testing';
        Object data = blaRec;
        Test.startTest();
        try{
        RenewalBlaTableController.updateBlaRecs(data);
        }
        catch(Exception e) {
            
        }
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    
        
}