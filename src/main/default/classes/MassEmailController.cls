/**
* @Name              : MassEmailController
* @Description       : Controller class to send mass email
Test class MassEmailControllerTest
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
public with sharing class MassEmailController {
    //Set<Id> selectedBlaIds = new Set<Id>{'0f0As000000065RIAQ'};//may get from list view/lightning comp
    Public Static Id templateId = NULL;
    Public Static String templateEntity = '';
    Public Static Map<Id, Id> targetWhatIdMap = new Map<Id, Id>();
    Public Static Map<Id, Id> whatIdTargetMap = new Map<Id, Id>();
    
    
    Public Static Id orgWideAddrId = NULL;
    Public Static String templateDevName = '';
    Public Static Map<Id, String> templateDetailsMap = new Map<Id, String>();
    Public Static String templateDetailName = '';
    
    //verified attributes all below are needed - remove comment later.
    Public Static String className = 'MassEmailController';
    
    Public Static Id templateDetailsId = NULL;
    Public Static String emailBody = '';
    Public Static String subjectValue = '';
    Public Static String emailBodyConst = '';
    Public Static String subjectValueConst = '';
    //ALR-827 - for html body
    Public Static String emailHtmlBodyConst = '';
    Public Static String emailHtmlBody = '';
    //ALR-827 ends
    
    Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
    Public Static Map<Id, Id> blaContactMap = new Map<Id, Id>();
    Public Static Map<Id, AccountContactRelation> accContactMap = new Map<Id, AccountContactRelation>();
    Public Static Map<Id, Account> accMap = new Map<Id, Account>();
    Public Static Map<Id, BusinessLicense> blMap = new Map<Id, BusinessLicense>();
    Public Static Map<Id, Integer> blaTotalAlUnitsMap = new Map<Id, Integer>();
    Public Static Map<Id, Set<Id>> blaContentVerMap = new Map<Id, Set<Id>>();
    
    Public Static String errMessage = '';//common err message for all records
    Public Static Boolean sendEmailValid = true;//false if template or org wide address is not found
    Public Static Map<Id, String> blaErrMap = new Map<Id, String>();
    Public Static Map<Id, String> blaSuccessMap = new Map<Id, String>();
    Public Static List<BusinessLicenseApplication> blaUpdateList = new List<BusinessLicenseApplication>();//bla records to update
    
    //method to to send email to records
    @AuraEnabled
    public static void doSendRenewals() {
        Boolean isValidAcc;
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        Map<Id, String> templateIdEntityMap = new Map<Id, String>();
        Id orgWideAddrId = NULL;
        Map<Id, Set<Id>> contactContentVerMap = new Map<Id, Set<Id>>();
        Set<Id> accIdSetTemp = new Set<Id>{'001As00000IGcv0IAD','001As00000IMmIEIA1','001As00000HVRtTIAX'};//temp delete acc
            //Set<Id> accIdSetTemp = new Set<Id>{'001As00000IMmIEIA1'};//temp delete xyz 
            try {
                //fetch acc status and rec type from metadata
                accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
                //fetch account, bla details
                //need to make query dynamic?
                for(Account activeAccRec : [SELECT Id, Status__c, Name, 
                                            (SELECT Id, ContactId, Contact.Name, Contact.Email, PrimaryContact__c
                                             FROM AccountContactRelations 
                                             WHERE PrimaryContact__c = TRUE AND IsActive = TRUE AND Contact.Email != NULL LIMIT 1),
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
                                            WHERE RecordType.DeveloperName =: accDetails.keyset() AND 
                                            Status__c IN: accDetails.values()[0] 
                                            //AND Id IN: accIdSetTemp
                                           ]) {
                                               isValidAcc = true;//setting account as valid initially
                                               
                                               //when valid renewal bla record is not available
                                               if(activeAccRec.BusinessLicenseApplicationAccount.size() == 0) {
                                                   isValidAcc = false;
                                                   continue;//skips following code and fetches next account in loop
                                               }
                                               //when primary contact(email's targetObjectId)/its email is not available
                                               if(isValidAcc && activeAccRec.AccountContactRelations.size() == 0) {
                                                   isValidAcc = false;
                                                   blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, BCMOH_Constants.noPrimaryContact);
                                                   continue;//skips following code and fetches next account in loop
                                               }
                                               //fetch business license record 
                                               if(activeAccRec.AccountBusinessLicenses__r.size() == 0) { 
                                                   //blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, BCMOH_Constants.noBLRec);
                                                }
                                               else if(isValidAcc) {
                                                   blMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec.AccountBusinessLicenses__r[0]);
                                               }
                                               
                                               //if account is valid then fetch the bla Ids associated with the account to fetch its files attached
                                               if(isValidAcc) {
                                                   //acc Map
                                                   accMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec);
                                                   
                                                   //acc contact map with bla id
                                                   accContactMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, 
                                                                     activeAccRec.AccountContactRelations[0]);
                                                   
                                                   //calculate total AL units if assets are present
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
                                                           blaContactMap.put(blaRec.Id, activeAccRec.AccountContactRelations[0].ContactId);
                                                       }
                                               }
                                           }
                //if valid blas are fetched
                if(!blaMap.isEmpty()) {
                    //fetch template Id
                    templateIdEntityMap = fetchTemplateDetails(BCMOH_Constants.templatePurpose);//email template
                    //fetch org wide address id
                    orgWideAddrId = getOrgWideId();//email from address
                    //if template or org wide id is not fetched, update error on valid bla records
                    if(!sendEmailValid) {
                        for(Id blaId : blaMap.keySet()) {
                            blaErrMap.put(blaId, errMessage);//err msg is set in child methods
                        }
                    }
                    else {
                        //fetch email attachments associated to BLA records
                        blaContentVerMap = fetchAttachmentDetails(blaMap.keySet());
                        //set whatId Target Map for send email method
                        whatIdTargetMap = blaContactMap;
                        //send email by passing the whatId-content map and whatid-target map
                        sendEmailForRenewals(blaContentVerMap, whatIdTargetMap);
                    }
                }
                //finally update bla records based on the err and success maps
                updateBlaStatus();
            }
        catch(exception ex) {
            system.debug('yui im caught'+ex.getMessage());
            LogService.logAndPublish(className, 'doSendRenewals', '', ex);
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
        Set<Id> accIdSetTemp = new Set<Id>{'001As00000IGcv0IAD','001As00000IMmIEIA1','001As00000HVRtTIAX'};//temp delete acc
            //Set<Id> accIdSetTemp = new Set<Id>{'001As00000IMmIEIA1'};//temp delete xyz 
            try {
                //fetch acc status and rec type from metadata
                accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
                //fetch account, bla details
                //need to make query dynamic?
                for(Account activeAccRec : [SELECT Id, Status__c, Name, 
                                            (SELECT Id, ContactId, Contact.Name, Contact.Email, PrimaryContact__c
                                             FROM AccountContactRelations 
                                             WHERE PrimaryContact__c = TRUE AND IsActive = TRUE AND Contact.Email != NULL LIMIT 1),
                                            (SELECT Id, Account.Name, RenewalYear__c, CreatedDate 
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
                                            WHERE RecordType.DeveloperName =: accDetails.keyset() AND 
                                            Status__c IN: accDetails.values()[0] 
                                            //AND Id IN: accIdSetTemp
                                           ]) {
                                               isValidAcc = true;//setting account as valid initially
                                               
                                               //when valid renewal bla record is not available
                                               if(activeAccRec.BusinessLicenseApplicationAccount.size() == 0) {
                                                   isValidAcc = false;
                                                   continue;//skips following code and fetches next account in loop
                                               }
                                               //when primary contact(email's targetObjectId)/its email is not available
                                               if(isValidAcc && activeAccRec.AccountContactRelations.size() == 0) {
                                                  isValidAcc = false;
                                                   blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, BCMOH_Constants.noPrimaryContact);
                                                   continue;//skips following code and fetches next account in loop
                                               }
                                               //fetch business license record 
                                               if(activeAccRec.AccountBusinessLicenses__r.size() == 0) { 
                                                   //blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, BCMOH_Constants.noBLRec);
                                                }
                                               else if(isValidAcc) {
                                                   blMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec.AccountBusinessLicenses__r[0]);
                                               }
                                               
                                               //if account is valid then fetch the bla Ids associated with the account to fetch its files attached
                                               if(isValidAcc) {
                                                  //acc Map
                                                   accMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec);
                                                   
                                                   //acc contact map with bla id
                                                   accContactMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, 
                                                                     activeAccRec.AccountContactRelations[0]);
                                                   
                                                   //calculate total AL units if assets are present
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
                                                           blaContactMap.put(blaRec.Id, activeAccRec.AccountContactRelations[0].ContactId);
                                                       }
                                               }
                                           }
                
                //if valid blas are fetched
                if(!blaMap.isEmpty()) {
                    //fetch template Id
                    templateIdEntityMap = fetchTemplate(BCMOH_Constants.templatePurposeDetails);//email template
                    //fetch org wide address id
                    orgWideAddrId = getOrgWideId();//email from address
                    //if template or org wide id is not fetched, update error on valid bla records
                    if(!sendEmailValid) {
                        for(Id blaId : blaMap.keySet()) {
                            blaErrMap.put(blaId, errMessage);//err msg is set in child methods
                        }
                    }
                    else {
                        //fetch email attachments associated to BLA records
                        blaContentVerMap = fetchAttachmentDetails(blaMap.keySet());
                        //set whatId Target Map for send email method
                        whatIdTargetMap = blaContactMap;
                        //send email by passing the whatId-content map and whatid-target map
                        sendEmailForRenewals(blaContentVerMap, whatIdTargetMap);
                    }
                }
                //finally update bla records based on the err and success maps
                //BCMOH_UtilityClass.updateBlaLateFeeStatus(blaErrMap,'Sent');
                updateLateFeeBlaStatus();
            }
        catch(exception ex) {
            system.debug('yui im caught'+ex.getMessage());
            LogService.logAndPublish(className, 'doSendLateFee', '', ex);
        }
    }
    
    
    //send email method
    public static void sendEmailForRenewals(Map<Id, Set<Id>> blaContentVerMap, Map<Id, Id> whatIdTargetMap) {
        //List<Id> attachIds = new List<Id>();
        Id contactId = NULL;
        BusinessLicense blRec = new BusinessLicense();
        Integer totalALUnits = 0;
        List<Messaging.SingleEmailMessage> singleEmailMsgList = new List<Messaging.SingleEmailMessage>();
        try {
            //blaId is whatId for email
            for(Id whatId : whatIdTargetMap.KeySet()) {
                //contact Id is Target Id for email
                contactId = whatIdTargetMap.isEmpty() ? NULL : whatIdTargetMap.get(whatId);
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
                       }//ALR-827 ends
                       subjectValue = replaceMergeFields(subjectValueConst, accContactMap.get(whatId), blaMap.get(whatId),
                                                         accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       if(subjectValue == NULL) {
                           continue;//go to next record
                       }
                       //if not err occured, blaErrMap will not contain whatId
                       if(!blaErrMap.containsKey(whatId)) {
                           //set params for email record
                           Messaging.SingleEmailMessage emailMsgRec = BCMOH_UtilityClass.setEmailParams(contactId, NULL, orgWideAddrId, attachIds, whatId, emailBody, subjectValue, emailHtmlBody);//ALR-827 - added emailHtmlBody
                           singleEmailMsgList.add(emailMsgRec);
                           
                       }
                   }
                else {
                    blaErrMap.put(whatId, BCMOH_Constants.mappingDataMissing);//required data missing account and bla records-corner scenario
                }
            }
            //Messaging.reserveSingleEmailCapacity(singleEmailMsgList.size());
            if(singleEmailMsgList != NULL && singleEmailMsgList.size() > 0) {
                Messaging.SendEmailResult[] emailResultList = Messaging.SendEmail(singleEmailMsgList, false);//send email inspite of failures in list
                //fetch email sent status and set success or err maps accordingly
                getEmailStatus(emailResultList, singleEmailMsgList, whatIdTargetMap);
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling sendEmailForRenewals'+ex.getMessage());
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
                                                catch(Exception ex) {
                                                    system.debug('use exception handling replaceMergeFields '+ex.getMessage());
                                                    LogService.logAndPublish(className, 'replaceMergeFields', blaRec.Id, ex);
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
                    emailHtmlBody = emailTempRec.HtmlValue;//ALR-827 - for html body
                    emailHtmlBodyConst = emailTempRec.HtmlValue;//ALR-827 - for html body
                }
                else {
                    //set error when email template was not fetched
                    errMessage = templateId == NULL ? BCMOH_Constants.templateNameMissing+templateDetailName : '';
                    system.debug(errMessage);//add in error handling
                    sendEmailValid = false;
                }
            }
            else {
                //set error when valid email template config is not available
                errMessage = BCMOH_Constants.activePurposeTemplateMissing+purpose+' purpose';
                system.debug(errMessage);//add in error handling
                sendEmailValid = false;
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling fetchTemplateId'+ex.getMessage());
            LogService.logAndPublish(className, 'fetchTemplateDetails', '', ex);
        }
        return templateDetails;
    }
    
    //fetch templateId needed to send the email-ALR-1000
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
                //emailTempRec = BCMOH_UtilityClass.getEmailTemplate(templateDetailName);
                emailTempRec =[Select Id, Name, DeveloperName, Description, Subject, HtmlValue, Body, RelatedEntityType from EmailTemplate where name='Renewal Late Fee Notification Letter'];
                if(emailTempRec != NULL) {
                    templateDetails.put(emailTempRec.Id, emailTempRec.RelatedEntityType);
                    templateEntity = emailTempRec.RelatedEntityType;
                    templateId = emailTempRec.Id;
                    subjectValue = emailTempRec.Subject;
                    subjectValueConst = emailTempRec.Subject;
                    emailBody = emailTempRec.Body;
                    emailBodyConst = emailTempRec.Body;
                    emailHtmlBody = emailTempRec.HtmlValue;//ALR-827 - for html body
                    emailHtmlBodyConst = emailTempRec.HtmlValue;//ALR-827 - for html body
                }
                else {
                    //set error when email template was not fetched
                    errMessage = templateId == NULL ? BCMOH_Constants.templateNameMissing+templateDetailName : '';
                    system.debug(errMessage);//add in error handling
                    sendEmailValid = false;
                }
            }
            else {
                //set error when valid email template config is not available
                errMessage = BCMOH_Constants.activePurposeTemplateMissing+purpose+' purpose';
                system.debug(errMessage);//add in error handling
                sendEmailValid = false;
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling fetchTemplateId is'+ex.getMessage());
            LogService.logAndPublish(className, 'fetchTemplate', '', ex);
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
                    //set error when valid org wide email address is not available
                    errMessage = BCMOH_Constants.noOrgWideAddr;
                    system.debug(errMessage);//add in error handling
                    sendEmailValid = false;
                }
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling getOrgWideId '+ex.getMessage());
            LogService.logAndPublish(className, 'getOrgWideId', '', ex);
        }
        return orgWideAddrId;
    }
    
    //fetch blaId-ContentVersions Map needed to add attachments to the email
    public static Map<Id, Set<Id>> fetchAttachmentDetails(Set<Id> blaIds) {
        Map<Id, Set<Id>> blaContentVerMap = new Map<Id, Set<Id>>();
        try {
            //fetch wrapper details with blaId-DocId Map and docId-contentVerId Map
            BCMOH_UtilityClass.ContentDocWrapper ContentDocWrapperRec = BCMOH_UtilityClass.getContentDocMap(blaIds);
            //fetch content versions per Bla record
            if(ContentDocWrapperRec != NULL) {
                for(Id blaId : ContentDocWrapperRec.entityContentIdsMap.KeySet()) {//for each bla rec Id
                    for(Id docId : ContentDocWrapperRec.entityContentIdsMap.get(blaId)) {//for each of its content document id
                        Set<Id> contentVerIdSet = new Set<Id>();
                        if(blaContentVerMap.containsKey(blaId)) {//if map contains the bla id
                            contentVerIdSet = blaContentVerMap.get(blaId);//fetch its content versions
                        }
                        contentVerIdSet.add(ContentDocWrapperRec.contentDocVerMap.get(docId));//add current version also to the list
                        //map's key value pair holds the whatId vs attachment ids per email
                        blaContentVerMap.put(blaId, contentVerIdSet);//set blaId-ContentVersionId map
                    }
                }
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling fetchAttachmentDetails '+ex.getMessage());
            LogService.logAndPublish(className, 'fetchAttachmentDetails', '', ex);
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
                                                      //Operation failed, get all errors                
                                                      for(Messaging.SendEmailError err : eResRec.getErrors()) {
                                                          targetIdErrorMap.put(err.getTargetObjectId(), err.getMessage());
                                                    }
                                                }
                                            }
                                              //loop through all SingleEmailMessage recs that were valid to send email and capture status for each whatId
                                              for(Messaging.SingleEmailMessage msgRec : singleEmailMsgList) {
                                                  //if emailResultList contains error for the specified target(contact), update bla(whatid) with error
                                                  if(targetIdErrorMap.containsKey(whatIdTargetMap.get(msgRec.whatId))) {
                                                      blaErrMap.put(msgRec.whatId, targetIdErrorMap.get(whatIdTargetMap.get(msgRec.whatId)));
                                                  }
                                                  else {
                                                      //if targetIdErrorMap does not contain what id, then its successful
                                                      String sentDetails = BCMOH_Constants.emailSentToId+' '+accContactMap.get(msgRec.whatId).Contact.Email+
                                                          '. '+BCMOH_Constants.emailSentTo+' '+accContactMap.get(msgRec.whatId).Contact.Name+'. '+BCMOH_Constants.sentTime+' '+datetime.now().format();//add to const
                                                      blaSuccessMap.put(msgRec.whatId, sentDetails);
                                                  }
                                              }
                                          }
                                          catch(exception ex) {
                                              system.debug('caught in meth - '+ex.getMessage());
                                              LogService.logAndPublish(className, 'updateTargetRecsStatus', '', ex);
                                          }
                                      }
    
    //update all bla records - DML
    public static void updateBlaStatus() {
        try {
            //loop through bla error map
            for(Id blaId : blaErrMap.keySet()) {
                //truncate the err message if length more than 255 chars
                String errMsg = blaErrMap.get(blaId).length() > 255 ? blaErrMap.get(blaId).Substring(0,255) : blaErrMap.get(blaId);
                BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
                    Id = blaId,
                    Status = BCMOH_Constants.errorBlaStatus,
                    RenewalError__c = errMsg);
                blaUpdateList.add(blaRec);
            }
            //loop through bla success map
            for(Id blaId : blaSuccessMap.keySet()) {
                BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
                    Id = blaId,
                    Status = BCMOH_Constants.sentBlaStatus,
                    RenewalError__c = blaSuccessMap.get(blaId));
                blaUpdateList.add(blaRec);
            }
            if(!blaUpdateList.isEmpty() && BusinessLicenseApplication.sObjectType.getDescribe().isUpdateable()) {
                Database.Update(blaUpdateList, false);//add error logs for failed records               
            }
        }
        catch(exception ex) {
            system.debug('caught in updateBlaStatus - '+ex.getMessage());
            LogService.logAndPublish(className, 'updateBlaStatus', '', ex);
        }
    }
    //method to get AccountId-ALR-1000
    public Static Id getAccountId(Id blaId) {
        return [SELECT AccountId FROM BusinessLicenseApplication WHERE Id = :blaId][0].AccountId;
    }
    
    //Method to update Account Status-ALR-1000
    public Static List<Account> updateAccountStatus(Id accId) {
        return [SELECT Status__c FROM Account WHERE Id = :accId];
    }
    
    
    //update all latefee bla records - DML-ALR-1000
    public static void updateLateFeeBlaStatus() {
        //List<BusinessLicenseApplication> statusBla = new List<BusinessLicenseApplication>();
        List<Account> accToUpdate = new List<Account>();
        try {
            BusinessLicenseApplication BLAquery = [SELECT Id, RenewalError__c FROM BusinessLicenseApplication WHERE Id =:blaErrMap.keySet() LIMIT 1];
               
            //loop through bla error map
            for(Id blaId : blaErrMap.keySet()) {
                //truncate the err message if length more than 255 chars
                String errMsg = blaErrMap.get(blaId).length() > 255 ? blaErrMap.get(blaId).Substring(0,255) : blaErrMap.get(blaId);
                String lateFeeMsg = blaErrMap.get(blaId);
                lateFeeMsg = BLAquery.RenewalError__c != NULL ? BLAquery.RenewalError__c + ' ; ' + errMsg : errMsg;
                BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
                    Id = blaId,
                    Late_Fee_Status__c = BCMOH_Constants.errorBlaStatus,
                    RenewalError__c = lateFeeMsg);
                blaUpdateList.add(blaRec);
            }
            //loop through bla success map
            
            for (Id blaId : blaSuccessMap.keySet()) {
                Id statusBla = getAccountId(blaId);
                accToUpdate=updateAccountStatus(statusBla);
                accToUpdate[0].Status__c=BCMOH_Constants.AccStatus;
                BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
                    Id = blaId,
                    Late_Fee_Status__c = BCMOH_Constants.sentBlaStatus,
                    RenewalError__c = blaSuccessMap.get(blaId)
                );
                blaUpdateList.add(blaRec);
            }
            
            if(!blaUpdateList.isEmpty() && BusinessLicenseApplication.sObjectType.getDescribe().isUpdateable()) {
                Database.Update(blaUpdateList, false);//add error logs for failed records 
                Database.Update(accToUpdate, false);
            }
            
            
        }
        catch(exception ex) {
            system.debug('caught in updateLateFeeBlaStatus - '+ex.getMessage());
            LogService.logAndPublish(className, 'updateLateFeeBlaStatus', '', ex);
        }
    }
}