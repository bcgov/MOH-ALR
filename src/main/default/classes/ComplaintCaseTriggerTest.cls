/**
* @Name              : ComplaintTriggerHandlerTest
* @Description       : Test class for ComplaintCaseTriggerHandler and ComplaintCaseTrigger
* @Author            : Sri Teja (Accenture)
* @StoryNo           : ALR-509
**/


@isTest
public class ComplaintCaseTriggerTest {
 
    @isTest
    static void testComplaintCaseTrigger() {
        RegulatoryAuthorizationType testRegulatoryAuthorizationType = new RegulatoryAuthorizationType(
        Name = 'Test Regulatory Authorization Type',
        RegulatoryAuthorizationCode__c = 'MH'
        );
        insert testRegulatoryAuthorizationType;
        // Test data setup
        Account testAccount = new Account(
        RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Residence' AND SObjectType = 'Account' LIMIT 1].Id,
        Name = 'Test Account',
        LicenseType__c = testRegulatoryAuthorizationType.Id
        );
        insert testAccount;
        System.debug('Test Account:'+testAccount);
 
        // Test for insertion of a single case
        Case testCase = new Case(
            AccountId = testAccount.Id,
            Subject = 'Test Case',
            Description = 'Testing the trigger',
            WishtoRemainAnonymous__c = 'No',
            NeedFeedbackOnResolution__c = 'No',
            ResidentAwareofComplaint__c = 'No'
        );
 
        // Verify the expected results
        //testCase = [SELECT Id, RecordTypeId, Complaint_Case_ID__c FROM Case WHERE Id = :testCase.Id LIMIT 1];
 
        //System.assertEquals('ExpectedRecordTypeId', testCase.RecordTypeId, 'Record Type not set correctly');
        //System.assertNotEquals(null, testCase.Complaint_Case_ID__c, 'Complaint Case ID not generated');
 
        // Test for insertion of multiple cases with the same account
        Case testCase2 = new Case(
            AccountId = testAccount.Id,
            Subject = 'Test Case 2',
            Description = 'Testing the trigger again',
            WishtoRemainAnonymous__c = 'No',
            NeedFeedbackOnResolution__c = 'No',
            ResidentAwareofComplaint__c = 'No'
            // Add any other required fields
        );
 
        Case testCase3 = new Case(
            AccountId = testAccount.Id,
            Subject = 'Test Case 3',
            Description = 'Testing once more',
            WishtoRemainAnonymous__c = 'No',
            NeedFeedbackOnResolution__c = 'No',
            ResidentAwareofComplaint__c = 'No'
            // Add any other required fields
        );
 
        // Test trigger execution
        Test.startTest();
        insert new List<Case>{ testCase, testCase2, testCase3 };
        Test.stopTest();
 
        // Verify the expected results for the second case
        testCase2 = [SELECT Id, RecordTypeId, AccountId, Complaint_Case_ID__c FROM Case WHERE Id = :testCase2.Id LIMIT 1];
 
        //System.assertEquals('ExpectedRecordTypeId', testCase2.RecordTypeId, 'Record Type not set correctly');
        //System.assertNotEquals(null, testCase2.Complaint_Case_ID__c, 'Complaint Case ID not generated');
 
        // Verify the expected results for the third case
        testCase3 = [SELECT Id, RecordTypeId, AccountId, Complaint_Case_ID__c FROM Case WHERE Id = :testCase3.Id LIMIT 1];
 
        //System.assertEquals('ExpectedRecordTypeId', testCase3.RecordTypeId, 'Record Type not set correctly');
        //System.assertNotEquals(null, testCase3.Complaint_Case_ID__c, 'Complaint Case ID not generated');
        
        List<Case> caseList = new List<Case>();
        caseList.add(testCase);
		caseList.add(testCase2);
		caseList.add(testCase3);     
        ComplaintCaseTriggerHandler.handleBeforeInsert(caseList);
    }
 
}