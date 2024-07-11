/**
* @Name              : ScheduledEmailTrigger
* @Description       : Class for Sending Email on  March-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-192
**/

public with sharing class ScheduledEmailTrigger implements Schedulable {
    public Static Id emailTemplateId =NULL;
    public static Set<Id> accountIds = new Set<Id>();
    Id blaRecord = NULL;
    List<AccountContactRelation> contacts =new List<AccountContactRelation>();
    Public Static Map<Id, List<Id>> blaContactMap = new Map<Id, List<Id>>();
    Public Static List<Id> contactIdList = new List<Id>();
    Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
    Public Static Map<Id, Set<Id>> blaContentVerMap = new Map<Id, Set<Id>>();
    Public Static Map<Id, List<Id>> whatIdTargetMap = new Map<Id, List<Id>>();
    Public Static Map<Id, String> blaErrMap = new Map<Id, String>();
    Public Static Map<Id, String> templateDetailsMap = new Map<Id, String>();
    Public Static String templateDetailName = '';
    Public Static String templateEntity = '';
    Public Static Id templateId = NULL;
    
    
    Public Static Map<Id, Account> accMap = new Map<Id, Account>();
    Public Static Map<Id, BusinessLicense> blMap = new Map<Id, BusinessLicense>();
    Public Static Map<Id, Integer> blaTotalAlUnitsMap = new Map<Id, Integer>();
    Public Static Map<Id, AccountContactRelation> accContactMap = new Map<Id, AccountContactRelation>();
    
    
    Public Static Id templateDetailsId = NULL;
    Public Static String emailBody = '';
    Public Static String subjectValue = '';
    Public Static String emailBodyConst = '';
    Public Static String subjectValueConst = '';
    
    Public Static String emailHtmlBodyConst = '';
    Public Static String emailHtmlBody = '';
    Public Static Id orgWideAddrId = NULL;
    Public Static String errMessage = '';
    Public Static Boolean sendEmailValid = true;
    Public Static Map<Id, String> blaSuccessMap = new Map<Id, String>();
    Public Static List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>();
    
    //get org wide email address based on custom setting
    public static Id getOrgWideId() {
        OrgWideEmailAddress orgWideAddr = new OrgWideEmailAddress();
        try {
            if(sendEmailValid) {
                orgWideAddr = BCMOH_UtilityClass.getOrgWideEmailAddress();
                if(orgWideAddr != NULL) {
                    orgWideAddrId = orgWideAddr.Id;
                }
                else {
                    errMessage = BCMOH_Constants.noOrgWideAddr;
                    sendEmailValid = false;
                }
            }
        }
        catch(Exception err) {
            system.debug('use exception handling sendEmailForRenewals'+err.getMessage());
        }
        return orgWideAddrId;
    }
    
    
    public void execute(SchedulableContext sc) {
        Boolean isValidAcc;
        Id blaRecord = NULL;
        Map<Id, String> templateIdEntityMap = new Map<Id, String>();
        List<AccountContactRelation> contacts =new List<AccountContactRelation>();
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        try {
            //fetch acc status and rec type from metadata
            accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            for(Account activeAccRec : [SELECT Id, Status__c, Name, 
                                        (SELECT Id, ContactId, Contact.Name, Contact.Email, PrimaryContact__c,IsActive
                                         FROM AccountContactRelations 
                                         WHERE IsActive = TRUE AND Contact.Email != NULL),
                                        (SELECT Id, Account.Name, RenewalYear__c, CreatedDate,Account.ParentId
                                         FROM BusinessLicenseApplicationAccount 
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType AND 
                                         Status =: BCMOH_Constants.sentBlaStatus
                                         AND Id IN (SELECT ParentRecordId FROM RegulatoryTrxnFee WHERE Status = 'Due' AND FeeType__c =: BCMOH_Constants.feeType) LIMIT 1),
                                        (SELECT Id, RegistrationCertificate__c 
                                         FROM AccountBusinessLicenses__r WHERE Status =: BCMOH_Constants.activeStatusBl LIMIT 1),
                                        (SELECT Id, Capacity__c, Quantity, Type__c 
                                         FROM Assets
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.parentAssetRecType
                                         AND Type__c IN: BCMOH_Constants.allALUnitTypes)
                                        FROM Account 
                                        WHERE (RecordType.DeveloperName =: BCMOH_Constants.accRecType OR RecordType.DeveloperName =: BCMOH_Constants.accRegType) 
                                       ]){
                                           isValidAcc = true;
                                           
                                           if(activeAccRec.BusinessLicenseApplicationAccount.size() == 0) {
                                               isValidAcc = false;
                                               continue;
                                           }
                                           
                                           
                                           if(activeAccRec.AccountBusinessLicenses__r.size() == 0) { 
                                           }
                                           else if(isValidAcc) {
                                               blMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec.AccountBusinessLicenses__r[0]);
                                           }
                                           
                                           //if account is valid then fetch the bla Ids associated with the account to fetch its files attached
                                           if(isValidAcc) {
                                               
                                               accMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec);
                                               
                                               accContactMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, 
                                                                 activeAccRec.AccountContactRelations[0]);
                                               
                                               if(activeAccRec.Assets.size() != 0) {
                                                   Integer unitCounter = 0;
                                                   for(Asset parentAsset : activeAccRec.Assets) {
                                                       unitCounter = unitCounter + Integer.valueOf(parentAsset.Quantity);
                                                   }
                                                   blaTotalAlUnitsMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, unitCounter);
                                               }
                                               //bla map and blaId-contactId map for email targetIds
                                               for(BusinessLicenseApplication blaRec : activeAccRec.BusinessLicenseApplicationAccount) {
                                                   blaMap.put(blaRec.Id, blaRec);
                                                   blaRecord = blaRec.Id;
                                                   contacts = getContacts(blaRec.AccountId,blaRec.Account.ParentId);
                                                   
                                                   blaContactMap.put(blaRecord,new List<Id>()); 
                                               }
                                               for(AccountContactRelation cont : contacts)
                                               {
                                                   contactIdList.add(cont.ContactId);
                                                   if(blaContactMap.containsKey(blaRecord)) {
                                                       blaContactMap.get(blaRecord).add(cont.ContactId);
                                                   } else {
                                                       blaContactMap.put(blaRecord, new List<Id> { cont.ContactId });
                                                   } 
                                               }
                                           }
                                       }
            
            
            
            //if valid blas are fetched
            if(!blaMap.isEmpty()) {
                //fetch template Id
                templateIdEntityMap = fetchTemplateDetails(BCMOH_Constants.templatePurpose);//email template
                orgWideAddrId = getOrgWideId();
                if(!sendEmailValid) {
                    for(Id blaId : blaMap.keySet()) {
                        blaErrMap.put(blaId, errMessage);
                    }
                }
                else {
                    blaContentVerMap = fetchAttachmentDetails(blaMap.keySet());
                    whatIdTargetMap = blaContactMap;
                    sendEmailForRenewals(blaContentVerMap, whatIdTargetMap);
                }
            }
            
        }
        catch(exception err) {
            system.debug('use exception handling sendEmailForRenewals'+err.getMessage());
        }
    }
    
    public Static List<AccountContactRelation> getContacts(Id accountId, Id parentId){
        return [Select Id,ContactId,AccountId,IsActive,Contact.Email from AccountContactRelation where (AccountId = :accountId OR AccountId =: parentId) AND IsActive =true AND Contact.Email != NULL];
        
    }
    
    //send email method
    public static void sendEmailForRenewals(Map<Id, Set<Id>> blaContentVerMap, Map<Id, List<Id>> whatIdTargetMap) {
        Id contactId = NULL;
        BusinessLicense blRec = new BusinessLicense();
        Integer totalALUnits = 0;
        List<Id> blaIdRec = new List<Id>();
        List<Id> contId =New List<Id>();
        Map<String, Id> duplicateEmailRemovalMap = new Map<String, Id>();
        Id FinalList;
        
        //List<Id> attachIds = new List<Id>();
        List<Messaging.SingleEmailMessage> singleEmailMsgList = new List<Messaging.SingleEmailMessage>();        
        try {
            
            for(Id whatId : whatIdTargetMap.KeySet()) {
                
                //fetch attachments for email attached to WhatId (Bla Id)
                List<Id> attachIds = new List<Id>(blaContentVerMap.get(whatId));
                if(!blaMap.isEmpty() && !accMap.isEmpty() &&
                   blaMap.get(whatId) != NULL && accMap.get(whatId) != NULL) {
                       blRec = !blMap.isEmpty() && blMap.get(whatId) != NULL ? blMap.get(whatId) : NULL;//get BL record
                       totalALUnits = !blaTotalAlUnitsMap.isEmpty() && blaTotalAlUnitsMap.get(whatId) != NULL ?
                           blaTotalAlUnitsMap.get(whatId) : 0;//get Total AL Units value
                       emailBody = replaceMergeFields(emailBodyConst, accContactMap.get(whatId), blaMap.get(whatId), 
                                                      accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       //ALR-827 - adding html value to email
                       emailHtmlBody = replaceMergeFields(emailHtmlBodyConst, accContactMap.get(whatId), blaMap.get(whatId), 
                                                          accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       //ALR-827 - if replaceMergeFields mthod returned null, err in replacing merge fields in template
                       if(emailBody == NULL || emailHtmlBody == NULL) {
                           continue;//go to next record
                       }
                       subjectValue = replaceMergeFields(subjectValueConst, accContactMap.get(whatId), blaMap.get(whatId),
                                                         accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       if(subjectValue == NULL) {
                           continue;//go to next record
                       }
                       //if not err occured, blaErrMap will not contain whatId
                       if(!blaErrMap.containsKey(whatId)) {
                           //set params for email record
                           for(Id conId : whatIdTargetMap.get(whatId)){
                               contactId = conId;
                               Messaging.SingleEmailMessage emailMsgRec = BCMOH_UtilityClass.setEmailParams(contactId, NULL, orgWideAddrId, attachIds, whatId, emailBody, subjectValue, emailHtmlBody);//ALR-827 - added emailHtmlBody
                               singleEmailMsgList.add(emailMsgRec);
                           }   
                           
                       }
                   }
                else {
                    blaErrMap.put(whatId, BCMOH_Constants.mappingDataMissing);//required data missing account and bla records-corner scenario
                }
            }
            
            if(singleEmailMsgList != NULL && singleEmailMsgList.size() > 0) {
                Messaging.SendEmailResult[] emailResultList = Messaging.SendEmail(singleEmailMsgList, false);//send email inspite of failures in list
                
                
            }
            
        }
        catch(Exception err) {
            system.debug('use exception handling sendEmailForRenewals'+err.getMessage());
            
        }
    }
    
    public static Map<Id, Set<Id>> fetchAttachmentDetails(Set<Id> blaIds) {
        Map<Id, Set<Id>> blaContentVerMap = new Map<Id, Set<Id>>();
        try {
            BCMOH_UtilityClass.ContentDocWrapper ContentDocWrapperRec = BCMOH_UtilityClass.getContentDocMap(blaIds);
            if(ContentDocWrapperRec != NULL) {
                for(Id blaId : ContentDocWrapperRec.entityContentIdsMap.KeySet()) {
                    for(Id docId : ContentDocWrapperRec.entityContentIdsMap.get(blaId)) {
                        Set<Id> contentVerIdSet = new Set<Id>();
                        if(blaContentVerMap.containsKey(blaId)) {
                            contentVerIdSet = blaContentVerMap.get(blaId);
                        }
                        contentVerIdSet.add(ContentDocWrapperRec.contentDocVerMap.get(docId));
                        blaContentVerMap.put(blaId, contentVerIdSet);
                    }
                }
            }
        }
        catch(Exception err) {
            system.debug('use exception handling fetchAttachmentDetails'+err.getMessage());
        }
        return blaContentVerMap;
    }
    
    
    
    //method to replace merge fields in email template
    public static String replaceMergeFields(String templateData, AccountContactRelation accContactRec, 
                                            BusinessLicenseApplication blaRec, Account accRec, 
                                            BusinessLicense blRec, String totalALUnits) {
                                                String mergeFieldValue = '';
                                                try {
                                                    for(TemplateMergeFieldMapping__mdt  templateMapping : TemplateMergeFieldMapping__mdt.getAll().values()) {
                                                        if(templateMapping.EmailTemplate__c == templateDetailsId &&
                                                           templateMapping.ObjectName__c == 'AccountContactRelation') {
                                                               templateData = templateData.replace(templateMapping.MergeField__c,
                                                                                                   accContactRec.get(templateMapping.FieldAPIName__c).toString());
                                                           }
                                                        else if(templateMapping.EmailTemplate__c == templateDetailsId &&
                                                                templateMapping.ObjectName__c == 'Account') {
                                                                    mergeFieldValue = accRec.get(templateMapping.FieldAPIName__c) != NULL ? 
                                                                        accRec.get(templateMapping.FieldAPIName__c).toString() : NULL;
                                                                    if(mergeFieldValue != NULL || mergeFieldValue != '') {
                                                                        templateData = templateData.replace(templateMapping.MergeField__c, 
                                                                                                            accRec.get(templateMapping.FieldAPIName__c).toString());
                                                                    }
                                                                }
                                                        else if(templateMapping.EmailTemplate__c == templateDetailsId &&
                                                                templateMapping.ObjectName__c == 'BusinessLicenseApplication') {
                                                                    if(templateMapping.FieldAPIName__c == 'CreatedDate') {
                                                                        templateData = templateData.replace(templateMapping.MergeField__c,
                                                                                                            Date.valueOf(blaRec.get(templateMapping.FieldAPIName__c)).format());
                                                                    }
                                                                    else {
                                                                        templateData = templateData.replace(templateMapping.MergeField__c,
                                                                                                            blaRec.get(templateMapping.FieldAPIName__c).toString());
                                                                    }
                                                                }
                                                        else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.ObjectName__c == 'BusinessLicense') {
                                                            if(blRec != NULL && blRec.get(templateMapping.FieldAPIName__c) != NULL) {
                                                                templateData = templateData.replace(templateMapping.MergeField__c, blRec.get(templateMapping.FieldAPIName__c).toString());
                                                            }
                                                            else if(templateData.contains(templateMapping.MergeField__c)) {
                                                                blaErrMap.put(blaRec.Id, BCMOH_Constants.mappingDataMissing+' for '+
                                                                              templateMapping.ObjectName__c+'.'+templateMapping.FieldAPIName__c);
                                                                return NULL;
                                                            }
                                                        }
                                                        else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.MergeFieldFormula__c == 'nextYear') {
                                                            templateData = templateData.replace(templateMapping.MergeField__c, BCMOH_Constants.nextYear);
                                                        }
                                                        else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.MergeFieldFormula__c == 'totalALUnits') {
                                                            templateData = templateData.replace(templateMapping.MergeField__c, totalALUnits);
                                                        }
                                                    }
                                                }
                                                catch(Exception err) {
                                                    system.debug('use exception handling sendEmailForRenewals'+err.getMessage());
                                                }
                                                return templateData;
                                            }
    
    //fetch templateId needed to send the email
    public static Map<Id, String> fetchTemplateDetails(String purpose) {
        Map<Id, String> templateDetails = new Map<Id, String>();
        EmailTemplate emailTempRec = new EmailTemplate();
        try {
            //fetch email template name from metadata
            templateDetailsMap = BCMOH_UtilityClass.getEmailtemplateName(purpose);
            // templateDetailsMap = fetchTemplateDetails(purpose);
            templateDetailName = templateDetailsMap.values()[0];
            templateDetailsId = new List<Id>(templateDetailsMap.keyset())[0];
            if(!templateDetailsMap.isEmpty()) {
                //fetch template details from email template
                // emailTempRec = BCMOH_UtilityClass.getEmailTemplate(templateDetailName);
                emailTempRec = BCMOH_UtilityClass.getEmailTemplateforRenewals(templateDetailName);
                if(emailTempRec != NULL) {
                    templateDetails.put(emailTempRec.Id, emailTempRec.RelatedEntityType);
                    templateEntity = emailTempRec.RelatedEntityType;
                    templateId = emailTempRec.Id;
                    subjectValue = emailTempRec.Subject;
                    subjectValueConst = emailTempRec.Subject;
                    emailBody = emailTempRec.Body;
                    emailBodyConst = emailTempRec.Body;
                    emailHtmlBody = emailTempRec.HtmlValue;
                    emailHtmlBodyConst = emailTempRec.HtmlValue;
                    
                }
                else {
                    errMessage = templateId == NULL ? BCMOH_Constants.templateNameMissing+templateDetailName : '';
                    sendEmailValid = false;
                }
            }
            else {
                errMessage = BCMOH_Constants.activePurposeTemplateMissing+purpose+' purpose';
                sendEmailValid = false;
            }
        }
        catch(Exception err) {
            system.debug('use exception handling sendEmailForRenewals'+err.getMessage());
        }
        return templateDetails;
    }
}