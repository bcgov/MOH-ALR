/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR - 509           Sri Teja
***********************************************************************************************/
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
        Account residence =[SELECT Id FROM account WHERE Name = 'residence1' LIMIT 1];
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
		 Account residence =[SELECT Id FROM account limit 1];        
		 Case complaintCase = [SELECT id,Accountid,subject,Description,WishtoRemainAnonymous__c,NeedFeedbackOnResolution__c,ResidentAwareofComplaint__c FROM Case WHERE Subject = 'Test Case' limit 1];
		 Case complaintCase1 = [SELECT id,Accountid,subject,Description,WishtoRemainAnonymous__c,NeedFeedbackOnResolution__c,ResidentAwareofComplaint__c FROM Case WHERE Subject = 'Test Case1' limit 1];
		Case complaintCase2 = [SELECT id,Accountid,subject,Description,WishtoRemainAnonymous__c,NeedFeedbackOnResolution__c,ResidentAwareofComplaint__c FROM Case WHERE Subject = 'Test Case2' limit 1];
		caseList.add(complaintCase);
        caseList.add(complaintCase1);
        caseList.add(complaintCase2);
        // Test trigger execution
        Test.startTest();
         ComplaintCaseTriggerHandler.handleBeforeInsert(caseList);
        Test.stopTest();    
		Assert.areEqual('Test Case', caseList[0].subject, 'Assertion for Test Case');
        Assert.areEqual('Test Case1', caseList[1].subject, 'Assertion for Test Case1');
        Assert.areEqual('Test Case2', caseList[2].subject, 'Assertion for Test Case2');

    }*/