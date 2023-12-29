/**
* @Name              : ComplaintTriggerHandlerTest
* @Description       : Test class for ComplaintCaseTriggerHandler and ComplaintCaseTrigger
* @Author            : Sri Teja (Accenture)
* @StoryNo           : ALR-509
**/


@isTest
public class ComplaintTriggerHandlerTest {

    @isTest
    static void testBeforeInsert() {
        // Assuming you have an existing Regulatory Authorization Type record
        RegulatoryAuthorizationType testRegulatoryAuthorizationType = new RegulatoryAuthorizationType(
            Name = 'Test Regulatory Authorization Type',
            RegulatoryAuthorizationCode__c = 'MH'
        );
        insert testRegulatoryAuthorizationType;

        // Create a test Account with LicenseType__c lookup
        Account testAccount = new Account(
            Name = 'Test Account',
            LicenseType__c = testRegulatoryAuthorizationType.Id
        );
        insert testAccount;

        // Query the required information outside the loop
        Map<Id, RegulatoryAuthorizationType> regulatoryAuthorizationTypes = new Map<Id, RegulatoryAuthorizationType>(
            [SELECT Id, Name, RegulatoryAuthorizationCode__c FROM RegulatoryAuthorizationType WHERE Id = :testRegulatoryAuthorizationType.Id]
        );

        // Test Scenario 1: Insert a single Case successfully
        Case testCase1 = new Case(
            Subject = 'Test Subject 1',
            AccountId = testAccount.Id,
            WishtoRemainAnonymous__c = 'No',
            NeedFeedbackOnResolution__c = 'No',
            ResidentAwareofComplaint__c = 'No'
            // Add other required fields as needed
        );

        // Start the test context
        Test.startTest();

        // Insert the test Case record, which should invoke the trigger
        insert testCase1;

        // Query the database to verify the changes
        Case updatedCase1 = [SELECT Id, RecordType.DeveloperName, Complaint_Case_ID__c FROM Case WHERE Id = :testCase1.Id LIMIT 1];

        // Add your assertions based on the expected behavior
        System.assertEquals('PublicComplaintCase', updatedCase1.RecordType.DeveloperName);
        System.assertNotEquals(null, updatedCase1.Complaint_Case_ID__c);

        // Test Scenario 2: Insert a Case with a missing AccountId (negative scenario)
        Case testCase2 = new Case(
            Subject = 'Test Subject 2'
            // AccountId is not provided intentionally
        );

        // Insert the test Case record, which should invoke the trigger
        try {
            insert testCase2;
            // If the above line doesn't throw an exception, the test should fail
            System.assert(false, 'Inserting a Case without AccountId should have thrown an exception.');
        } catch (DmlException e) {
            // Expected exception, add assertions if needed
            System.assertEquals(true, e.getMessage().contains('REQUIRED_FIELD_MISSING'));
        }

        // Test Scenario 3: Bulk processing (insert multiple Cases)
        List<Case> testCasesBulk = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            Case newCase = new Case(
                Subject = 'Test Subject ' + i,
                AccountId = testAccount.Id,
                WishtoRemainAnonymous__c = 'No',
                NeedFeedbackOnResolution__c = 'No',
                ResidentAwareofComplaint__c = 'No'
                // Add other required fields as needed
            );
            testCasesBulk.add(newCase);
        }

        // Inserting the bulk Cases, which should invoke the trigger
        insert testCasesBulk;

        // Query the database to verify the changes
        List<Case> updatedCasesBulk = [SELECT Id, RecordType.DeveloperName, Complaint_Case_ID__c FROM Case WHERE Id IN :testCasesBulk];

        // Adding assertions based on the expected behavior for bulk processing
        System.assertEquals(testCasesBulk.size(), updatedCasesBulk.size());

        // End the test context
        Test.stopTest();
    }
}