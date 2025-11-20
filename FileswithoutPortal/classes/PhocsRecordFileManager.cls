public with sharing class PhocsRecordFileManager {

    @AuraEnabled(cacheable=true)
    public static List<DocumentDetail> getDocumentsList(Id parentRecordId) {
        List<DocumentDetail> docs = new List<DocumentDetail>();
        if(parentRecordId == null){
            return docs;
        }

        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink link : [SELECT ContentDocumentId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId = :parentRecordId]){
            contentDocIds.add(link.ContentDocumentId);
        }

        for(ContentVersion cv :  [SELECT ContentDocumentId, Title, FileExtension, CreatedDate
                                  FROM ContentVersion
                                  WHERE ContentDocumentId IN :contentDocIds
                                         AND IsLatest = true]){
            DocumentDetail detail = new DocumentDetail();
            detail.contentDocumentId = cv.ContentDocumentId;
            detail.fileName = cv.Title;
            detail.createdDate = cv.CreatedDate;
            detail.parentRecordId = parentRecordId;
            detail.downloadUrl = getDownloadUrl(cv.ContentDocumentId);
            detail.previewUrl  = getRenditionDownloadUrl(cv.Id);
            docs.add(detail);
        }
        return docs;
    }

      public static String getDownloadUrl(Id contentVersionId) {
        // Get the current request URL
       String communityBaseUrl = URL.getCurrentRequestUrl().getHost();
       String renditionUrl = 'https://' + communityBaseUrl 
                            + '/phocsportal/sfc/servlet.shepherd/document/download/'
                            + contentVersionId;

        return renditionUrl;
    }

    public static String getRenditionDownloadUrl(Id contentVersionId) {
        // Get the current request URL
       String communityBaseUrl = URL.getCurrentRequestUrl().getHost();
       String renditionUrl = 'https://' + communityBaseUrl 
                            + '/phocsportal/sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId='
                            + contentVersionId;

        return renditionUrl;
    }

    public class DocumentDetail {      
        @AuraEnabled public String contentDocumentId;
        @AuraEnabled public String fileName;
        @AuraEnabled public Id parentRecordId;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String downloadUrl;
        @AuraEnabled public String previewUrl;
    }
}