/**********************************************************************************************
* @Author:      Accenture 
* @Date:        30 Oct 2025
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                30 Oct -  PHOCS-402/405     -  Accenture   -  Update Owner to Queue for PHOCS Web PC records.
***********************************************************************************************/
public without sharing class PublicComplaintTriggerHandler {
    public static Id recordTypePublicComplaint = Schema.SObjectType.PublicComplaint.getRecordTypeInfosByDeveloperName().get('PHOCSPublicComplaint').getRecordTypeId();
    public static Id recordTypePublicRequestInquiry = Schema.SObjectType.PublicComplaint.getRecordTypeInfosByDeveloperName().get('PHOCSPublicRequestInquiry').getRecordTypeId();
/**
* @author: Deepak
* @date: 30 Oct 2025
* @description: The purpose of this method is to Update Owner to Queue for PHOCS Web Public Complaint records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    public static void updatePHOCSPCOwner(List<PublicComplaint> newList) {
        List<PublicComplaint> pCListToUpdate = new List<PublicComplaint>();
        List<PublicComplaint> updatePCList = new List<PublicComplaint>();
        for (PublicComplaint pCObj : newList) {
            if((pCObj.RecordTypeId == recordTypePublicComplaint || pCObj.RecordTypeId == recordTypePublicRequestInquiry) && pCObj.ComplaintOrigin__c == 'Web'){
                pCListToUpdate.add(pCObj);
            }
        }
        
        if(pCListToUpdate.isEmpty()){
            return;
        } 
        
        List<Group> bAQueueList = [SELECT Id FROM Group WHERE DeveloperName = 'PHOCSBusinessAdminIntakeQueue' AND Type = 'Queue' LIMIT 1];
        
        if(!bAQueueList.isEmpty()) {           
            for(PublicComplaint pCRec : pCListToUpdate){
                updatePCList.add(new PublicComplaint(Id = pCRec.Id, OwnerId = bAQueueList[0].Id));
            }
            
            if(!updatePCList.isEmpty()){
                Database.Update(updatePCList, true);
            }
        }
    }
}