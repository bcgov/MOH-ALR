/**********************************************************************************************
* @Author:      Accenture 
* @Date:        30 Oct 2025
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                30 Oct -  PHOCS-402/405     -  Accenture   -  Creating afterInsert method to call sub-methods.
                30 Oct -  PHOCS-402/405     -  Accenture   -  Update Owner to Queue for PHOCS Web PC records.
***********************************************************************************************/
public without sharing class PublicComplaintTriggerHandler {
    public static Id recordTypePublicComplaint = Schema.SObjectType.PublicComplaint.getRecordTypeInfosByDeveloperName().get('PHOCSPublicComplaint').getRecordTypeId();
    public static Id recordTypePublicRequestInquiry = Schema.SObjectType.PublicComplaint.getRecordTypeInfosByDeveloperName().get('PHOCSPublicRequestInquiry').getRecordTypeId();
    public static String CLASS_NAME = 'PublicComplaintTriggerHandler';
    public static final String ORIGIN_WEB = 'Web';
    public static final String GROUP_TYPE = 'Queue';
    public static final String PHOCS_BA_QUEUE = 'PHOCSBusinessAdminIntakeQueue';

/**
* @author: Deepak
* @date: 30 Oct 2025
* @description: The purpose of this method is to all after insert submethods.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    public static void afterInsert(List<PublicComplaint> newList) {
        updatePHOCSPCOwner(newList);
    }
/**
* @author: Deepak
* @date: 30 Oct 2025
* @description: The purpose of this method is to Update Owner to Queue for PHOCS Web Public Complaint records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    public static void updatePHOCSPCOwner(List<PublicComplaint> newList) {
        try {
            List<PublicComplaint> pCListToUpdate = new List<PublicComplaint>();
            List<PublicComplaint> updatePCList = new List<PublicComplaint>();
            for(PublicComplaint pCObj : newList){
                if((pCObj.RecordTypeId == recordTypePublicComplaint || pCObj.RecordTypeId == recordTypePublicRequestInquiry) && pCObj.ComplaintOrigin__c == ORIGIN_WEB){
                    pCListToUpdate.add(pCObj);
                }
            }
            
            if(pCListToUpdate.isEmpty()){
                return;
            } 
            
            List<Group> bAQueueList = [SELECT Id FROM Group WHERE DeveloperName =: PHOCS_BA_QUEUE AND Type =: GROUP_TYPE LIMIT 1];
            
            if(!bAQueueList.isEmpty()){           
                for(PublicComplaint pCRec : pCListToUpdate){
                    updatePCList.add(new PublicComplaint(Id = pCRec.Id, OwnerId = bAQueueList[0].Id));
                }
                
                if(!updatePCList.isEmpty()){
                    Database.Update(updatePCList, true);
                }
            }
        }catch(Exception ex){
            LogService.logAndPublish(CLASS_NAME, 'updatePHOCSPCOwner', '', ex);
        }
    }
}