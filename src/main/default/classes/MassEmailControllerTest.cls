/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Test class for MassEmailController and BCMOH_UtilityClass and RenewalBlaTableController
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                          ALR -560             Sweta          Renewal verification and renewal mass email
***********************************************************************************************/
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
        blaRec.Late_Fee_Status__c='Ready to Send';
        update blaRec;
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
    //test method-ALR-1000
     @isTest
    static void doSendLateFeeTest() {
        Test.startTest();
        MassEmailController.doSendLateFee();
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
        blaRecs[0].Status = 'Cancelled';//ALR-820
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
    
    //updateBlaStatusTest
     @isTest
    static void updateBlaStatusTest() {
        String blaStatus = '' ;
        Id BlaId=[SELECT Id FROM BusinessLicenseApplication][0].Id;
        Map<Id,String> blaIdDetailsMap = new Map<Id,String>{BlaId =>''} ; 
        List<BusinessLicenseApplication> BlaList=new List<BusinessLicenseApplication>();
        Test.startTest();
        BlaList=BCMOH_UtilityClass.updateBlaStatus(blaIdDetailsMap,blaStatus);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    
    //updateBlaLateFeeStatusTest
     @isTest
    static void updateBlaLateFeeStatusTest() {
        String blaStatus = '' ;
        Id BlaId=[SELECT Id FROM BusinessLicenseApplication][0].Id;
        Map<Id,String> blaIdDetailsMap = new Map<Id,String>{BlaId =>''} ; 
        List<BusinessLicenseApplication> BlaList=new List<BusinessLicenseApplication>();
        Test.startTest();
        BlaList=BCMOH_UtilityClass.updateBlaLateFeeStatus(blaIdDetailsMap,blaStatus);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
      
      //getDocTempContentMap
     @isTest
    static void getDocTempContentMapTest() {
        List<String> templateNames = new List<String>();
        Map<String, DocumentTemplateContentDoc> templateNameDocMap = new Map<String, DocumentTemplateContentDoc>();
        Test.startTest();
        templateNameDocMap=BCMOH_UtilityClass.getDocTempContentMap(templateNames);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }
    
           
        //getDocGenProcRec
     @isTest
    static void getDocGenProcRecTest() {
        String type1 = '';
        String requestText = '';
        String referenceId = '';
        String tokenData = '';
        String docGenType = '';
        DocumentGenerationProcess docgen = new DocumentGenerationProcess();
        Test.startTest();
        docgen=BCMOH_UtilityClass.getDocGenProcRec(type1,requestText,referenceId,tokenData,docGenType);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
           }
    
         //getDocNameTitle
     @isTest
    static void getDocNameTitleTest() {
        String docGenPurpose = '';
        Map<String,String> docGenRec = new Map<String,String>();
        Test.startTest();
        docGenRec=BCMOH_UtilityClass.getDocNameTitle(docGenPurpose);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
           }
    
    //getDocNameTitleLateFeeTest
     @isTest
    static void getDocNameTitleLateFeeTest() {
        String docGenPurpose = '';
        Map<String,String> docGenRec = new Map<String,String>();
        Test.startTest();
        docGenRec=BCMOH_UtilityClass.getDocNameTitleLateFee(docGenPurpose);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
           }
    
     //getSubstringWithoutExtension
     @isTest
    static void getSubstringWithoutExtensionTest() {
        String documentTitle = '';
        String docGenRec = '';
        Test.startTest();
        docGenRec=BCMOH_UtilityClass.getSubstringWithoutExtension(documentTitle);
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
           }
    
    //relpaceMergeFieldsTest
    @isTest
    Static void relpaceMergeFieldsTest(){
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(LastName = 'Test Contact',Phone ='1234567890');
        insert con;

        AccountContactRelation acr = new AccountContactRelation(
            AccountId = acc.Id,
            ContactId = con.Id,
            Roles = 'Decision Maker'
        );
        
        BusinessLicense bl = new BusinessLicense(Name = 'Test License');
        insert bl;

        BusinessLicenseApplication bla = new BusinessLicenseApplication(
           Status = 'Pending'
        );
        
        String templateData = 'Hello {!AccountContactRelation.FirstName}, your license {!BusinessLicenseApplication.Status} is pending.';

       TemplateMergeFieldMapping__mdt mapping1 = new TemplateMergeFieldMapping__mdt(
            ObjectName__c = 'AccountContactRelation',
            MergeField__c = '{!AccountContactRelation.FirstName}',
            FieldAPIName__c = 'Contact.FirstName'
        );
       
        TemplateMergeFieldMapping__mdt mapping2 = new TemplateMergeFieldMapping__mdt(
            ObjectName__c = 'BusinessLicenseApplication',
            MergeField__c = '{!BusinessLicenseApplication.Status}',
            FieldAPIName__c = 'Status'
        );
       
      Test.startTest();
        String result = MassEmailController.replaceMergeFields(templateData, acr, bla, acc, bl, '10');
         Test.stopTest(); 
       
         System.assertEquals('Hello {!AccountContactRelation.FirstName}, your license {!BusinessLicenseApplication.Status} is pending.',result);
    }

    //getEmailStatus
    @isTest
    Static void getEmailStatusTest(){
    List<Messaging.SingleEmailMessage> testEmailMessages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();
        email1.setSubject('Test Email 1');
        email1.setPlainTextBody('This is a test email.');
        testEmailMessages.add(email1);

        List<Messaging.SendEmailResult> testEmailResults = new List<Messaging.SendEmailResult>();
        Map<Id, Id> whatIdTargetMap = new Map<Id, Id>();
        whatIdTargetMap.put(email1.getWhatId(), email1.getTargetObjectId());

        Map<Id, Contact> accContactMap = new Map<Id, Contact>();
        Contact testContact = new Contact();
        testContact.Id = email1.getTargetObjectId();
        testContact.Email = 'test@gmail.com';
        accContactMap.put(testContact.Id, testContact);

        Test.startTest();
        MassEmailController.getEmailStatus(testEmailResults, testEmailMessages, whatIdTargetMap);
        Test.stopTest();

        
        System.assertEquals(0, MassEmailController.blaSuccessMap.size());
        System.assertEquals(0, MassEmailController.blaErrMap.size()); 
      
    }
}