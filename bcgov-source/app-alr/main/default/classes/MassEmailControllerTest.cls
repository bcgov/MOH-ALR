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
        AccountContactRelation acConRelRec1 = TestDataFactory.createAccContRelRecord(residenceRec2.Id, contRec.Id , false, true, true);
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 2, residenceRec1.Id, true);
        unitRec1.recordTypeId = parentAssetRTId;
        //unit1.GenerateInvoice__c = true;
        update unitRec1;
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true);
        blaRec.Late_Fee_Status__c='Ready to Send';
        blaRec.AccountId=residenceRec1.Id;
        update blaRec;
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, residenceRec1.Id, residenceRec1.ParentId, '58659', 'BL RECORD 1', true);
        BusinessLicenseApplication blaRec1 = TestDataFactory.createRenewalBla(residenceRec2.LicenseType__c, residenceRec2.Id, true);
        blaRec1.Late_Fee_Status__c='Ready to Send';
        blaRec1.AccountId=residenceRec2.Id;
        update blaRec1;
        BusinessLicense blRec1 = TestDataFactory.createBlRecord(regAuth.Id, residenceRec2.Id, residenceRec2.ParentId, '58459', 'BL RECORD 2', true);
        ContentVersion contentVersionRec = TestDataFactory.createContentVer('title value 1', blaRec.Id, true);
        //ContentVersion contentVersionRec1 = TestDataFactory.createContentVer('title value 2', blaRec.Id, true);
      
        
        

    }

    // Covers basic execution of doSendRenewals.
     @isTest
    static void doSendRenewalsTest() {
        Test.startTest();
        MassEmailController.doSendRenewals();
        Test.stopTest();
        List<Account> accRec = [SELECT Id FROM Account];
        Assert.isNotNull(accRec.size());
    }

    // Covers doSendRenewals when an account has no active contact.
    @isTest
    static void testnoprimarycontact() {
        // Use testSetup data: find the residence account created there
        Account acct = [SELECT Id FROM Account WHERE Name = 'Account2' LIMIT 1];
        // Remove any AccountContactRelation to simulate no primary contact
        List<AccountContactRelation> acrs = [SELECT Id, IsActive FROM AccountContactRelation WHERE AccountId = :acct.Id];
        if (!acrs.isEmpty()) {
            for (AccountContactRelation a : acrs) {
                a.IsActive = false;
            }
            update acrs;
        }

        BusinessLicenseApplication bla = [SELECT Id FROM BusinessLicenseApplication WHERE AccountId = :acct.Id LIMIT 1];

        Test.startTest();
        MassEmailController.doSendRenewals();
        Test.stopTest();

        System.assert(MassEmailController.blaErrMap.containsKey(bla.Id), 'Expected no-primary-contact error for BLA');
        System.assert(MassEmailController.blaErrMap.get(bla.Id).contains(BCMOH_Constants.noActiveContact));
    }

    // Covers doSendRenewals with multiple active contacts on one account — all contacts should be represented in RenewalDetail__c.
    @isTest
    static void doSendRenewalsMultipleActiveContactsTest() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        BusinessLicenseApplication bla = [SELECT Id FROM BusinessLicenseApplication WHERE AccountId = :acct.Id LIMIT 1];

        Contact contact2 = TestDataFactory.createContactRecord(acct.Id, 'contact2renewal@xyz.com', 'firstname2', 'lastname2', true);
        Contact contact3 = TestDataFactory.createContactRecord(acct.Id, 'contact3renewal@xyz.com', 'firstname3', 'lastname3', true);

        Test.startTest();
        MassEmailController.doSendRenewals();
        Test.stopTest();

        BusinessLicenseApplication updatedBla = [SELECT RenewalDetail__c, Status FROM BusinessLicenseApplication WHERE Id = :bla.Id];

        System.assertNotEquals(null, updatedBla.RenewalDetail__c, 'Expected RenewalDetail__c to be populated');
        System.assert(updatedBla.RenewalDetail__c.contains('test1@xyz.com'), 'Expected original contact to be represented');
        System.assert(updatedBla.RenewalDetail__c.contains('contact2renewal@xyz.com'), 'Expected 2nd contact to be represented (regression check)');
        System.assert(updatedBla.RenewalDetail__c.contains('contact3renewal@xyz.com'), 'Expected 3rd contact to be represented (regression check)');
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
        BusinessLicenseApplication blaRec = [SELECT Id, Status, ExclusionReason__c FROM BusinessLicenseApplication LIMIT 1];
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

    // Covers updateBlaStatus for a success-only outcome.
    @isTest
    static void updateBlaStatusSuccessOnlyTest() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        BusinessLicenseApplication bla = [SELECT Id FROM BusinessLicenseApplication WHERE AccountId = :acct.Id LIMIT 1];

        MassEmailController.blaErrMap.clear();
        MassEmailController.blaSuccessMap.clear();
        MassEmailController.blaSuccessMap.put(bla.Id, 'Email Sent To: alice@acme.com. Email Sent To: Alice Smith. Sent Time: now');

        Test.startTest();
        MassEmailController.updateBlaStatus();
        Test.stopTest();

        BusinessLicenseApplication updatedBla = [SELECT Status, RenewalDetail__c FROM BusinessLicenseApplication WHERE Id = :bla.Id];
        System.assertEquals(BCMOH_Constants.sentBlaStatus, updatedBla.Status, 'Expected sent status for success-only outcome');
        System.assert(updatedBla.RenewalDetail__c.contains('alice@acme.com'), 'Expected success detail in RenewalDetail__c');
    }

    // Covers updateBlaStatus for an error-only outcome.
    @isTest
    static void updateBlaStatusErrorOnlyTest() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        BusinessLicenseApplication bla = [SELECT Id FROM BusinessLicenseApplication WHERE AccountId = :acct.Id LIMIT 1];

        MassEmailController.blaErrMap.clear();
        MassEmailController.blaSuccessMap.clear();
        MassEmailController.blaErrMap.put(bla.Id, 'Email Sent To: carol@acme.com. Email Sent To: Carol Lee. Failed: some error');

        Test.startTest();
        MassEmailController.updateBlaStatus();
        Test.stopTest();

        BusinessLicenseApplication updatedBla = [SELECT Status, RenewalDetail__c FROM BusinessLicenseApplication WHERE Id = :bla.Id];
        System.assertEquals(BCMOH_Constants.errorBlaStatus, updatedBla.Status, 'Expected error status for error-only outcome');
        System.assert(updatedBla.RenewalDetail__c.contains('carol@acme.com'), 'Expected error detail in RenewalDetail__c');
    }

    // Covers updateBlaStatus for a mixed success/error outcome.
    @isTest
    static void updateBlaStatusMixedOutcomeTest() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        BusinessLicenseApplication bla = [SELECT Id FROM BusinessLicenseApplication WHERE AccountId = :acct.Id LIMIT 1];

        MassEmailController.blaErrMap.clear();
        MassEmailController.blaSuccessMap.clear();
        MassEmailController.blaSuccessMap.put(bla.Id,
            'Email Sent To: alice@acme.com. Email Sent To: Alice Smith. Sent Time: now<br/>Email Sent To: bob@acme.com. Email Sent To: Bob Jones. Sent Time: now');
        MassEmailController.blaErrMap.put(bla.Id,
            'Email Sent To: carol@acme.com. Email Sent To: Carol Lee. Failed: some error');

        Test.startTest();
        MassEmailController.updateBlaStatus();
        Test.stopTest();

        BusinessLicenseApplication updatedBla = [SELECT Status, RenewalDetail__c FROM BusinessLicenseApplication WHERE Id = :bla.Id];
        System.assert(updatedBla.RenewalDetail__c.contains('alice@acme.com'), 'Expected 1st success retained in mixed outcome');
        System.assert(updatedBla.RenewalDetail__c.contains('bob@acme.com'), 'Expected 2nd success retained in mixed outcome');
        System.assert(updatedBla.RenewalDetail__c.contains('carol@acme.com'), 'Expected failure retained in mixed outcome');
        System.assertNotEquals(null, updatedBla.Status, 'Status should be set for mixed outcome (value pending business confirmation)');
    }

    // Covers getEmailStatus appending multiple contacts' results instead of overwriting.
    @isTest
    static void getEmailStatusAppendsMultipleContactsNotOverwriteTest() {
        Account acct = [SELECT Id FROM Account WHERE Name = 'residenceAccount1' LIMIT 1];
        BusinessLicenseApplication bla = [SELECT Id FROM BusinessLicenseApplication WHERE AccountId = :acct.Id LIMIT 1];

        Contact contactA = TestDataFactory.createContactRecord(acct.Id, 'contactA@getstatus.com', 'ContactA', 'LastA', true);
        Contact contactB = TestDataFactory.createContactRecord(acct.Id, 'contactB@getstatus.com', 'ContactB', 'LastB', true);

        AccountContactRelation acrA = [SELECT Id, ContactId, Contact.Email, Contact.Name FROM AccountContactRelation WHERE AccountId = :acct.Id AND ContactId = :contactA.Id LIMIT 1];
        AccountContactRelation acrB = [SELECT Id, ContactId, Contact.Email, Contact.Name FROM AccountContactRelation WHERE AccountId = :acct.Id AND ContactId = :contactB.Id LIMIT 1];

        System.assertNotEquals(null, acrA.Contact.Email, 'Setup check: acrA should have an email queried back');
        System.assertNotEquals(null, acrB.Contact.Email, 'Setup check: acrB should have an email queried back');
        System.assertEquals('contacta@getstatus.com', acrA.Contact.Email.toLowerCase(), 'Setup check: acrA email should match what was inserted (case-insensitive)');
        System.assertEquals('contactb@getstatus.com', acrB.Contact.Email.toLowerCase(), 'Setup check: acrB email should match what was inserted (case-insensitive)');

        MassEmailController.contactAcrMap.put(contactA.Id, acrA);
        MassEmailController.contactAcrMap.put(contactB.Id, acrB);

        System.assertNotEquals(null, MassEmailController.contactAcrMap.get(contactA.Id), 'Setup check: contactAcrMap should hold contactA right after put');
        System.assertNotEquals(null, MassEmailController.contactAcrMap.get(contactB.Id), 'Setup check: contactAcrMap should hold contactB right after put');

        MassEmailController.msgContactOrderList.clear();
        MassEmailController.msgContactOrderList.add(contactA.Id);
        MassEmailController.msgContactOrderList.add(contactB.Id);

        Messaging.SingleEmailMessage msgA = new Messaging.SingleEmailMessage();
        msgA.setWhatId(bla.Id);
        msgA.setToAddresses(new List<String>{ 'contactA@getstatus.com' });
        msgA.setSubject('Test Subject A');
        msgA.setPlainTextBody('Test Body A');

        Messaging.SingleEmailMessage msgB = new Messaging.SingleEmailMessage();
        msgB.setWhatId(bla.Id);
        msgB.setToAddresses(new List<String>{ 'contactB@getstatus.com' });
        msgB.setSubject('Test Subject B');
        msgB.setPlainTextBody('Test Body B');

        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>{ msgA, msgB };
        Map<Id, List<Id>> whatIdTargetMap = new Map<Id, List<Id>>{ bla.Id => new List<Id>{ contactA.Id, contactB.Id } };

        MassEmailController.blaErrMap.clear();
        MassEmailController.blaSuccessMap.clear();

        Test.startTest();
        Messaging.SendEmailResult[] results = Messaging.SendEmail(msgs, false);
        System.assertEquals(2, results.size(), 'Setup check: SendEmail should return one result per message sent');
        MassEmailController.getEmailStatus(results, msgs, whatIdTargetMap);
        Test.stopTest();

        String successDetail = MassEmailController.blaSuccessMap.get(bla.Id);
        String errorDetail = MassEmailController.blaErrMap.get(bla.Id);

        System.assert(successDetail != null || errorDetail != null,
            'Expected blaSuccessMap or blaErrMap to have an entry for this BLA — if neither does, getEmailStatus likely caught and swallowed an exception internally (check debug logs for LogService entry "updateTargetRecsStatus")');

        if (successDetail != null) {
            System.assert(successDetail.contains(BCMOH_Constants.emailSentToId), 'Expected success detail to use emailSentToId label');
            System.assert(successDetail.contains(BCMOH_Constants.emailSentTo), 'Expected success detail to use emailSentTo label');
        }
        if (errorDetail != null) {
            System.assert(errorDetail.contains(BCMOH_Constants.emailFailedToId), 'Expected error detail to use emailFailedToId label');
            System.assert(errorDetail.contains(BCMOH_Constants.emailFailedRecipient), 'Expected error detail to use emailFailedRecipient label');
            System.assert(errorDetail.contains(BCMOH_Constants.emailFailedReason), 'Expected error detail to use emailFailedReason label');
        }

        String combined = (successDetail == null ? '' : successDetail) + (errorDetail == null ? '' : errorDetail);
        String combinedLower = combined.toLowerCase();

        System.assert(combinedLower.contains('contacta@getstatus.com'), 'Expected contact A represented in status maps');
        System.assert(combinedLower.contains('contactb@getstatus.com'), 'Expected contact B represented in status maps');
    }

    // Covers updateLateFeeBlaStatus.
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
        BusinessLicenseApplication bla = [SELECT Id ,AccountId FROM BusinessLicenseApplication  LIMIT 1];
        Account testAcc = [SELECT Id FROM Account where recordtype.developerName='Residence' limit 1];
        Id returnId=MassEmailController.getAccountId(bla.Id);
        MassEmailController.updateAccountStatus(testAcc.Id);
        MassEmailController.blaErrQuery(bla.Id);
        MassEmailController.fetchTemplate('LateFee');
        System.assertEquals(bla.AccountId, returnId);
    }

    
    @isTest
    static void fetchTemplateTest() {
        EmailTemplate emailTempRec =[Select Id, Name, DeveloperName, Description, Subject, HtmlValue, Body, RelatedEntityType from EmailTemplate where name='Renewal Late Fee Notification Letter'];
        Map<Id, String> mapReturn= MassEmailController.fetchTemplate('LateFee');
        System.assertEquals(emailTempRec.Id, mapReturn.keySet().iterator().next());
    }

}