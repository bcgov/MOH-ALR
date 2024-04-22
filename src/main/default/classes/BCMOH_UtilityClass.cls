/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for Util class for common re-usable methods
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                            ALR -560             Sweta 
***********************************************************************************************/
public class BCMOH_UtilityClass {
    public static String className = 'BCMOH_UtilityClass';
/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch renewal details FROM metadata
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, List<String>> getAccRenewals(String renewalName) {
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        RenewalProcessCriteria__mdt renewalCriteriaRec = new RenewalProcessCriteria__mdt();
        try {
            renewalCriteriaRec = RenewalProcessCriteria__mdt.getInstance(renewalName);
            accDetails.put(renewalCriteriaRec.AccountRecordType__c, renewalCriteriaRec.AccountStatuses__c.split(';'));
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getAccRenewals', '', ex);
        }
        return accDetails;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch active email template developer name based on purpose FROM metadata
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
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
            LogService.logAndPublish(className, 'getEmailtemplateName', '', ex);
        }
        return templateDetailsMap;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch active email template developer name based on purpose FROM metadata-ALR-1000
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<Id, String> getEmailtemplatebyName(String templatePurposeDetails) {
        Map<Id, String> templateDetailsMap = new Map<Id, String>();
        try {
            for(EmailTemplateDetails__mdt emailTemplateRec : EmailTemplateDetails__mdt.getAll().values()) {
                if(emailTemplateRec.IsActive__c && emailTemplateRec.Purpose__c == templatePurposeDetails) {
                    templateDetailsMap.put(emailTemplateRec.Id, emailTemplateRec.EmailTemplateDeveloperName__c);
                    break;
                }
            }
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getAccRenewals', '', ex);
        }
        return templateDetailsMap;
    }
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch email template based on developer name provided
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static EmailTemplate getEmailTemplate(String templateDevName) {
        EmailTemplate emailTemplateRec = new EmailTemplate();
        try {
            emailTemplateRec = [SELECT Id, DeveloperName, RelatedEntityType, Body, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateDevName WITH SECURITY_ENFORCED LIMIT 1];
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getEmailTemplate', '', ex);
        }
        return emailTemplateRec;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch contentVersion Ids for provided LinkedEntity Ids
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static ContentDocWrapper getContentDocMap(Set<Id> linkedIds) {
        Map<Id, Set<Id>> entityContentIdsMap1 = new Map<Id, Set<Id>>();
        Set<Id> allDocIds = new Set<Id>();
        Map<Id, Id> contentDocVerMap1 = new Map<Id, Id>();
        ContentDocWrapper ContentDocWrapperRecord = new ContentDocWrapper();
        try {
            for(ContentDocumentLink contentDoc : [SELECT Id, ContentDocument.Id, LinkedEntityId 
                                                  FROM ContentDocumentLink 
                                                  WHERE LinkedEntityId IN: linkedIds WITH SECURITY_ENFORCED]) {
                                                      //all doc Ids
                                                      allDocIds.add(contentDoc.ContentDocument.Id);
                                                      //map of linkedId with its associated doc ids
                                                      Set<Id> docIdSet = new Set<Id>();
                                                      if(entityContentIdsMap1.containsKey(contentDoc.LinkedEntityId)) {
                                                          docIdSet = entityContentIdsMap1.get(contentDoc.LinkedEntityId);
                                                      }
                                                      docIdSet.add(contentDoc.ContentDocument.Id);
                                                      entityContentIdsMap1.put(contentDoc.LinkedEntityId, docIdSet);
                                                  }
            ContentDocWrapperRecord.entityContentIdsMap = entityContentIdsMap1;
            //fetch content version vs content doc map
            for(ContentVersion contentVerRec : [SELECT Id, ContentDocument.Id, ContentSize FROM ContentVersion
                                                WHERE ContentDocument.Id IN: allDocIds WITH SECURITY_ENFORCED]) {
                                                    contentDocVerMap1.put(contentVerRec.ContentDocument.Id, contentVerRec.Id);
                                                }
            ContentDocWrapperRecord.contentDocVerMap = contentDocVerMap1;
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getContentDocMap', '', ex);
        }
        return ContentDocWrapperRecord;
    }
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch fetch org wide email based on Org
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static OrgWideEmailAddress getOrgWideEmailAddress() {
        OrgWideEmailAddress orgWideAddr = new OrgWideEmailAddress();
        String fromAddress = '';
        try {
            if(Test.isRunningTest()) {
                orgWideAddr = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
            }
            else {
                //stores email addresses in custom setting
                Notification__c notifDefault = Notification__c.getOrgDefaults();
                //fetch org type
                Boolean isSandbox = String.isEmpty(DomainParser.parse(DomainCreator.getOrgMyDomainHostname()).getSandboxName()) ? false : true;
                //based on org type, fetch respective email as fromAddress
                fromAddress = isSandbox ? notifDefault.TestSupportEmail__c : notifDefault.ProductionSupportEmail__c;
                orgWideAddr = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: fromAddress LIMIT 1];
            }
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getOrgWideEmailAddress', '', ex);
        }
        return orgWideAddr;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to set Email parameters
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Messaging.SingleEmailMessage setEmailParams(Id targetId, Id templateId, Id orgWideAddressId, List<Id> attachmentIds, Id whatId, String emailBody, String subjectValue, String emailHtmlBody) {//ALR-827 - added param htmlbody
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        emailMsg.setTargetObjectId(targetId);
        emailMsg.setEntityAttachments(attachmentIds);
        emailMsg.setOrgWideEmailAddressId(orgWideAddressId);
        emailMsg.setSubject(subjectValue);
        emailMsg.setWhatId(whatId);//?null check needed?
        emailMsg.setplainTextBody(emailBody);
        emailMsg.setHtmlBody(emailHtmlBody);//ALR-827 - added html body
        return emailMsg;   
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to fetch DocumentTemplateContentDoc map given template name
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, DocumentTemplateContentDoc> getDocTempContentMap(List<String> templateNames) {
        Map<String, DocumentTemplateContentDoc> templateNameDocMap = new Map<String, DocumentTemplateContentDoc>();
        for(DocumentTemplateContentDoc docTempRec : [SELECT DocumentTemplate.Name, ContentDocument.Title, LatestContentVersionId
                                                     FROM DocumentTemplateContentDoc
                                                     WHERE DocumentTemplate.Name IN: templateNames WITH SECURITY_ENFORCED 
                                                     LIMIT 5000]) {
                                                         templateNameDocMap.put(docTempRec.DocumentTemplate.Name, docTempRec);
                                                     }
        return templateNameDocMap;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to convert a Map to a JSON string
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String mapToJson(Map<String, Object> inputMap) {
        String jsonString = JSON.serialize(inputMap);
        return jsonString;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to get substring of document title without file extension
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String getSubstringWithoutExtension(String documentTitle) {
        //get last occurrence of '.'
        Integer lastDotIndex = documentTitle.lastIndexOf('.');
        //If found, get the substring before the last '.'
        if(lastDotIndex != -1) {
            documentTitle = documentTitle.substringBeforeLast('.');
        }
        return documentTitle;
    }
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to create document record
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static DocumentGenerationProcess getDocGenProcRec(String type, String requestText, String referenceId, String tokenData, String docGenType) {
        DocumentGenerationProcess docGenRec = new DocumentGenerationProcess(
            Type = type,
            RequestText = requestText,
            ReferenceObject = referenceId,
            TokenData = tokenData,
            DocGenApiVersionType = docGenType);
        return docGenRec;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to get map of document name and title for given purpose- ALR-775
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, String> getDocNameTitle(String docGenPurpose) {
        Map<String, String> docNameWithTitleMap = new Map<String, String>();
        try {
            if(docGenPurpose.equals(BCMOH_Constants.templatePurpose)) {
                docNameWithTitleMap.put('RenewalApplicationForm', 'Renewal Application Form');
                docNameWithTitleMap.put('RenewalInvoiceTemplate', 'Renewal Invoice '+BCMOH_Constants.invoiceIdMerge);
            }
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getDocNameTitle', '', ex);
        }
        return docNameWithTitleMap;
    }

/**
* @Author:
* @date: 
* @description: The purpose of this method is to ALR-997
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, String> getDocNameTitleLateFee(String docGenPurpose) {
        Map<String, String> docNameWithTitleMap = new Map<String, String>();
        try {
            if(docGenPurpose.equals(BCMOH_Constants.templatePurposeDetails)){
                docNameWithTitleMap.put('LateFee_Template', 'Late Fee Invoice '+BCMOH_Constants.invoiceIdMerge);//ALR-1000
            }
        }
        catch(Exception ex) {
            LogService.logAndPublish(className, 'getDocNameTitleLateFee', '', ex);
        }
        return docNameWithTitleMap;
    }
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to update all bla records - DML
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //ALR-560 - common util class
    public static List<BusinessLicenseApplication> updateBlaStatus(Map<Id, String> blaIdDetailsMap, String blaStatus) {
        List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>();
        try {           
            //loop through bla update map
            for(Id blaId : blaIdDetailsMap.keySet()) {
                //truncate the message if length more than 255 chars
                String renewalMsg = blaIdDetailsMap.get(blaId);
                renewalMsg = renewalMsg.length() > 255 ? renewalMsg.Substring(0,255) : renewalMsg;
                BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
                    Id = blaId,
                    Status = blaStatus,
                    RenewalDetail__c = renewalMsg);
                blaUpdateList.add(blaRec);
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'updateBlaStatus', '', ex);
        }
        return blaUpdateList;
    }
    
/**
* @Author:
* @date: 
* @description: The purpose of this method is to update all bla late fee status
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static List<BusinessLicenseApplication> updateBlaLateFeeStatus(Map<Id, String> blaIdDetailsMap, String blalatefeeStatus) {
        List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>();
        try {     
            BusinessLicenseApplication BLAquery = [SELECT Id, RenewalDetail__c FROM BusinessLicenseApplication WHERE Id =:blaIdDetailsMap.keySet() WITH SECURITY_ENFORCED LIMIT 1];
            
            //loop through bla update map
            for(Id blaId : blaIdDetailsMap.keySet()) {
                //truncate the message if length more than 255 chars
                String renewalMsg = blaIdDetailsMap.get(blaId);
                renewalMsg = BLAquery.RenewalDetail__c != NULL ? BLAquery.RenewalDetail__c + ' ; ' + renewalMsg : renewalMsg;
                BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
                    Id = blaId,
                    Late_Fee_Status__c = blalatefeeStatus,
                    RenewalDetail__c = renewalMsg);
                blaUpdateList.add(blaRec);
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'updateBlaLateFeeStatus', '', ex);
        }
        return blaUpdateList;
    } 

/**
* @Author:
* @date: 
* @description: The purpose of this method is to 
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    //wrapper class to pass content doc details
    public class ContentDocWrapper {
        public Map<Id, Set<Id>> entityContentIdsMap;// {get;set;}
        public Map<Id, Id> contentDocVerMap;// {get;set;}
    }  
}