@IsTest(seeAllData=false)
private class PhocsBLADocumentChecklistManagerTest{

    private static Account createAccount() {
        RegulatoryAuthorizationType regAuthRec = new RegulatoryAuthorizationType(
        Name = 'Pool Operating Permit',
        RegulatoryAuthCategory = 'Permit',
        RegulatoryAuthorizationCode__c = 'MH',
        RecordTypeId = Schema.SObjectType.RegulatoryAuthorizationType.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryAuthorizationType').getRecordTypeId(),
        LateFee__c = 1,
        OneTimeFee__c = 2,
        PartialUnitFee__c = 3,
        UnitFee__c = 4);
        insert regAuthRec;

        Account facility = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId(),
            Name = 'Test Facility',
            BillingCity = 'TT',
            BillingCountry = 'YY',
            BillingPostalCode = '225522',
            BillingState = 'TT',
            BillingStreet = 'YT',
            LicenseType__c = regAuthRec.Id
        );
        insert facility;

        return  facility;
    }

    private static BusinessLicenseApplication createBLA(String status) {
        Account AccRec = createAccount();
        Id stExam = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('OperatingPermitApplication').getRecordTypeId();
        BusinessLicenseApplication bla = new BusinessLicenseApplication();
        bla.Status = status;
        bla.AccountId = AccRec.Id;
        bla.RecordtypeId= stExam;
        bla.LicenseTypeId = AccRec.LicenseType__c;
        bla.AppliedDate = System.today();
        bla.Category = 'Permit';
        insert bla;

        return bla;
    }

    @TestSetup
    static void setupTestData() {
        // Create a dummy Business License Application
        BusinessLicenseApplication app = createBLA('Open');

        // Create a Document Checklist Item linked to the application
        DocumentChecklistItem dci = new DocumentChecklistItem(
            Name = 'Business License Proof',
            ParentRecordId = app.Id,
            Status = 'Pending',
            IsRequired = true
        );
        insert dci;
    }

    @IsTest
    static void testGetChecklistItems_withDocuments() {
        // Fetch test data
        BusinessLicenseApplication app = [SELECT Id FROM BusinessLicenseApplication LIMIT 1];
        
        DocumentChecklistItem dcl = [select Id From DocumentChecklistItem Limit 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Fake PDF Content'));
        PhocsBLADocumentChecklistManager.uploadFileToChecklist(
            dcl.Id,
            'NewFile.pdf',
            base64Data,
            'application/pdf',
            false
        );

        // Call method
        Test.startTest();
        List<PhocsBLADocumentChecklistManager.DocCheckListItem> result =
            PhocsBLADocumentChecklistManager.getChecklistItems(app.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(0, result.size(), 'Checklist items should be returned');
        PhocsBLADocumentChecklistManager.DocCheckListItem firstItem = result[0];
        System.assertNotEquals(null, firstItem.fileName, 'File name should be populated');
        System.assert(firstItem.hasFileUploaded, 'Should indicate a file has been uploaded');
        System.assert(firstItem.allowDocumentsUpload, 'Upload should be allowed when status is not closed');
    }

    @IsTest
    static void testUploadFileToChecklist_newFile() {
        // Get a DocumentChecklistItem from setup
        DocumentChecklistItem dci = [SELECT Id FROM DocumentChecklistItem LIMIT 1];

        // Create fake file data
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Fake PDF Content'));

        Test.startTest();
        PhocsBLADocumentChecklistManager.DocCheckListItem result =
            PhocsBLADocumentChecklistManager.uploadFileToChecklist(
                dci.Id,
                'NewFile.pdf',
                base64Data,
                'application/pdf',
                false
            );
        Test.stopTest();

        System.assertNotEquals(null, result.contentDocumentId, 'A content document should be created');
        System.assert(result.hasFileUploaded, 'File should be marked as uploaded');
        System.assertEquals('Received', result.Status, 'Status should be set to Received');
    }

    @IsTest
    static void testUploadFileToChecklist_replaceFile() {
        // Get an existing DocumentChecklistItem with a linked file
        DocumentChecklistItem dci = [SELECT Id FROM DocumentChecklistItem LIMIT 1];
      
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Updated File Content'));

        Test.startTest();
         PhocsBLADocumentChecklistManager.DocCheckListItem result =
            PhocsBLADocumentChecklistManager.uploadFileToChecklist(
                dci.Id,
                'UpdatedFile.pdf',
                base64Data,
                'application/pdf',
                true
            );
            result = PhocsBLADocumentChecklistManager.uploadFileToChecklist(
                dci.Id,
                'UpdatedFile1.pdf',
                base64Data,
                'application/pdf',
                true
            );
        Test.stopTest();

        System.assertNotEquals(null, result.contentDocumentId, 'Should still have a content document');
        System.assertEquals('Received', result.Status, 'Status should be Received after upload');
    }
}
