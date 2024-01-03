/**
* @Name              : MassEmailController
* @Description       : Controller class to send mass email
                       referenced in ....
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
public with sharing class MassEmailController {
    //Set<Id> selectedBlaIds = new Set<Id>{'0f0As000000065RIAQ'};//may get from list view/lightning comp
    Public Static Boolean sendEmailValid = true;//reqd params for sending email
    Public Static Id templateId = NULL;
    Public Static String templateEntity = '';
    Public Static Map<Id, Id> targetWhatIdMap = new Map<Id, Id>();
    Public Static Map<Id, Id> whatIdTargetMap = new Map<Id, Id>();
    Public Static String emailBody = '';
    Public Static String subjectValue = '';
    Public Static String emailBodyConst = '';
    Public Static String subjectValueConst = '';
        
    Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
    Public Static Map<Id, AccountContactRelation> accContactMap = new Map<Id, AccountContactRelation>();
    Public Static Map<Id, Account> accMap = new Map<Id, Account>();
    Public Static Map<Id, BusinessLicense> blMap = new Map<Id, BusinessLicense>();
    Public Static Id orgWideAddrId = NULL;
    Public Static String templateDevName = '';
    Public Static Map<Id, String> templateDetailsMap = new Map<Id, String>();
    Public Static String templateDetailName = '';
    Public Static Id templateDetailsId = NULL;
    
    Public Static Set<Id> blaIds = new Set<Id>();
    Public Static Map<Id, Id> contactBlaMap = new Map<Id, Id>();
    Public Static Map<Id, Id> blaContactMap = new Map<Id, Id>();
    Public Static Map<Id, Integer> blaTotalAlUnitsMap = new Map<Id, Integer>();
    
    Public Static String errMessage = '';
    
    //method to to send email to records
    @AuraEnabled
    public static void doSendRenewals() {
        Boolean isValidAcc;
        Map<String, List<String>> accDetails = new Map<String, List<String>>();
        Map<Id, String> templateIdEntityMap = new Map<Id, String>();
        Id orgWideAddrId = NULL;
        Map<Id, String> blaErrMap = new Map<Id, String>();
        Map<Id, Set<Id>> contactContentVerMap = new Map<Id, Set<Id>>();
        Set<Id> accIdSetTemp = new Set<Id>{'001As00000IGcv0IAD'};//temp delete bla
        //Set<Id> accIdSetTemp = new Set<Id>{'001As00000IMmIEIA1'};//temp delete xyz 
        try {
            //fetch acc status and rec type from metadata
            accDetails = BCMOH_UtilityClass.getAccRenewals(BCMOH_Constants.renewalName);
            //fetch account, bla details
            //need to make query dynamic
            for(Account activeAccRec : [SELECT Id, Status__c, Name, 
                                        (SELECT Id, ContactId, Contact.Email, PrimaryContact__c
                                         FROM AccountContactRelations 
                                         WHERE PrimaryContact__c = TRUE AND IsActive = TRUE AND Contact.Email != NULL LIMIT 1),
                                        (SELECT Id, Account.Name, RenewalYear__c, CreatedDate 
                                         FROM BusinessLicenseApplicationAccount 
                                         WHERE RecordType.DeveloperName =: BCMOH_Constants.blaRecType AND 
                                         Status =: BCMOH_Constants.blaCreatedStatus 
                                         AND RenewalYear__c =: BCMOH_Constants.renewalYear LIMIT 1),
                                        (SELECT Id, RegistrationCertificate__c, Identifier 
                                         FROM BusinessLicenses LIMIT 1),
                                        (SELECT Id, Capacity__c, Quantity, Type__c 
                                         FROM Assets
										 WHERE RecordType.DeveloperName =: BCMOH_Constants.parentAssetRecType
										 AND Type__c IN: BCMOH_Constants.allALUnitTypes)
                                        FROM Account 
                                        WHERE RecordType.DeveloperName =: accDetails.keyset() AND 
                                        Status__c IN: accDetails.values()[0] 
                                        //AND Id IN: accIdSetTemp
                                       ]) {
                                            system.debug('yui activeAccRec Id '+activeAccRec.Id);
                                            String errMsg = '';//set no err msg initially
                                            isValidAcc = true;//setting account as valid initially
                                            //?use switch?
                                            
                                            //when valid renewal bla record is not available
                                            if(activeAccRec.BusinessLicenseApplicationAccount.size() == 0) {
                                                system.debug('yui bla null '+activeAccRec.Id);
                                                errMsg = 'No Renewal BLAs for this Account';
                                                system.debug(errMsg);//?no error handling for this right as no BLA?
                                                isValidAcc = false;
                                                continue;//skips following code and fetches next account in loop
                                            }
                                          
                                            //when primary contact(email's targetObjectId)/its email is not available
                                            if(activeAccRec.AccountContactRelations.size() == 0) {
                                                system.debug('yui contact null '+activeAccRec.Id);
                                                errMsg = BCMOH_Constants.noPrimaryContact;
                                                system.debug(errMsg);//add in error handling
                                                isValidAcc = false;
                                                blaErrMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, errMsg);
                                                continue;//skips following code and fetches next account in loop
                                            }
                                            //fetch business license record 
                                            if(activeAccRec.BusinessLicenses.size() == 0) {
                                                errMsg = 'No BL for this Account';
                                                system.debug(errMsg);//add err handling
                                            }
                                           	else if(isValidAcc) {                            
                                                //bl map - loop through bl records and get latest bl record
                                               //blMap.put(activeAccRec.AccountContactRelations[0].ContactId, activeAccRec.BusinessLicenses[0]);
                                               blMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec.BusinessLicenses[0]);
                                            }
                                           
                                            //if account is valid then fetch the bla Ids associated with the account to fetch its files attached
                                            if(isValidAcc) {
                                                system.debug('yui valid acc '+activeAccRec.Id);
                                                //acc Map
                                            	accMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, activeAccRec);//not used anywhere yet
                                                system.debug('yui acc map in loop '+accMap);
                                                //bla maps
                                                blaContactMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id,
                                                                  activeAccRec.AccountContactRelations[0].ContactId);//blaId, contactId map for email targetIds
                                                contactBlaMap.put(activeAccRec.AccountContactRelations[0].ContactId, 
                                                                 activeAccRec.BusinessLicenseApplicationAccount[0].Id);//contactId blaId map for email targetIds
                                                system.debug('yui contactblamap acc '+contactBlaMap);
                                                //acc contact map
                                               /* accContactMap.put(activeAccRec.AccountContactRelations[0].ContactId, 
                                                                 activeAccRec.AccountContactRelations[0]);*/
                                                //acc contact map with bla id
                                                accContactMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, 
                                                                 activeAccRec.AccountContactRelations[0]);
                                            	//?if bla Id is comng from front end then this for loop is not needed?
                                            	if(activeAccRec.Assets.size() != 0) {
                                                	Integer unitCounter = 0;
                                                	for(Asset parentAsset : activeAccRec.Assets) {
                                                    	unitCounter = unitCounter + Integer.valueOf(parentAsset.Quantity);
                                               		}
                                               		blaTotalAlUnitsMap.put(activeAccRec.BusinessLicenseApplicationAccount[0].Id, unitCounter);
                                           		}
                                                for(BusinessLicenseApplication blaRec : 
                                                    activeAccRec.BusinessLicenseApplicationAccount) {
                                                    blaIds.add(blaRec.Id);//these are the linked entity Ids
                                                    //bla map
                                                	blaMap.put(blaRec.Id, blaRec);
                                             	}                     
                                            }
            }
            system.debug('yui blaContactMap after for '+blaContactMap);
            system.debug('yui acc map after for loop '+accMap.size()+' '+accMap);
            system.debug('yui blaIds after for '+blaIds);
            system.debug('yui blMap after for '+blMap);
            //if valid contacts are fetched
            //? if template id is not fetched then all bla record's error message needs to be updated ?
            if(!blaContactMap.isEmpty()) {
                //fetch template Id
                templateIdEntityMap = fetchTemplateDetails(BCMOH_Constants.templatePurpose);//email template
                system.debug('yui after calling fetch templ details '+templateEntity+' '+templateId);
                //fetch org wide address id
                orgWideAddrId = getOrgWideId();//email from address
                system.debug('yui if main values inside '+orgWideAddrId+' '+templateIdEntityMap);
                //fetch files associated to BLA record
                contactContentVerMap = fetchAttachmentDetails(blaContactMap, blaIds);//email attachments
                system.debug('yui contactContentVerMap inside MAIN if '+contactContentVerMap);
                //fetch whatId for the email - may be not required check
               /* if(templateEntity == 'BusinessLicenseApplication') {
                    targetWhatIdMap = contactBlaMap;                    
                    system.debug('yui inside bla template entity'+targetWhatIdMap+' '+contactBlaMap);
                } */
                targetWhatIdMap = contactBlaMap;
                whatIdTargetMap = blaContactMap;
                
                //send email with the target-content map and target-whatid map
                if(!templateIdEntityMap.isEmpty() && orgWideAddrId != NULL) {// && !contactContentVerMap.isEmpty()) {
                	//sendEmailForRenewals(contactContentVerMap, targetWhatIdMap);
                	sendEmailForRenewals(contactContentVerMap, whatIdTargetMap);
                }
            }
        }
        catch(exception ex) {
            system.debug('yui im caught'+ex.getMessage());
        }
    }
    
    //send email method
    public static void sendEmailForRenewals(Map<Id, Set<Id>> contactContentVerMap, Map<Id, Id> whatIdTargetMap) {
        List<Id> targetIds = new List<Id>();
        List<Id> attachIds = new List<Id>();
        Id contactId = NULL;
        BusinessLicense blRec = new BusinessLicense();
        Integer totalALUnits = 0;
        List<Messaging.SingleEmailMessage> singleEmailMsgList = new List<Messaging.SingleEmailMessage>();
        try {
            for(Id whatId : whatIdTargetMap.KeySet()) {
                system.debug('yui inside sendEmailForRenewals whatIdTargetMap '+whatIdTargetMap);
                contactId = whatIdTargetMap.isEmpty() ? NULL : whatIdTargetMap.get(whatId);
                system.debug('yui inside sendEmailForRenewals whatid  '+whatId);
                attachIds = new List<Id>(contactContentVerMap.get(contactId));//change this to bla map later
                if(!accContactMap.isEmpty() && !blaMap.isEmpty() && !accMap.isEmpty() &&
                   accContactMap.get(whatId) != NULL && blaMap.get(whatId) != NULL && accMap.get(whatId) != NULL) {
                       blRec = !blMap.isEmpty() && blMap.get(whatId) != NULL ? blMap.get(whatId) : NULL;//get BL record
                       totalALUnits = !blaTotalAlUnitsMap.isEmpty() && blaTotalAlUnitsMap.get(whatId) != NULL ?
                           			 blaTotalAlUnitsMap.get(whatId) : 0;//get Total AL Units value
                       emailBody = replaceMergeFields(emailBodyConst, accContactMap.get(whatId), blaMap.get(whatId), 
                                               accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       subjectValue = replaceMergeFields(subjectValueConst, accContactMap.get(whatId), blaMap.get(whatId),
                                                  accMap.get(whatId), blRec, String.valueOf(totalALUnits));
                       Messaging.SingleEmailMessage emailMsgRec = BCMOH_UtilityClass.setEmailParams(contactId, NULL, orgWideAddrId, attachIds, whatId, emailBody, subjectValue);
                	   singleEmailMsgList.add(emailMsgRec);
                       system.debug('yui emailmsg rec data set '+emailMsgRec);
                }
                else {
                    errMessage = 'data required for template is missing';
                }
            }
            system.debug('yui singleEmailMsgList before sending email '+singleEmailMsgList.size()+' '+singleEmailMsgList);
            //put this in another method - sending the email and receiving its response.
            //Messaging.reserveSingleEmailCapacity(singleEmailMsgList.size());
            if(singleEmailMsgList != NULL && singleEmailMsgList.size() > 0) {
                Messaging.SendEmailResult[] emailResultList = Messaging.SendEmail(singleEmailMsgList, false);//send email inspite of failure
                system.debug('yui email result '+emailResultList);
                updateTargetRecsStatus(emailResultList, singleEmailMsgList, whatIdTargetMap);
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling sendEmailForRenewals'+ex.getMessage());
        }
    }
    
    //method to replace few merge fields in email template //need to make it re-usable
    public static String replaceMergeFields(String templateData, AccountContactRelation accContactRec, 
                                            BusinessLicenseApplication blaRec, Account accRec, 
                                            BusinessLicense blRec, String totalALUnits) {
        String mergeFieldValue = '';
        try {
            //system.debug('gggg '+templateData);
            system.debug('tmp data yyy'+accContactRec+' '+blaRec+' '+accRec+' '+blRec);
            for(TemplateMergeFieldMapping__mdt  templateMapping : TemplateMergeFieldMapping__mdt.getAll().values()) {
                //?handle null checks?
                if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.ObjectName__c == 'AccountContactRelation') {
                    //Schema.SObjectField field = accContactRec.get(templateMapping.FieldAPIName__c);
                    templateData = templateData.replace(templateMapping.MergeField__c, accContactRec.get(templateMapping.FieldAPIName__c).toString());
                }
                else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.ObjectName__c == 'Account') {
                    mergeFieldValue = accRec.get(templateMapping.FieldAPIName__c) != NULL ? accRec.get(templateMapping.FieldAPIName__c).toString() : NULL;
                    if(mergeFieldValue != NULL || mergeFieldValue != '') {
                    	templateData = templateData.replace(templateMapping.MergeField__c, accRec.get(templateMapping.FieldAPIName__c).toString());
                    }
                }
                else if(templateMapping.EmailTemplate__c == templateDetailsId &&  templateMapping.ObjectName__c == 'BusinessLicenseApplication') {
                    if(templateMapping.FieldAPIName__c == 'CreatedDate') {
                        templateData = templateData.replace(templateMapping.MergeField__c,
                                                            Date.valueOf(blaRec.get(templateMapping.FieldAPIName__c)).format());
                    }
                    else {
                        templateData = templateData.replace(templateMapping.MergeField__c, blaRec.get(templateMapping.FieldAPIName__c).toString());
                    }
                }
                else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.ObjectName__c == 'BusinessLicense' && blRec != NULL) {
                    if(blRec.get(templateMapping.FieldAPIName__c) != NULL) {
                        mergeFieldValue = blRec != NULL && blRec.get(templateMapping.FieldAPIName__c) != NULL ? blRec.get(templateMapping.FieldAPIName__c).toString() : NULL;
                        if(mergeFieldValue != NULL && mergeFieldValue != '') {
                        	templateData = templateData.replace(templateMapping.MergeField__c, blRec.get(templateMapping.FieldAPIName__c).toString());
                    	}
                    }
                }
                else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.MergeFieldFormula__c == 'nextYear') {
                    templateData = templateData.replace(templateMapping.MergeField__c, BCMOH_Constants.nextYear);
                }
                else if(templateMapping.EmailTemplate__c == templateDetailsId && templateMapping.MergeFieldFormula__c == 'totalALUnits') {
                    templateData = templateData.replace(templateMapping.MergeField__c, totalALUnits);
                }
            }
            //system.debug('cds'+templateData);
        }
        catch(Exception ex) {
            system.debug('use exception handling replaceMergeFields '+ex.getMessage());
        }
        return templateData;
    }
    
    //fetch templateId needed to send the email
    public static Map<Id, String> fetchTemplateDetails(String purpose) {
        Map<Id, String> templateDetails = new Map<Id, String>();
        //String relatedEntityType = '';
        EmailTemplate emailTempRec = new EmailTemplate();
        String errMessage = '';
        try {
            //fetch email template name from metadata
            templateDetailsMap = BCMOH_UtilityClass.getEmailtemplateName(purpose);
            templateDetailName = templateDetailsMap.values()[0];
            templateDetailsId = new List<Id>(templateDetailsMap.keyset())[0];
            if(!templateDetailsMap.isEmpty()) {
                //fetch template details from email template
                emailTempRec = BCMOH_UtilityClass.getEmailTemplate(templateDetailName);
                if(emailTempRec != NULL) {
                    system.debug('yui fetched email template '+emailTempRec.Id);
                    templateDetails.put(emailTempRec.Id, emailTempRec.RelatedEntityType);
                    templateEntity = emailTempRec.RelatedEntityType;
                    templateId = emailTempRec.Id;
                    subjectValue = emailTempRec.Subject;
                    subjectValueConst = emailTempRec.Subject;
                    emailBody = emailTempRec.Body;//BCMOH_UtilityClass.replaceMergeFields(emailTempRec.Body, );not needed
                    emailBodyConst = emailTempRec.Body;
                    system.debug('yui fetched email templateEntity  '+templateEntity+' '+templateId);//+' '+emailBody);
                }
                else {
                    //set error when email template was not fetched
                	errMessage = templateId == NULL ? 'No email template found for specified template developer name: '+templateDetailName : '';
                	system.debug(errMessage);//add in error handling
                    sendEmailValid = false;
                }
            }
            else {
                //set error when valid email template config is not available
                errMessage = 'No active email template name configured for '+purpose+' purpose';
                system.debug(errMessage);//add in error handling
                sendEmailValid = false;
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling fetchTemplateId'+ex.getMessage());
        }
        return templateDetails;
    }
    
    //get org wide email address based on custom setting
    public static Id getOrgWideId() {
        String errMessage = '';
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
        }
        return orgWideAddrId;
    }
    
    //fetch contactId vs ContentVersions Map needed to add attachments to the email
    public static Map<Id, Set<Id>> fetchAttachmentDetails(Map<Id, Id> blaContactMap, Set<Id> blaIds) {
        Map<Id, Set<Id>> contactContentVerMap = new Map<Id, Set<Id>>();
        String errMessage = '';
        try {
            //fetch wrapper details with content version and blaIds
            BCMOH_UtilityClass.ContentDocWrapper ContentDocWrapperRec = BCMOH_UtilityClass.getContentDocMap(blaIds);
            system.debug('yui fetchAttachmentDetailsmeth wrappper resp '+ContentDocWrapperRec);
            //fetch content versions per contact record
            if(ContentDocWrapperRec != NULL) {
                Set<Id> contentVerIdSet = new Set<Id>();
                for(Id blaId : ContentDocWrapperRec.entityContentIdsMap.KeySet()) {//for each bla rec Id
                    for(Id docId : ContentDocWrapperRec.entityContentIdsMap.get(blaId)) {//for each of its content document id
                        if(contactContentVerMap.containsKey(blaContactMap.get(blaId))) {//if map contains the contact id
                            contentVerIdSet = contactContentVerMap.get(blaContactMap.get(blaId));//fetch its content versions
                        }
                        //? null check needed ?
                        contentVerIdSet.add(ContentDocWrapperRec.contentDocVerMap.get(docId));//add current version also to the list
                        //map's key value pair holds the target id vs attachment ids per email
                        contactContentVerMap.put(blaContactMap.get(blaId), contentVerIdSet);//again set the map
                    }
                }
            }
        }
        catch(Exception ex) {
            system.debug('use exception handling fetchAttachmentDetails '+ex.getMessage());
        }
        return contactContentVerMap;
    }
    //update bla status
     public static void updateTargetRecsStatus(Messaging.SendEmailResult[] emailResultList, 
                                               List<Messaging.SingleEmailMessage> singleEmailMsgList, Map<Id, Id> whatIdTargetMap) {
         Map<Id, String> targetIdErrorMap = new Map<Id, String>();
         try {
             for(Messaging.SendEmailResult eResRec : emailResultList) {
                 if(eResRec.isSuccess()) {
                     //Do something for success
                 }  
                 else {
                     // Operation failed, so get all errors                
                     for(Messaging.SendEmailError err : eResRec.getErrors()) {
                         System.debug('^^ The stat code   err msg. '+err.getStatusCode() + ': ' + err.getMessage()); 
                         System.debug('^^ fields that affected this error: ' + err.getFields());
                         System.debug('^^ target id that affected this error: ' + err.getTargetObjectId());
                         //Map<Id, String> blaErrorMap = new Map<Id, String>();
                         targetIdErrorMap.put(err.getTargetObjectId(), err.getMessage());
                     }
                 }
             }
             //update bla records
             for(BusinessLicenseApplication blaRec : blaMap.values()) {
                 if(targetIdErrorMap.keyset().contains(whatIdTargetMap.get(blaRec.Id))) {//if error map contains this bla id
                     blaRec.Status = 'Errored';
                     String errMsg = targetIdErrorMap.get(whatIdTargetMap.get(blaRec.Id)).length() > 255 ?
                         				targetIdErrorMap.get(whatIdTargetMap.get(blaRec.Id)).Substring(0,255) :
                     					targetIdErrorMap.get(whatIdTargetMap.get(blaRec.Id));
                     blaRec.RenewalError__c = errMsg;
                 }
                 else {
                     blaRec.Status = 'Sent';
                 }
             }
             if(!blaMap.isEmpty()) {//check permissions
                 Database.Update(blaMap.values());                 
             }
         }
         catch(exception ex) {
             system.debug('caught in meth - '+ex.getMessage());
         }
     }
}