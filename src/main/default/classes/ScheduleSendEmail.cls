/**
* @Name              : ScheduleSendEmail
* @Description       : Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-562
**/

public with sharing class ScheduleSendEmail implements Schedulable {
    
    public static Set<Id> accountIds = new Set<Id>();
    
    public void execute(SchedulableContext sc) {
           try {
            Map<Id, Set<Id>> accountIdToContactIdsMap = new Map<Id, Set<Id>>();
            
             List<Account> accounts = [
                SELECT Id ,ParentId
                FROM Account
                WHERE Status__c IN ('Registered Active', 'Registered Active with Conditions', 'Registered Active Progressive Enforcement')
            ];

             for (Account acc : accounts) {
                accountIds.add(acc.Id);
                accountIds.add(acc.ParentId);
                accountIdToContactIdsMap.put(acc.Id, new Set<Id>());
                accountIdToContactIdsMap.put(acc.ParentId, new Set<Id>());
            }

             Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>([
                SELECT Id,parentId,
                       (SELECT Id, ContactId, Contact.Name, Contact.Email
                        FROM AccountContactRelations
                        WHERE IsActive = true AND Contact.Email != null)
                FROM Account
                WHERE Id IN :accountIds
            ]);

            for (Account account : [
    SELECT  parentId, 
         (SELECT Id, ContactId, Contact.Name, Contact.Email 
          FROM AccountContactRelations 
          WHERE IsActive = true AND Contact.Email!= null)
    FROM Account 
    WHERE Id IN : accountIds
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
                sendRenewalDueEmail(contactIdsList);
            }

        } catch (Exception e) {
            System.debug('Exception occurred in execute method: ' + e.getMessage());
        }
    
  }
    public static void sendRenewalDueEmail(List<Id> contactIds) {
        try {
             EmailTemplate emailTemplate = getEmailTemplate('Upcoming_Renewal_Email_Template');

                 OrgWideEmailAddress orgWideAddr = [
                    SELECT Id, DisplayName, Address
                    FROM OrgWideEmailAddress
                    WHERE DisplayName = 'ALR Support Email'
                ];
                
                List<Contact> contactRec =[Select Id,Email from Contact WHERE Id IN: contactIds];

        Integer batchSize = 100; 
        List<List<Messaging.SingleEmailMessage>> emailBatches = new List<List<Messaging.SingleEmailMessage>>();
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Contact contact : contactRec){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(emailTemplate.Id);
            email.setOrgWideEmailAddressId(orgWideAddr.Id);
            email.setToAddresses(new String[] {contact.Email});
            email.setTargetObjectId(contact.Id);
            String emailSubject = emailTemplate.Subject;
            String emailBody = emailTemplate.HtmlValue;
            email.setSubject(emailSubject);
            email.setHtmlBody(emailBody);
            emails.add(email);
            if (emails.size() == batchSize) {
                emailBatches.add(emails);
                emails = new List<Messaging.SingleEmailMessage>();
            }
        }
        if (!emails.isEmpty()) {
            emailBatches.add(emails);
        }
        for (List<Messaging.SingleEmailMessage> emailBatch : emailBatches) {
            try {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailBatch);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        System.debug('Email sent successfully to ' + emailBatch[i].getToAddresses()[0]);
                    } else {
                       String errorMessage = results[i].getErrors()[0].getMessage();
                        if (errorMessage.contains('EMAIL_ADDRESS_BOUNCED')) {
                            System.debug('Bounced email address: ' + emailBatch[i].getToAddresses()[0]);
                        } else {
                            System.debug('Failed to send email to ' + emailBatch[i].getToAddresses()[0] +
                                 '. Error message: ' + errorMessage);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Exception occurred in sendEmails method: ' + e.getMessage());
            }
        }
    }catch (Exception e) {
            System.debug('Exception occurred in sendRenewalDueEmail method: ' + e.getMessage());
        }
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