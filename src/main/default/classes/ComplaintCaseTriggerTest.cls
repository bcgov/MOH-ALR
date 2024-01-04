/**
* @Name              : ComplaintTriggerHandlerTest
* @Description       : Test class for ComplaintCaseTriggerHandler and ComplaintCaseTrigger
* @Author            : Sri Teja (Accenture)
* @StoryNo           : ALR-509
**/


@isTest
public class ComplaintCaseTriggerTest {
@testSetup
 
    public static void makeData(){
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
		Case testCase = TestDataFactory.createComplaintCase(residence.Id,'Test Case','Testing the trigger',false,false,false,true);
		Case testCase1 = TestDataFactory.createComplaintCase(residence.Id,'Test Case1','Testing the trigger',false,false,false,true);
		Case testCase2 = TestDataFactory.createComplaintCase(residence.Id,'Test Case2','Testing the trigger',false,false,false,true);
    }
	@isTest
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
    }
}