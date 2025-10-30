/**********************************************************************************************
* @Author:      Accenture 
* @Date:        30 Oct 2025
* @Description: The purpose of this class is to cover Code coverage of PublicComplaintTriggerHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                30 Oct -  PHOCS-402/405     -  Accenture   -  Update Owner to Queue for PHOCS Web PC records.
***********************************************************************************************/
@isTest
public class PublicComplaintTriggerHandlerTest {

    //Test Data Setup
    private static void createTestData() {
        Id rtPublicComplaint = Schema.SObjectType.PublicComplaint.getRecordTypeInfosByDeveloperName().get('PHOCSPublicComplaint').getRecordTypeId();
        Id rtPublicRequestInquiry = Schema.SObjectType.PublicComplaint.getRecordTypeInfosByDeveloperName().get('PHOCSPublicRequestInquiry').getRecordTypeId();
        
        List<PublicComplaint> pcList = new List<PublicComplaint>();
        pcList.add(new PublicComplaint(RecordTypeId = rtPublicComplaint, ComplaintOrigin__c = 'Web', Subject = 'Test Complaint-1', IncidentDate = Date.today().addDays(-1)));
        pcList.add(new PublicComplaint(RecordTypeId = rtPublicRequestInquiry, ComplaintOrigin__c = 'Phone', Subject = 'Test Complaint-2', IncidentDate = Date.today().addDays(-1)));        
        insert pcList;
    }

    
/**
* @author: Deepak
* @date: 30 Oct 2025
* @description: The purpose of this method is to cover Testcoverage of updatePHOCSPCOwner.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void updatePHOCSPCOwnerTest(){
        createTestData();
        List<PublicComplaint> pcList = [SELECT Id, RecordTypeId, ComplaintOrigin__c, OwnerId FROM PublicComplaint 
                                        WHERE Subject LIKE '%Test Complaint%' LIMIT 2];
        
        Test.startTest();
        PublicComplaintTriggerHandler.updatePHOCSPCOwner(pcList);
        Test.stopTest();
        
        Id queueId = [SELECT Id FROM Group WHERE DeveloperName = 'PHOCSBusinessAdminIntakeQueue' AND Type = 'Queue' LIMIT 1].Id;
        
        for(PublicComplaint pc : pcList){
            if(pc.ComplaintOrigin__c == 'Web') {
                Assert.areEqual(queueId, pc.OwnerId, 'Record with Origin Web should be assigned to the queue');                
            }else{
                Assert.areNotEqual(queueId, pc.OwnerId, 'Record with Origin other than Web should not be updated');                
            }
        }
    }
}