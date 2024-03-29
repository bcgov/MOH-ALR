/**
* @Name              : ComplaintCaseTriggerTest
* @Description       : Test class for ComplaintCaseTriggerHandler and ComplaintCaseTrigger
* @Author            : Sri Teja (Accenture)
* @StoryNo           : ALR-509
**/

@isTest
public class ComplaintCaseTriggerTest {
    
	@testSetup
    public static void makeData() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
		
    }
    //ALR-762
    @isTest
    static void testComplaintCaseTrigger() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        Account residence =[Select Id from account WHERE Name = 'residence1' limit 1];
        Case complaintCase = TestDataFactory.createComplaintCase(residence.Id,'Test Case','Testing the trigger',false,false,false,false);
        caseList.add(complaintCase);
        insert complaintCase;
        Test.stopTest();
        Case caseRec = [SELECT Id, Complaint_Case_ID__c FROM Case LIMIT 1];
        Assert.isNotNull(caseRec.Complaint_Case_ID__c);
    }
}

/*Case testCase = TestDataFactory.createComplaintCase(residence.Id,'Test Case','Testing the trigger',false,false,false,true);
		Case testCase1 = TestDataFactory.createComplaintCase(residence.Id,'Test Case1','Testing the trigger',false,false,false,true);
		Case testCase2 = TestDataFactory.createComplaintCase(residence.Id,'Test Case2','Testing the trigger',false,false,false,true);*/


	/*@isTest
    static void testComplaintCaseTrigger() {
         List<Case> caseList = new List<Case>();
		 Account residence =[Select Id from account limit 1];        
		 Case complaintCase = [select id,Accountid,subject,Description,WishtoRemainAnonymous__c,NeedFeedbackOnResolution__c,ResidentAwareofComplaint__c FROM Case where Subject = 'Test Case' limit 1];
		 Case complaintCase1 = [select id,Accountid,subject,Description,WishtoRemainAnonymous__c,NeedFeedbackOnResolution__c,ResidentAwareofComplaint__c FROM Case where Subject = 'Test Case1' limit 1];
		Case complaintCase2 = [select id,Accountid,subject,Description,WishtoRemainAnonymous__c,NeedFeedbackOnResolution__c,ResidentAwareofComplaint__c FROM Case where Subject = 'Test Case2' limit 1];
		caseList.add(complaintCase);
        caseList.add(complaintCase1);
        caseList.add(complaintCase2);
        // Test trigger execution
        Test.startTest();
         ComplaintCaseTriggerHandler.handleBeforeInsert(caseList);
        Test.stopTest();    
		System.assertEquals('Test Case', caseList[0].subject, 'Assertion for Test Case');
        System.assertEquals('Test Case1', caseList[1].subject, 'Assertion for Test Case1');
        System.assertEquals('Test Case2', caseList[2].subject, 'Assertion for Test Case2');

    }*/