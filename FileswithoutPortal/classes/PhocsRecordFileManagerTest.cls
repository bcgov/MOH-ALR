@IsTest
private class PhocsRecordFileManagerTest {

    @TestSetup
    static void setupTestData() {

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

        // Create a sample parent record (e.g., Account)
        Account acc = new Account(Name = 'Test Account', LicenseType__c = regAuthRec.Id);
        insert acc;

        ContentVersion newVersion = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test file content'),
            Origin = 'H'
        );
        newVersion.FirstPublishLocationId = acc.Id;  // brand-new file, link created once automatically
        insert newVersion;
    }

    @IsTest
    static void testGetDocumentsList_WithValidRecordId() {
        // Retrieve the Account created in @TestSetup
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<PhocsRecordFileManager.DocumentDetail> result = PhocsRecordFileManager.getDocumentsList(acc.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Documents list should not be empty');     
    }

}
