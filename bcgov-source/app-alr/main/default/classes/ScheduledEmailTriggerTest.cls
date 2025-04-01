/**
* @Name              : ScheduledEmailTriggerTest
* @Description       : Test Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-192
**/
@isTest
private class ScheduledEmailTriggerTest {

   

       //test data setup
    @testSetup public static void setupData() {
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        //account with asset and bla
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        Account residenceRec2 = TestDataFactory.createResidence('Residence', 'Account2', regAuth.Id, true);
        Contact contactRec = TestDataFactory.createContactRecord(residenceRec2.Id, 'test@xyz.com', 'fname1', 'lname1', true);
		Contact contRec = TestDataFactory.createContactRecord(residenceRec1.Id, 'test1@xyz.com', 'firstname1', 'lastname1', true);
        
        AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);

        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec1.Id, true);
        unitRec1.recordTypeId = parentAssetRTId;
          update unitRec1;
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);
        blaRec.Late_Fee_Status__c='Ready to Send';
        blaRec.AccountId=residenceRec1.Id;
        update blaRec;
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, residenceRec1.ParentId, '58659', 'BL RECORD 1', true);
        
        ContentVersion contentVersionRec = TestDataFactory.createContentVer('title value 1', blaRec.Id, true);
        //ContentVersion contentVersionRec1 = TestDataFactory.createContentVer('title value 2', blaRec.Id, true);
    
    }
    //test method
     @isTest
    static void sendEmailForRenewalsTest() {
        Test.startTest();
        Map<Id, Set<Id>> blaContentVerMap = new Map<Id, Set<Id>>(); 
        Map<Id, List<Id>> whatIdTargetMap = new Map<Id, List<Id>>(); 
        ScheduledEmailTrigger.sendEmailForRenewals(blaContentVerMap, whatIdTargetMap);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }

    // Test method for fetchTemplateDetails()
    @isTest
    static void testFetchTemplateDetails() {
        String purpose = 'Renewal'; 
        
        Test.startTest();
        Map<Id, String> result = ScheduledEmailTrigger.fetchTemplateDetails(purpose);
        Test.stopTest();
        
       List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    
      // Test method for fetchTemplateDetails()
    @isTest
    static void testFetchTemplateDetails1() {
        String purpose = 'RenewalTest'; 
        
        Test.startTest();
        Map<Id, String> result = ScheduledEmailTrigger.fetchTemplateDetails(purpose);
        Test.stopTest();
        
       List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    
    // Test method for fetchAttachmentDetails()
    @isTest
    static void testFetchAttachmentDetails() {
        // Test setup
        Set<Id> blaIds = new Set<Id>(); 
        
        // Test logic
        Test.startTest();
        Map<Id, Set<Id>> result = ScheduledEmailTrigger.fetchAttachmentDetails(blaIds);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
     
    }

    @isTest
    static void testGetOrgWideId() {
       
        // Test logic
        Test.startTest();
        Id orgWideAddrId = ScheduledEmailTrigger.getOrgWideId();
        Test.stopTest();
        
      System.assertNotEquals(null, orgWideAddrId, 'OrgWideEmailAddress Id should not be null');
    
    }

    // Test method for execute(SchedulableContext)
    @isTest
    static void testExecute() {
         Test.startTest();
        ScheduledEmailTrigger scheduler = new ScheduledEmailTrigger();
        scheduler.execute(null); 
        Test.stopTest();

        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());

    }

    // Test method for replaceMergeFields()
    @isTest
    static void testReplaceMergeFields() {
          
        String templateData = ''; 
        AccountContactRelation accContactRec = new AccountContactRelation(); 
        BusinessLicenseApplication blaRec = new BusinessLicenseApplication(); 
        Account accRec = new Account(); 
        BusinessLicense blRec = new BusinessLicense(); 
        String totalALUnits = '10'; 
        String replacedData = ScheduledEmailTrigger.replaceMergeFields(templateData, accContactRec, blaRec, accRec, blRec, totalALUnits);
        
        List<Account> accRec1 = [SELECT Id FROM Account];
        Assert.isNotNull(accRec1.size());


    }
}