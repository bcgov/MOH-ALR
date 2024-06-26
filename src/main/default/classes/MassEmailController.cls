/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Test class for MassEmailController and BCMOH_UtilityClass and RenewalBlaTableController
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                          ALR -560             Sweta          Renewal verification and renewal mass email
***********************************************************************************************/
public with sharing class MassEmailController {
    Public Static Id templateId = NULL;
    Public Static String templateEntity = '';
    Public Static Map<Id, Id> targetWhatIdMap = new Map<Id, Id>();
    Public Static Map<Id, Id> whatIdTargetMap = new Map<Id, Id>();
    
    Public Static Id orgWideAddrId = NULL;
    Public Static String templateDevName = '';
    Public Static Map<Id, String> templateDetailsMap = new Map<Id, String>();
    Public Static String templateDetailName = '';
    
    
    Public Static String className = 'MassEmailController';
    
    Public Static Id templateDetailsId = NULL;
    Public Static String emailBody = '';
    Public Static String subjectValue = '';
    Public Static String emailBodyConst = '';
    Public Static String subjectValueConst = '';
    
    Public Static String emailHtmlBodyConst = '';
    Public Static String emailHtmlBody = '';
    
    Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
    Public Static Map<Id, Id> blaContactMap = new Map<Id, Id>();
    Public Static Map<Id, AccountContactRelation> accContactMap = new Map<Id, AccountContactRelation>();
    Public Static Map<Id, Account> accMap = new Map<Id, Account>();
    Public Static Map<Id, BusinessLicense> blMap = new Map<Id, BusinessLicense>();
    Public Static Map<Id, Integer> blaTotalAlUnitsMap = new Map<Id, Integer>();
    Public Static Map<Id, Set<Id>> blaContentVerMap = new Map<Id, Set<Id>>();
    private Final Static String RegTxnFeeStatus = 'Due';
    public Final Static String FeeTypeStatuses = 'Renewal Unit Fee';
    
    Public Static String errMessage = '';
    Public Static Boolean sendEmailValid = true;
    Public Static Map<Id, String> blaErrMap = new Map<Id, String>();
    Public Static Map<Id, String> blaSuccessMap = new Map<Id, String>();
    Public Static List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>();
    
    //method to to send email to records
    @AuraEnabled
    public static void doSendRenewals() {
        Boolean isValidAcc;
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        Map<Id, String> templateIdEntityMap = new Map<Id, String>();
        Id orgWideAddrId = NULL;
        Map<Id, Set<Id>> contactContentVerMap = new Map<Id, Set<Id>>();
        
        try {
            //fetch acc status and rec type from metadata
            accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            for(Account activeAccRec : [SELECT Id, Status__c, Name, 
                                        (SELECT Id, ContactId, Contact.Name, Contact.Email, PrimaryContact__c,IsActive
                                         FROM AccountContactRelations 
                                         WHERE IsActive = TRUE AND Contact.Email != NULL),
                                        (SELECT Id, Account.Name, RenewalYear__c, CreatedDate 
                                         FROM BusinessLicenseApplicationAccount 
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType AND 
                                         Status =: BCMOH_Constants.blaCreatedStatus
                                         AND RenewalYear__c =: BCMOH_Constants.renewalYear LIMIT 1),
                                        (SELECT Id, RegistrationCertificate__c 
                                         FROM AccountBusinessLicenses__r WHERE Status =: BCMOH_Constants.activeStatusBl LIMIT 1),
                                        (SELECT Id, Capacity__c, Quantity, Type__c 
                                         FROM Assets
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.parentAssetRecType
                                         AND Type__c IN: BCMOH_Constants.allALUnitTypes)
                                        FROM Account 
                                        WHERE (RecordType.DeveloperName =: BCMOH_Constants.accRecType OR RecordType.DeveloperName =: BCMOH_Constants.accRegType) AND 
                                        Status__c IN: accDetails.values()[0] 
                                       ]){
                                           isValidAcc = true;
                                           
                                           if(activeAccRec.BusinessLicenseApplicationAccount.size() == 0) {
                                               isValidAcc = false;
                                               continue;
                                           }
                                           
                                           if(isValidAcc && activeAccRec.AccountContactRelations.size() == 0) {
                                               isValidAcc = false;
                                               blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, BCMOH_Constants.noPrimaryContact);
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
                                               for(BusinessLicenseApplication blaRec : 
                                                   activeAccRec.BusinessLicenseApplicationAccount) {
                                                       blaMap.put(blaRec.Id, blaRec);
                                                       for(Contact cont : [Select id,Name from Contact where Contact.AccountId =:blaRec.AccountId ])

                                                           {

                                                                blaContactMap.put(blaRec.Id,cont.Id); 

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
            //finally update bla records based on the err and success maps
            updateBlaStatus();
        }
        catch(exception err) {
            system.debug('yui im caught'+err.getMessage());
            LogService.logAndPublish(className, 'doSendRenewals', '', err);
        }
    }
    
    //method to to send email to records-ALR-1000
    @AuraEnabled
    public static void doSendLateFee() {
        Boolean isValidAcc;
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        Map<Id, String> templateIdEntityMap = new Map<Id, String>();
        Id orgWideAddrId = NULL;
        Map<Id, Set<Id>> contactContentVerMap = new Map<Id, Set<Id>>();
        try {
            //fetch acc status and rec type from metadata
            accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            for(Account activeAccRec : [SELECT Id, Status__c, Name, 
                                        (SELECT Id, ContactId, Contact.Name, Contact.Email, PrimaryContact__c,IsActive
                                         FROM AccountContactRelations 
                                         WHERE IsActive = TRUE AND Contact.Email != NULL),
                                        (SELECT Id, Account.Name, RenewalYear__c, CreatedDate,AccountId
                                         FROM BusinessLicenseApplicationAccount 
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType AND 
                                         Late_Fee_Status__c =: BCMOH_Constants.blaLateFeeStatus 
                                         AND RenewalYear__c =: BCMOH_Constants.renewalYear LIMIT 1),
                                        (SELECT Id, RegistrationCertificate__c 
                                         FROM AccountBusinessLicenses__r WHERE Status =: BCMOH_Constants.activeStatusBl LIMIT 1),
                                        (SELECT Id, Capacity__c, Quantity, Type__c 
                                         FROM Assets
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.parentAssetRecType
                                         AND Type__c IN: BCMOH_Constants.allALUnitTypes)
                                        FROM Account 
                                       WHERE (RecordType.DeveloperName =: BCMOH_Constants.accRecType OR RecordType.DeveloperName =: BCMOH_Constants.accRegType) AND
                                        Status__c IN: accDetails.values()[0] 
                                        
                                       ]) {
                                           isValidAcc = true;
                                           if(activeAccRec.BusinessLicenseApplicationAccount.size() == 0) {
                                               isValidAcc = false;
                                               continue;
                                           }
                                           if(isValidAcc && activeAccRec.AccountContactRelations.size() == 0) {
                                               isValidAcc = false;
                                               blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, BCMOH_Constants.noPrimaryContact);
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
                                               for(BusinessLicenseApplication blaRec : 
                                                   activeAccRec.BusinessLicenseApplicationAccount) {
                                                        blaMap.put(blaRec.Id, blaRec);
                                                        for(Contact cont : [Select id,Name from Contact where Contact.AccountId =:blaRec.AccountId ])

                                                           {

                                                                blaContactMap.put(blaRec.Id,cont.Id); 

                                                           }
                                                   }
                                           }
                                       }
            
            //if valid blas are fetched
            if(!blaMap.isEmpty()) {
                templateIdEntityMap = fetchTemplate(BCMOH_Constants.templatePurposeDetails);//email template
                orgWideAddrId = getOrgWideId();//email from address
                //if template or org wide id is not fetched, update error on valid bla records
                if(!sendEmailValid) {
                    for(Id blaId : blaMap.keySet()) {
                        blaErrMap.put(blaId, errMessage);
                    }
                }
                else {
                    //fetch email attachments associated to BLA records
                    blaContentVerMap = fetchAttachmentDetails(blaMap.keySet());
                    whatIdTargetMap = blaContactMap;
                    sendEmailForRenewals(blaContentVerMap, whatIdTargetMap);
                }
            }
            //finally update bla records based on the err and success maps
            updateLateFeeBlaStatus();
        }
        catch(exception err) {
            system.debug('yui im caught'+err.getMessage());
            LogService.logAndPublish(className, 'doSendLateFee', '', err);
        }
    }
    
    //send email method
    public static void sendEmailForRenewals(Map<Id, Set<Id>> blaContentVerMap, Map<Id, Id> whatIdTargetMap) {
        Id contactId = NULL;
        BusinessLicense blRec = new BusinessLicense();
        Integer totalALUnits = 0;
        Id blaIdRec = NULL;
         Set<Id> contId =New Set<Id>();
 
        List<Id> attachIds = new List<Id>();
         List<Messaging.SingleEmailMessage> singleEmailMsgList = new List<Messaging.SingleEmailMessage>();
        try {
            for(Id whatId : whatIdTargetMap.KeySet()) {
                blaIdRec = whatId;
               contactId = whatIdTargetMap.isEmpty() ? NULL : whatIdTargetMap.get(whatId);
                
                if(!blaMap.isEmpty() && !accMap.isEmpty() &&
                   blaMap.get(whatId) != NULL && accMap.get(whatId) != NULL) {
                       blRec = !blMap.isEmpty() && blMap.get(whatId) != NULL ? blMap.get(whatId) : NULL;//get BL record
                       totalALUnits = !blaTotalAlUnitsMap.isEmpty() && blaTotalAlUnitsMap.get(whatId) != NULL ?
                           blaTotalAlUnitsMap.get(whatId) : 0;//get Total AL Units value
                       emailBody = replaceMergeFields(emailBodyConst, accContactMap.get(whatId), blaMap.get(whatId), 
                                                      accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       emailHtmlBody = replaceMergeFields(emailHtmlBodyConst, accContactMap.get(whatId), blaMap.get(whatId), 
                                                          accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       if(emailBody == NULL || emailHtmlBody == NULL) {
                           continue;
                       }
                       subjectValue = replaceMergeFields(subjectValueConst, accContactMap.get(whatId), blaMap.get(whatId),
                                                         accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       if(subjectValue == NULL) {
                           continue;
                       }
                       
                   }
                else {
                    blaErrMap.put(whatId, BCMOH_Constants.mappingDataMissing);//required data missing account and bla records-corner scenario
                }
            }
            BusinessLicenseApplication blaObject= [select AccountId,Account.ParentId from BusinessLicenseApplication where Id=:blaIdRec LIMIT 1];
           
            List<AccountContactRelation> conRec = [Select Id,AccountId,ContactId, Contact.Email,Account.ParentId from AccountContactRelation where (AccountId =: blaObject.AccountId OR AccountId =: blaObject.Account.ParentId) AND IsActive = TRUE];
                      for(AccountContactRelation acr : conRec){
                contId.add(acr.ContactId);
            }
             for(AccountContactRelation conIds : conRec) {
                           if(!blaErrMap.containsKey(blaIdRec)) {
                           Messaging.SingleEmailMessage emailMsgRec = BCMOH_UtilityClass.setEmailParams(conIds.ContactId, NULL, orgWideAddrId, attachIds, blaIdRec, emailBody, subjectValue, emailHtmlBody);//ALR-827 - added emailHtmlBody
                           singleEmailMsgList.add(emailMsgRec);
                       }
            }
             if(singleEmailMsgList != NULL && singleEmailMsgList.size() > 0) {
                Messaging.SendEmailResult[] emailResultList = Messaging.SendEmail(singleEmailMsgList, false);//send email inspite of failures in list
                getEmailStatus(emailResultList, singleEmailMsgList, whatIdTargetMap);
                
            }
            
        }
        catch(Exception err) {
            system.debug('use exception handling sendEmailForRenewals'+err.getMessage());
            system.debug('use exception handling sendEmailForRenewals'+err.getLineNumber());
        }
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
                                                    system.debug('use exception handling replaceMergeFields '+err.getMessage());
                                                    LogService.logAndPublish(className, 'replaceMergeFields', blaRec.Id, err);
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
            templateDetailName = templateDetailsMap.values()[0];
            templateDetailsId = new List<Id>(templateDetailsMap.keyset())[0];
            if(!templateDetailsMap.isEmpty()) {
                //fetch template details from email template
                emailTempRec = BCMOH_UtilityClass.getEmailTemplate(templateDetailName);
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
            system.debug('use exception handling fetchTemplateId'+ err.getMessage());
            LogService.logAndPublish(className, 'fetchTemplateDetails', '', err);
        }
        return templateDetails;
    }
    
    //fetch templateId needed to send the email
    public static Map<Id, String> fetchTemplate(String purpose) {
        Map<Id, String> templateDetails = new Map<Id, String>();
        EmailTemplate emailTempRec = new EmailTemplate();
        try {
            //fetch email template name from metadata
            templateDetailsMap = BCMOH_UtilityClass.getEmailtemplatebyName(purpose);
            templateDetailName = templateDetailsMap.values()[0];
            templateDetailsId = new List<Id>(templateDetailsMap.keyset())[0];
            if(!templateDetailsMap.isEmpty()) {
                //fetch template details from email template
                emailTempRec =[Select Id, Name, DeveloperName, Description, Subject, HtmlValue, Body, RelatedEntityType from EmailTemplate where name='Renewal Late Fee Notification Letter'];
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
            system.debug('use exception handling fetchTemplateId is'+err.getMessage());
            LogService.logAndPublish(className, 'fetchTemplate', '', err);
        }
        return templateDetails;
    }    
    
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
            system.debug('use exception handling getOrgWideId '+err.getMessage());
            LogService.logAndPublish(className, 'getOrgWideId', '', err);
        }
        return orgWideAddrId;
    }
    
    //fetch blaId-ContentVersions Map needed to add attachments to the email
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
            system.debug('use exception handling fetchAttachmentDetails '+err.getMessage());
            LogService.logAndPublish(className, 'fetchAttachmentDetails', '', err);
        }
        return blaContentVerMap;
    }
    
    //update bla success and error maps after sending email
    public static void getEmailStatus(Messaging.SendEmailResult[] emailResultList, 
                                      List<Messaging.SingleEmailMessage> singleEmailMsgList, Map<Id, Id> whatIdTargetMap) {
                                          Map<Id, String> targetIdErrorMap = new Map<Id, String>();
                                          try {
                                              for(Messaging.SendEmailResult eResRec : emailResultList) {
                                                  if(!eResRec.isSuccess()) {
                                                      for(Messaging.SendEmailError err : eResRec.getErrors()) {
                                                          targetIdErrorMap.put(err.getTargetObjectId(), err.getMessage());
                                                      }
                                                  }
                                              }
                                              for(Messaging.SingleEmailMessage msgRec : singleEmailMsgList) {
                                                  if(targetIdErrorMap.containsKey(whatIdTargetMap.get(msgRec.whatId))) {
                                                      blaErrMap.put(msgRec.whatId, targetIdErrorMap.get(whatIdTargetMap.get(msgRec.whatId)));
                                                  }
                                                  else {
                                                      String sentDetails = BCMOH_Constants.emailSentToId+' '+accContactMap.get(msgRec.whatId).Contact.Email+
                                                          '. '+BCMOH_Constants.emailSentTo+' '+accContactMap.get(msgRec.whatId).Contact.Name+'. '+BCMOH_Constants.sentTime+' '+datetime.now().format();//add to const
                                                      blaSuccessMap.put(msgRec.whatId, sentDetails);
                                                  }
                                              }
                                          }
                                          catch(exception err) {
                                              system.debug('caught in meth - '+err.getMessage());
                                              LogService.logAndPublish(className, 'updateTargetRecsStatus', '', err);
                                          }
                                      }
    
    public static void updateBlaStatus() {
        Set<Id> blaIds = new Set<Id>();
        try {
            // Collect BLA IDs from both maps
        blaIds.addAll(blaErrMap.keySet());
        blaIds.addAll(blaSuccessMap.keySet());
        // Query all relevant BLAs at once
        Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>([SELECT Id, AccountId, RenewalDetail__c, Status FROM BusinessLicenseApplication WHERE Id IN :blaIds]);
        // Update BLAs and related Accounts
      
            for (Id blaId : blaIds) {
             BusinessLicenseApplication blaRec = blaMap.get(blaId);
            if (blaRec != null) {
                  // Update BLAs based on the map they are present in
                if (blaErrMap.containsKey(blaId)) {
                     String renewalMsg = blaErrMap.get(blaId).length() > 255 ? blaErrMap.get(blaId).Substring(0, 255) : blaErrMap.get(blaId);
                    String errMsg = blaErrMap.get(blaId);
                    errMsg = blaRec.RenewalDetail__c != null ? blaRec.RenewalDetail__c + ' ; ' + renewalMsg : renewalMsg;
                    blaRec.Status = BCMOH_Constants.errorBlaStatus;
                    blaRec.RenewalDetail__c = errMsg;
                } else if (blaSuccessMap.containsKey(blaId)) {
                     String renewalMsg = blaSuccessMap.get(blaId).length() > 255 ? blaSuccessMap.get(blaId).Substring(0, 255) : blaSuccessMap.get(blaId);
                    String succMsg = String.isEmpty(blaRec.RenewalDetail__c) ? renewalMsg : blaRec.RenewalDetail__c + ' ; ' + renewalMsg;
                    blaRec.Status = BCMOH_Constants.sentBlaStatus;
                    blaRec.RenewalDetail__c = succMsg;
                  }
                blaUpdateList.add(blaRec);
             }
            else {
            }
        }
            if(!blaUpdateList.isEmpty() && BusinessLicenseApplication.sObjectType.getDescribe().isUpdateable()) {
                Database.Update(blaUpdateList, false);               
            }
        }
        catch(exception err) {
            system.debug('caught in updateBlaStatus - '+err.getMessage());
            LogService.logAndPublish(className, 'updateBlaStatus', '', err);
        }
    }

    public Static Id getAccountId(Id blaId) {
        return [SELECT AccountId FROM BusinessLicenseApplication WHERE Id = :blaId][0].AccountId;
    }
    public Static List<Account> updateAccountStatus(Id accId) {
         return [SELECT Status__c FROM Account WHERE Id = :accId];
    }
    public Static List<BusinessLicenseApplication> blaErrQuery(Id blaId) {
        return [SELECT RenewalDetail__c FROM BusinessLicenseApplication WHERE Id =:blaId LIMIT 1];
    }
    
   
    public static void updateLateFeeBlaStatus() {
    List<Account> accToUpdate = new List<Account>();
    List<BusinessLicenseApplication> blaToUpdate = new List<BusinessLicenseApplication>();
    Set<Id> blaIds = new Set<Id>();
 
    try {
        // Collect BLA IDs from both maps
        blaIds.addAll(blaErrMap.keySet());
        blaIds.addAll(blaSuccessMap.keySet());
        // Query all relevant BLAs at once
        Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>([SELECT Id, AccountId, RenewalDetail__c, Late_Fee_Status__c FROM BusinessLicenseApplication WHERE Id IN :blaIds]);
        // Update BLAs and related Accounts
        for (Id blaId : blaIds) {
             BusinessLicenseApplication blaRec = blaMap.get(blaId);
            if (blaRec != null) {
                  // Update BLAs based on the map they are present in
                if (blaErrMap.containsKey(blaId)) {
                     String lateFeeMsg = blaErrMap.get(blaId).length() > 255 ? blaErrMap.get(blaId).Substring(0, 255) : blaErrMap.get(blaId);
                    String errMsg = blaErrMap.get(blaId);
                    errMsg = blaRec.RenewalDetail__c != null ? blaRec.RenewalDetail__c + ' ; ' + lateFeeMsg : lateFeeMsg;
                    blaRec.Late_Fee_Status__c = BCMOH_Constants.errorBlaStatus;
                    blaRec.RenewalDetail__c = errMsg;
                } else if (blaSuccessMap.containsKey(blaId)) {
                     String lateFeeMsg = blaSuccessMap.get(blaId).length() > 255 ? blaSuccessMap.get(blaId).Substring(0, 255) : blaSuccessMap.get(blaId);
                    String succMsg = String.isEmpty(blaRec.RenewalDetail__c) ? lateFeeMsg : blaRec.RenewalDetail__c + ' ; ' + lateFeeMsg;
                    blaRec.Late_Fee_Status__c = BCMOH_Constants.sentBlaStatus;
                    blaRec.RenewalDetail__c = succMsg;
                    // Add Account to the update list if AccountId is not null
                    if (blaRec.AccountId != null) {
                       accToUpdate.add(new Account(Id = blaRec.AccountId, Status__c = BCMOH_Constants.AccStatus));
                    } 
                 }
                blaToUpdate.add(blaRec);
             }
            else {
            }
        }
 
        // Perform updates
        if (!blaToUpdate.isEmpty()) {
            Database.update(blaToUpdate, false);
        }
        if (!accToUpdate.isEmpty()) {
            //update accToUpdate.values();
            Database.update(accToUpdate, false);
             }
    } catch (Exception err) {
        System.debug('caught in updateLateFeeBlaStatus - ' + err.getMessage());
        LogService.logAndPublish(className, 'updateLateFeeBlaStatus', '', err);
    }
}
}