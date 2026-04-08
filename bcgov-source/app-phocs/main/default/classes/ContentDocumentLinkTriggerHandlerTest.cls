/**********************************************************************************************
* @Author:Accenture_PHOCS Dev Team   
* @Date:       
* @Description: Test class for ContentDocumentLinkTriggerHandler EHIS-1657
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                  
***********************************************************************************************/

@isTest
public class ContentDocumentLinkTriggerHandlerTest {
    @isTest
    static void testUpdateDocumentChecklistItemAfterUploadFile() {
      
        Id dciRecordTypeId = Schema.SObjectType.DocumentChecklistItem.getRecordTypeInfosByDeveloperName().get('PHOCSDocumentChecklist').getRecordTypeId();
        Id blaRecordTypeId = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('OperatingPermitApplication').getRecordTypeId();
        
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
        Account AccRec = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        Contact ContactTest = TestDataFactory.createContactRecord(AccRec.Id, 'test@gmail.com', 'Test Fname', 'Test lname', true);
        RegulatoryAuthorizationType ratTest = TestDataFactory.createRegAuthTypeACR('AuthName', true);
        
        BusinessLicenseApplication blaTest = new BusinessLicenseApplication(
          	recordTypeId = blaRecordTypeId,
          	AccountId = AccRec.Id,
          	LicenseTypeId = ratTest.Id,
          	Status = 'Submitted',
          	AppliedDate = DateTime.now(),
            PrimaryOwnerId = ContactTest.Id,
            Category = 'Permit');
       insert blaTest;
        
        DocumentChecklistItem dciTest = new DocumentChecklistItem(
            Name = 'DCL name', 
            Status = 'Not Received', 
            RecordTypeId = dciRecordTypeId, 
            parentRecordId = blaTest.Id);
        insert dciTest;
        
        ContentDocumentLink cdlTest = new ContentDocumentLink(
            LinkedEntityId = dciTest.Id, 
            ContentDocumentId = '069000000000AAA');
        
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink> { cdlTest };
        
        Test.startTest();
        ContentDocumentLinkTriggerHandler.updateDocumentChecklistItemAfterUploadFile(cdlList);
        Test.stopTest();
        
        DocumentChecklistItem dciAfter = [SELECT Status FROM DocumentChecklistItem WHERE Id = :dciTest.Id];
        System.assertEquals('Received', dciAfter.Status);
    }
}