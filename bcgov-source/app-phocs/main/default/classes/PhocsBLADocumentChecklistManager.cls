public with sharing class PhocsBLADocumentChecklistManager {
    @AuraEnabled(cacheable=true)
    public static DocCheckListItem[] getChecklistItems(Id businessLicenseApplicationId) {
        Map<Id, DocCheckListItem> checklistItemMap = new Map<Id, DocCheckListItem>();
        if(businessLicenseApplicationId == null){
            return checklistItemMap.values();
        }

        BusinessLicenseApplication app = [Select Id, Status From BusinessLicenseApplication Where Id = :businessLicenseApplicationId LIMIT 1];

        Map<Id, DocumentCheckListItem> docCheckListItemsMap = new Map<Id, DocumentCheckListItem>([SELECT Id,Name,Status,IsRequired,CreatedDate 
                                                      FROM DocumentChecklistItem 
                                                      WHERE ParentRecordId = :businessLicenseApplicationId]);
        if(docCheckListItemsMap != null && docCheckListItemsMap.size() > 0){

            for(DocumentCheckListItem docCheckListItem : docCheckListItemsMap.values()){
                DocCheckListItem docCheckListItemWrapper = new DocCheckListItem();
                docCheckListItemWrapper.docCheckListItemId = docCheckListItem.Id;
                docCheckListItemWrapper.name = docCheckListItem.Name;
                docCheckListItemWrapper.status = docCheckListItem.Status;
                docCheckListItemWrapper.isRequired = docCheckListItem.IsRequired? 'Yes' : 'No';
                docCheckListItemWrapper.createdDate = docCheckListItem.CreatedDate;
                docCheckListItemWrapper.allowDocumentsUpload = app?.Status != 'Closed';
                checklistItemMap.put(docCheckListItem.Id, docCheckListItemWrapper);
            }

            List<ID> contentDocIds = new List<ID>();
            set<Id> docCheckListItemIds= new set<Id>(docCheckListItemsMap.keySet());
            Map<Id,Id> contentDocIdDocCheckListItemIdMap = new Map<Id,Id>();

            List<ContentDocumentLink> contentDocumentLinks = [SELECT LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :docCheckListItemIds];                                             
            for (ContentDocumentLink docLink : contentDocumentLinks) {
                contentDocIds.add(docLink.ContentDocumentId);
                contentDocIdDocCheckListItemIdMap.put(docLink.ContentDocumentId, docLink.LinkedEntityId);
            }

            if(!contentDocIds.isEmpty()){
                for (ContentVersion docLink : [SELECT ContentDocumentId, FileExtension, Title 
                                               FROM ContentVersion 
                                               WHERE ContentDocumentId IN :contentDocIds]){
                    Id docCheckListItemId = contentDocIdDocCheckListItemIdMap.get(docLink.ContentDocumentId);
                    checklistItemMap.get(docCheckListItemId).fileName = docLink.Title;
                    checklistItemMap.get(docCheckListItemId).contentDocumentId = docLink.ContentDocumentId;
                    checklistItemMap.get(docCheckListItemId).downloadUrl = '/sfc/servlet.shepherd/document/download/' + docLink.ContentDocumentId;
                    checklistItemMap.get(docCheckListItemId).hasFileUploaded= true; 
                }
            }
        }
        return checklistItemMap.values();
    }

    @AuraEnabled
    public static DocCheckListItem uploadFileToChecklist(Id documentCheckListItemId, String fileName, String base64Data, String contentType, boolean replaceFile) {
         Blob fileBody = EncodingUtil.base64Decode(base64Data);

        // check for existing link
        Id existingDocId;
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :documentCheckListItemId
            LIMIT 1
        ];
        if (!existingLinks.isEmpty()) {
            existingDocId = existingLinks[0].ContentDocumentId;
        }

        ContentVersion newVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = fileBody,
            Origin = 'H'
        );

        if (replaceFile && existingDocId != null) {
            newVersion.ContentDocumentId = existingDocId;   // new version on the same ContentDocument, no link created
        } else {       
            newVersion.FirstPublishLocationId = documentCheckListItemId;  // brand-new file, link created once automatically
        }
        insert newVersion;
        
        Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :newVersion.Id].ContentDocumentId; 
        
        DocCheckListItem docCheckListItem = new DocCheckListItem();
        docCheckListItem.docCheckListItemId = documentCheckListItemId;
        docCheckListItem.fileName = fileName;
        docCheckListItem.contentDocumentId = contentDocId;
        docCheckListItem.downloadUrl = '/sfc/servlet.shepherd/document/download/' + contentDocId;
        docCheckListItem.hasFileUploaded= true; 
        docCheckListItem.Status= 'Received';

        return docCheckListItem;
    }


    public Class DocCheckListItem{
        @AuraEnabled public Id docCheckListItemId;
        @AuraEnabled public string name;
        @AuraEnabled public string isRequired;
        @AuraEnabled public string status;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public string fileName;
        @AuraEnabled public string contentDocumentId;
        @AuraEnabled public string downloadUrl;
        @AuraEnabled public boolean hasFileUploaded;
        @AuraEnabled public boolean allowDocumentsUpload;
    }
}