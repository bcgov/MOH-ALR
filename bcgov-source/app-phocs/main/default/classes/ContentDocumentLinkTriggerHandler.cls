/**********************************************************************************************
* @Author:Accenture_PHOCS Dev Team   
* @Date:       
* @Description: Method to update DocumentChecklistItem after a file is uploaded EHIS-1657
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                  
***********************************************************************************************/

public with sharing class ContentDocumentLinkTriggerHandler {
    
    public static void updateDocumentChecklistItemAfterUploadFile(List<ContentDocumentLink> CDLs) {
        
        String devNamePrefixPHOCS = 'PHOCS%';
        String statusReceived = 'Received';
        String dclIdPrefix = '0dd';
        
        try {
            Set<Id> LinkedEntityIds = new Set<Id>();
            
            for (ContentDocumentLink CDL : CDLs) {
               
                String idPrefix = String.valueOf(CDL.LinkedEntityId).substring(0,3);
                
                if (idPrefix == dclIdPrefix) {
                   LinkedEntityIds.add(CDL.LinkedEntityId);
                }
            }
            
            List<DocumentChecklistItem> relatedDCItems = [SELECT Id, Status 
                                                   			FROM DocumentChecklistItem
                                                   			WHERE Id IN :LinkedEntityIds
                                                         	AND RecordType.DeveloperName LIKE :devNamePrefixPHOCS];
            
            List<DocumentChecklistItem> dciToUpdate = new List<DocumentChecklistItem>();
            
            for (DocumentChecklistItem dci : relatedDCItems) {
                if (dci.Status != statusReceived) {
                    dciToUpdate.add(dci);
                }
            }
            
            if (!dciToUpdate.isEmpty()) {
                for (DocumentChecklistItem dci : dciToUpdate) {
                    dci.Status = statusReceived;
                }
                update dciToUpdate;
            }
           
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
    
}