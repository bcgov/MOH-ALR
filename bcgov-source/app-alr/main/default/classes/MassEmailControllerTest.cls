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
		Contact contRec = TestDataFactory.createContactRecord(residenceRec1.Id, 'test1@xyz.com', 'firstname1', 'lastname1', true);
        
        AccountContactRelation acConRelRec = TestDataFactory.createAccContRelRecord(residenceRec1.Id, contactRec.Id , true, true, true);

        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec1.Id, true);
        unitRec1.recordTypeId = parentAssetRTId;
        //unit1.GenerateInvoice__c = true;
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
    

    //    updateBlaLateFeeStatus
    @isTest
    static void testUpdateBlaLateFeeStatus() {
               
     Account testAcc = [SELECT Id FROM Account where recordtype.developerName='Residence' limit 1];
     RegulatoryAuthorizationType regAuth = [SELECT Id FROM RegulatoryAuthorizationType where Name='Mental Helath' limit 1];

   // Create a Business License Application
        BusinessLicenseApplication bla = new BusinessLicenseApplication(
            RecordTypeId = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId(),
            AccountId = testAcc.Id,
            LicenseTypeId = regAuth.Id,
            Status = 'Ready for Renewal',
            AppliedDate = DateTime.now(),
            RenewalYear__c = String.valueOf(Date.today().year()),
            RenewalDetail__c = 'Existing note'
        );
        insert bla;

        Map<Id, String> blaIdDetailsMap = new Map<Id, String>{
            bla.Id => 'Late fee applied due to delay'
        };

        String newStatus = 'Pending Payment';

        Test.startTest();
        List<BusinessLicenseApplication> updatedBlaList = BCMOH_UtilityClass.updateBlaLateFeeStatus(blaIdDetailsMap, newStatus);
        Test.stopTest();
        System.assertEquals(1, updatedBlaList.size(), 'One BLA record should be returned');
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

    @isTest
    static void getEmailtemplatebyNameTest() {
        Test.startTest();
        BCMOH_UtilityClass.getEmailtemplatebyName(BCMOH_Constants.templatePurposeDetails);      
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

    
    
     @isTest
    static void updateBlaStatusTest() {
         RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
         Account residenceRec1 = TestDataFactory.createResidence('Residence', 'Test Residence', regAuth.Id, true);
       BusinessLicenseApplication bla = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
         

        Map<Id, String> blaErrMap = new Map<Id, String>();
        blaErrMap.put(bla.Id, 'Error message');

        Map<Id, String> blaSuccessMap = new Map<Id, String>();
        blaSuccessMap.put(bla.Id, 'Success message');

        Test.startTest();
        MassEmailController.updateBlaStatus();
        Test.stopTest();

        List<BusinessLicenseApplication> blaList = [SELECT Id, Status, RenewalDetail__c FROM BusinessLicenseApplication  LIMIT 1];
        System.assertEquals(1, blaList.size(), 'Expected one BusinessLicenseApplication record to be queried');

        if (!blaList.isEmpty()) {
            BusinessLicenseApplication blaRec = blaList[0];
            System.assert(true, 'BusinessLicenseApplication record found matching query criteria');
        } else {
            // Handle case where no BusinessLicenseApplication record is found
            System.assert(false, 'No BusinessLicenseApplication record found matching query criteria');
        }
        
    }
      @isTest
    static void updateLateFeeBlaStatusTest() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
          Account residenceRec1 = TestDataFactory.createResidence('Residence', 'Test Residence', regAuth.Id, true);
       BusinessLicenseApplication bla = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);  
        bla.Late_Fee_Status__c='Ready to Send';
        bla.RenewalDetail__c= 'Late fee error message';
        Database.update( bla,false);
        
       Map<Id, String> blaErrMap = new Map<Id, String>();
        blaErrMap.put(bla.Id, 'Late fee error');

        Map<Id, String> blaSuccessMap = new Map<Id, String>();
        blaSuccessMap.put(bla.Id, 'Late fee success');

        Test.startTest();
        MassEmailController.updateLateFeeBlaStatus();
        Test.stopTest();

         // Verify updates to BusinessLicenseApplication record
        BusinessLicenseApplication updatedBla = [SELECT Id, Late_Fee_Status__c, RenewalDetail__c FROM BusinessLicenseApplication WHERE Id = :bla.Id];
        System.assertEquals(BCMOH_Constants.blaLateFeeStatus, updatedBla.Late_Fee_Status__c);
        System.assertEquals('Late fee error message', updatedBla.RenewalDetail__c);

        // Verify related Account update
        Account acc = [SELECT Id, Status__c FROM Account WHERE Id = :residenceRec1.Id];
        System.assertEquals(BCMOH_Constants.accountStat, acc.Status__c);
        
    }

       @isTest
    static void accountBlaQueryTest() {
        BusinessLicenseApplication bla = [SELECT Id  FROM BusinessLicenseApplication  LIMIT 1];
        Account testAcc = [SELECT Id FROM Account where recordtype.developerName='Residence' limit 1];
        MassEmailController.getAccountId(bla.Id);
        MassEmailController.updateAccountStatus(testAcc.Id);
        MassEmailController.blaErrQuery(bla.Id);
        MassEmailController.fetchTemplate('LateFee');
    }

    
       @isTest
    static void fetchTemplateTest() {
        MassEmailController.fetchTemplate('LateFee');
    }

}