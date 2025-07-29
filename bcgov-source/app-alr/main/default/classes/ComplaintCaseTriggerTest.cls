/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR - 509           Sri Teja       Public complaints/Cases additional changes
                           ALR-762             ACN-ALR        Error Thrown on creation of Reportable Incident Case 
***********************************************************************************************/
@isTest
public class ComplaintCaseTriggerTest {

    @testSetup
    public static void makeData() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
        System.assertNotEquals(null, regAuth.Id, 'RegulatoryAuthorizationType record creation failed');
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
        System.assertNotEquals(null, residence.Id, 'Residence account creation failed');
    }

    @isTest
    static void testComplaintCaseTrigger() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        Account residence = [SELECT Id FROM Account WHERE Name = 'residence1' LIMIT 1];
        System.assertNotEquals(null, residence.Id, 'Residence account not found');
        
        Case complaintCase = TestDataFactory.createComplaintCase(residence.Id, 'Test Case', 'Testing the trigger', false, false, false, false);
        System.assertNotEquals(null, complaintCase.RecordTypeId, 'Complaint case record type is not set');
        
        caseList.add(complaintCase);
        insert complaintCase;
        Test.stopTest();
        
        Case caseRec = [SELECT Id, Complaint_Case_ID__c FROM Case WHERE Id = :caseList[0].Id LIMIT 1];
        System.assertNotEquals(null, caseRec.Id, 'Inserted case record not found');
        
        Assert.isNotNull(caseRec.Complaint_Case_ID__c, 'Complaint_Case_ID__c should not be null');
    }
}