public with sharing class PhocsRecordFileManager {

    @AuraEnabled(cacheable=true)
    public static List<DocumentDetail> getDocumentsList(Id parentRecordId) {
        List<DocumentDetail> docs = new List<DocumentDetail>();
        if(parentRecordId == null){
            return docs;
        }

        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink link : [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :parentRecordId
        ]){
            contentDocIds.add(link.ContentDocumentId);
        }

        for(ContentVersion cv : [
            SELECT ContentDocumentId, Title, FileExtension, CreatedDate
            FROM ContentVersion
            WHERE ContentDocumentId IN :contentDocIds
            AND IsLatest = true
        ]){
            DocumentDetail detail = new DocumentDetail();
            detail.contentDocumentId = cv.ContentDocumentId;
            detail.fileName = cv.Title;
            detail.createdDate = cv.CreatedDate;
            detail.parentRecordId = parentRecordId;
            detail.downloadUrl = '/sfc/servlet.shepherd/document/download/' + cv.ContentDocumentId;
            detail.previewUrl  = '/lightning/r/ContentDocument/' + cv.ContentDocumentId + '/view';
            docs.add(detail);
        }
        return docs;
    }

    public class DocumentDetail {      
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public Id parentRecordId;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String previewUrl;  // 👈 Added for preview
    }
}