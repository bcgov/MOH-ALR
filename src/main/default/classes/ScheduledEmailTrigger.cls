/**
* @Name              : ScheduledEmailTrigger
* @Description       : Class for Sending Email on  March-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-192
**/

public with sharing class ScheduledEmailTrigger implements Schedulable {
    public Static Id emailTemplateId =NULL;
    public static Set<Id> accountIds = new Set<Id>();

    public void execute(SchedulableContext sc) {
        try {
            Map<Id, Set<Id>> accountIdToContactIdsMap = new Map<Id, Set<Id>>();
            List<Id> blaId = new List<Id>();
            List<RegulatoryTrxnFee> fees = [
                SELECT Id, AccountId, Account.ParentId, ParentRecordId 
                FROM RegulatoryTrxnFee
                WHERE FeeType__c = 'Renewal Unit Fee'
                    AND Status = 'Due'
            ];

            for (RegulatoryTrxnFee fee : fees) {
                accountIds.add(fee.AccountId);
                accountIds.add(fee.Account.ParentId);
                accountIdToContactIdsMap.put(fee.AccountId, new Set<Id>());
                accountIdToContactIdsMap.put(fee.Account.ParentId, new Set<Id>());
                blaId.add(fee.ParentRecordId);
            }

            Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>([
                SELECT Id, ParentId,
                    (SELECT Id, ContactId, Contact.Name, Contact.Email
                     FROM AccountContactRelations
                     WHERE IsActive = true AND Contact.Email != null)
                FROM Account
                WHERE Id IN :accountIds
            ]);

            for (Account account : [
                SELECT ParentId,
                    (SELECT Id, ContactId, Contact.Name, Contact.Email
                     FROM AccountContactRelations
                     WHERE IsActive = true AND Contact.Email != null)
                FROM Account
                WHERE Id IN :accountIds
            ]) {
                accountIdToAccountMap.put(account.Id, account);
            }

            for (Account acc : accountIdToAccountMap.values()) {
                for (AccountContactRelation acr : acc.AccountContactRelations) {
                    accountIdToContactIdsMap.get(acc.Id).add(acr.ContactId);
                }
            }

            List<Id> contactIdsList = new List<Id>();
            for (Set<Id> contactIds : accountIdToContactIdsMap.values()) {
                contactIdsList.addAll(contactIds);
            }
            if (!contactIdsList.isEmpty()) {
                sendRenewalDueEmail(contactIdsList, blaId);
            }
        } catch (Exception e) {
            System.debug('Exception occurred in execute method: ' + e.getMessage());
        }
    }

    public static void sendRenewalDueEmail(List<Id> contactIds, List<Id> blaId) {
        List<Id> accListforKeepingIds = new List<Id>();
    try {
        EmailTemplate emailTemplate = getEmailTemplate('Renewal_Reminder_Email');
        OrgWideEmailAddress orgWideAddr = [
            SELECT Id, DisplayName, Address
            FROM OrgWideEmailAddress
            WHERE DisplayName = 'ALR Support Email'
        ];
 		
         List<AccountContactRelation> AccountcontactRecList = [SELECT Id, AccountId, Account.Name, ContactId, Contact.Email, Contact.IsEmailBounced FROM AccountContactRelation WHERE ContactId IN :contactIds];
        
        for(AccountContactRelation AccountconList : AccountcontactRecList){
            accListforKeepingIds.add(AccountconList.ContactId);
        }
       
        List<BusinessLicenseApplication> blaList = [SELECT Id, RenewalYear__c FROM BusinessLicenseApplication WHERE Id IN :blaId];
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Map<String, List<String>> processedEmails = new Map<String, List<String>>();
 
        for (BusinessLicenseApplication blaRec : blaList) {
            for (AccountContactRelation acrList : AccountcontactRecList) {
                if (acrList.contact.Email != null) {
                    String key = acrList.AccountId + '_' + acrList.contact.Email.toLowerCase();
                    if (!processedEmails.containsKey(key)) {
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setTemplateId(emailTemplate.Id);
                        email.setOrgWideEmailAddressId(orgWideAddr.Id);
                        email.setToAddresses(new String[]{acrList.contact.Email});
                        email.setTargetObjectId(acrList.contact.Id);
                        EmailTemplate emailTemplates = replaceMergeFields(emailTemplate, blaRec, acrList.Account.Name);
                        //String emailSubject = emailTemplate.Subject;
                        email.setSubject(emailTemplates.Subject);
                        email.setHtmlBody(emailTemplates.HtmlValue);
                        emails.add(email);
                        processedEmails.put(key, new List<String>{acrList.contact.Email});
                    }
                }
            }
            
        }
        
 
        if (!emails.isEmpty()) {
            sendEmailBatch(emails);
        }
    } catch (Exception e) {
        System.debug('Exception occurred in sendRenewalDueEmail method: ' + e.getMessage());
    }
}

    public static void sendEmailBatch(List<Messaging.SingleEmailMessage> emailBatch) {
        List<Messaging.SingleEmailMessage> singleEmailList = new List<Messaging.SingleEmailMessage>();
        try{
            for (Messaging.SingleEmailMessage email : emailBatch) {
                singleEmailList.add(email);
        }  
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(singleEmailList, false);

        }catch (Exception e) {
                System.debug('Exception occurred while sending email to ' + e.getMessage());
                System.debug('Exception occurred while sending email to ' + e.getLineNumber());
            }
        }
    
    
    public static EmailTemplate replaceMergeFields(EmailTemplate emailTemplate, BusinessLicenseApplication blaRec, String name) {
        String mergeFieldValue = '';
        //Id emailTemplateId =NULL;
        try {
            for (TemplateMergeFieldMapping__mdt templateMapping : TemplateMergeFieldMapping__mdt.getAll().values()) {
                if ( templateMapping.EmailTemplate__c == emailTemplateId && templateMapping.ObjectName__c == 'Account') {
                    emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace(templateMapping.MergeField__c, name);
                    emailTemplate.Subject = emailTemplate.Subject.replace(templateMapping.MergeField__c, name);
                      } else if (templateMapping.EmailTemplate__c == emailTemplate.Id && templateMapping.ObjectName__c == 'BusinessLicenseApplication') {

                    if (templateMapping.FieldAPIName__c == 'RenewalYear__c') {
                        emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace(templateMapping.MergeField__c,
                            Date.valueOf(blaRec.get(templateMapping.FieldAPIName__c)).format());
                        emailTemplate.Subject = emailTemplate.Subject.replace(templateMapping.MergeField__c,
                            Date.valueOf(blaRec.get(templateMapping.FieldAPIName__c)).format());
                          } else {
                        emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace(templateMapping.MergeField__c,
                            blaRec.get(templateMapping.FieldAPIName__c).toString());
                        emailTemplate.Subject = emailTemplate.Subject.replace(templateMapping.MergeField__c,
                            blaRec.get(templateMapping.FieldAPIName__c).toString());
                         }
                } else if (templateMapping.EmailTemplate__c == emailTemplate.Id && templateMapping.MergeFieldFormula__c == 'nextYear') {
                    emailTemplate.HtmlValue = emailTemplate.HtmlValue.replace(templateMapping.MergeField__c, BCMOH_Constants.nextYear);
                    emailTemplate.Subject = emailTemplate.Subject.replace(templateMapping.MergeField__c, BCMOH_Constants.nextYear);
                     }
            }
        } catch (Exception err) {
            System.debug('Exception occurred in replaceMergeFields method: ' + err.getMessage());
        }
        return emailTemplate;
    }
    
     
    public static EmailTemplate getEmailTemplate(String templateDevName) {
        EmailTemplate emailTemplateRec = null;
        try {
            emailTemplateRec = [
                SELECT Id, DeveloperName, Subject, HtmlValue, Body
                FROM EmailTemplate
                WHERE DeveloperName = :templateDevName
                LIMIT 1
            ];
        } catch (Exception ex) {
            System.debug('Exception occurred in getEmailTemplate method: ' + ex.getMessage());
        }
        return emailTemplateRec;
    }
}