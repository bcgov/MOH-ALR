@IsTest
private class PhocsRecordFileManagerTest {

    @TestSetup
    static void setupTestData() {
        // Create a sample parent record (e.g., Account)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a ContentDocument
        ContentDocument doc = new ContentDocument(
            Title = 'Test Document',
            FileType = 'PDF'
        );
        insert doc;

        // Create a ContentVersion (must be inserted with ContentDocumentId null)
        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test file content'),
            IsLatest = true
        );
        insert version;

        // The ContentDocument is automatically created when ContentVersion is inserted,
        // so we query it back to link to the Account.
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId, Title, CreatedDate
            FROM ContentVersion
            WHERE Id = :version.Id
        ];

        // Create ContentDocumentLink to link the file to the parent record
        ContentDocumentLink link = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = acc.Id,
            ShareType = 'V', // Viewer permission
            Visibility = 'AllUsers'
        );
        insert link;
    }

    @IsTest
    static void testGetDocumentsList_WithValidRecordId() {
        // Retrieve the Account created in @TestSetup
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<PhocsRecordFileManager.DocumentDetail> result = PhocsRecordFileManager.getDocumentsList(acc.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Documents list should not be empty');
        PhocsRecordFileManager.DocumentDetail docDetail = result[0];

        System.assertNotEquals(null, docDetail.contentDocumentId, 'ContentDocumentId should not be null');
        System.assertEquals(acc.Id, docDetail.parentRecordId, 'ParentRecordId should match');
        System.assert(docDetail.downloadUrl.startsWith('/sfc/servlet.shepherd/document/download/'),
                      'Download URL should be properly formatted');
        System.assert(docDetail.previewUrl.contains('/lightning/r/ContentDocument/'),
                      'Preview URL should be properly formatted');
    }

}
