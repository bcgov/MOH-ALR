/**
* @Name              : BCMOH_UtilityClass
* @Description       : Util class for common re-usable methods
                       referenced in ....
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
public class BCMOH_UtilityClass {
    //method to fetch renewal details from metadata
    public static Map<String, List<String>> getAccRenewals(String renewalName) {
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        RenewalProcessCriteria__mdt renewalCriteriaRec = new RenewalProcessCriteria__mdt();
        try {
            renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
        	accDetails.put(renewalCriteriaRec.AccountRecordType__c, renewalCriteriaRec.AccountStatuses__c.split(';'));
        }
        catch(Exception ex) {
            system.debug('use exception handling'+ex.getMessage());
        }
        return accDetails;
    }
    
    //method to fetch active email template developer name based on purpose from metadata
      public static Map<Id, String> getEmailtemplateName(String templatePurpose) {
        Map<Id, String> templateDetailsMap = new Map<Id, String>();
        try {
            for(EmailTemplateDetails__mdt emailTemplateRec : EmailTemplateDetails__mdt.getAll().values()) {
                if(emailTemplateRec.IsActive__c && emailTemplateRec.Purpose__c == templatePurpose) {
                    templateDetailsMap.put(emailTemplateRec.Id, emailTemplateRec.EmailTemplateDeveloperName__c);
                    break;
                }
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling'+ex.getMessage());
        }
        return templateDetailsMap;
    }
    
    //method to fetch email template based on developer name provided
    public static EmailTemplate getEmailTemplate(String templateDevName) {
        EmailTemplate emailTemplateRec = new EmailTemplate();
        try {
            emailTemplateRec = [SELECT Id, DeveloperName, RelatedEntityType, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateDevName LIMIT 1];
        }
        catch(Exception ex) {
            system.debug('use exception handling'+ex.getMessage());
        }
        return emailTemplateRec;
    }

    //method to fetch contentVersion Ids for provided LinkedEntity Ids
    public static ContentDocWrapper getContentDocMap(Set<Id> linkedIds) {
        Map<Id, Set<Id>> entityContentIdsMap1 = new Map<Id, Set<Id>>();
        Set<Id> docIdSet = new Set<Id>();
        Set<Id> allDocIds = new Set<Id>();
        Map<Id, Id> contentDocVerMap1 = new Map<Id, Id>();
        ContentDocWrapper ContentDocWrapperRecord = new ContentDocWrapper();
        try {
            for(ContentDocumentLink contentDoc : [SELECT Id, ContentDocument.Id, LinkedEntityId 
                                                  FROM ContentDocumentLink 
                                                  WHERE LinkedEntityId IN: linkedIds]) {
                                                      //all doc Ids
                                                      allDocIds.add(contentDoc.ContentDocument.Id);
                                                      system.debug('yui getContentDocMap meth allDocIds '+allDocIds);
                                                      //map of linkedId with its associated doc ids
                                                      if(entityContentIdsMap1.containsKey(contentDoc.LinkedEntityId)) {
                                                          system.debug('yui inside if contans wrapper rec '+entityContentIdsMap1);
                                                          docIdSet = entityContentIdsMap1.get(contentDoc.LinkedEntityId);
                                                      }
                                                      docIdSet.add(contentDoc.ContentDocument.Id);
                                                      entityContentIdsMap1.put(contentDoc.LinkedEntityId, docIdSet);
            }
            ContentDocWrapperRecord.entityContentIdsMap = entityContentIdsMap1;
            //fetch content version vs content doc map
            for(ContentVersion contentVerRec : [SELECT Id, ContentDocument.Id, ContentSize FROM ContentVersion
                                                WHERE ContentDocument.Id IN: allDocIds]) {
                                                    system.debug('yui inside for content version wrap '+contentDocVerMap1);
                                                    contentDocVerMap1.put(contentVerRec.ContentDocument.Id, contentVerRec.Id);
                                                }
            ContentDocWrapperRecord.contentDocVerMap = contentDocVerMap1;
        }
        catch(Exception ex) {
            system.debug('use exception handling getContentDocMap '+ex.getMessage());
        }
        return ContentDocWrapperRecord;
    }
    
    //method to fetch fetch org wide email based on Org
    public static OrgWideEmailAddress getOrgWideEmailAddress() {
        OrgWideEmailAddress orgWideAddr = new OrgWideEmailAddress();
        String fromAddress = '';
        try {
            if(Test.isRunningTest()) {
            	orgWideAddr = [SELECT Id from OrgWideEmailAddress LIMIT 1];
                system.debug('fsd'+orgWideAddr);
            }
            else {
                //stores email addresses in custom setting
                Notification__c notifDefault = Notification__c.getOrgDefaults();
                system.debug('csd Notification__c '+notifDefault);
                //fetch org type
                Boolean isSandbox = String.isEmpty(DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName()) ? false : true;
                //based on org type, fetch respective email as fromAddress
                fromAddress = isSandbox ? notifDefault.TestSupportEmail__c : notifDefault.ProductionSupportEmail__c;
                orgWideAddr = [SELECT Id from OrgWideEmailAddress WHERE Address =: fromAddress LIMIT 1];
                system.debug('csd orgWideAddr '+orgWideAddr);
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling getOrgWideEmailAddress '+ex.getMessage());
        }
        return orgWideAddr;
    }
    
    //method to set Email parameters
    public static Messaging.SingleEmailMessage setEmailParams(Id targetId, Id templateId, Id orgWideAddressId, List<Id> attachmentIds, Id whatId, String emailBody, String subjectValue) {
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        emailMsg.setTargetObjectId(targetId);
        //emailMsg.setTemplateId(templateId);
        emailMsg.setEntityAttachments(attachmentIds);
        emailMsg.setOrgWideEmailAddressId(orgWideAddressId);
        emailMsg.setSubject(subjectValue);
        emailMsg.setWhatId(whatId);//?null check needed?
        emailMsg.setplainTextBody(emailBody);
        //emailMsg.HtmlBody(emailBody);
        return emailMsg;
    }
    
    //method to fetch DocumentTemplateContentDoc map given template name
    public static Map<String, DocumentTemplateContentDoc> getDocTempContentMap(List<String> templateNames) {
       Map<String, DocumentTemplateContentDoc> templateNameDocMap = new Map<String, DocumentTemplateContentDoc>();
        for(DocumentTemplateContentDoc docTempRec : [SELECT DocumentTemplate.Name, ContentDocument.Title, LatestContentVersionId
                                                     FROM DocumentTemplateContentDoc
                                                     WHERE DocumentTemplate.Name IN: templateNames 
                                                     LIMIT 5000]) {
                                                       templateNameDocMap.put(docTempRec.DocumentTemplate.Name, docTempRec);
                                                     }
        return templateNameDocMap;
    }
    
    //Method to convert a Map to a JSON string
    public static String mapToJson(Map<String, Object> inputMap) {
        String jsonString = JSON.serialize(inputMap);
        return jsonString;
    }
    
    //Method to get substring of document title without file extension
    public static String getSubstringWithoutExtension(String documentTitle) {
        //get last occurrence of '.'
        Integer lastDotIndex = documentTitle.lastIndexOf('.');
        //If found, get the substring before the last '.'
        if(lastDotIndex != -1) {
            documentTitle = documentTitle.substringBeforeLast('.');
        }
        return documentTitle;
    }
    
    //create document record
    public static DocumentGenerationProcess getSubstringWithoutExtension(String type, String requestText, String referenceId, String tokenData, String docGenType) {
        DocumentGenerationProcess docGenRec = new DocumentGenerationProcess(
            Type = type,
            RequestText = requestText,
            ReferenceObject = referenceId,
            TokenData = tokenData,
            DocGenApiVersionType = docGenType);
        return docGenRec;
    }
        
    //wrapper class to pass content doc details
    public class ContentDocWrapper {
        public Map<Id, Set<Id>> entityContentIdsMap;// {get;set;}
        public Map<Id, Id> contentDocVerMap;// {get;set;}
    }  
    
}