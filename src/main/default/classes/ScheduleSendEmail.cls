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
                SELECT Id
                FROM Account
                WHERE Status__c IN ('Registered Active', 'Registered Active with Conditions', 'Registered Active Progressive Enforcement')
            ];

             for (Account acc : accounts) {
                accountIds.add(acc.Id);
                accountIdToContactIdsMap.put(acc.Id, new Set<Id>());
            }

             Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>([
                SELECT Id,
                       (SELECT Id, ContactId, Contact.Name, Contact.Email
                        FROM AccountContactRelations
                        WHERE IsActive = true AND Contact.Email != null)
                FROM Account
                WHERE Id IN :accountIds
            ]);

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

            if (emailTemplate != null && emailTemplate.Id != null) {
                OrgWideEmailAddress orgWideAddr = [
                    SELECT Id, DisplayName, Address
                    FROM OrgWideEmailAddress
                    WHERE DisplayName = 'ALR Support Email'
                ];

                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

                for (Id contactId : contactIds) {
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setTemplateId(emailTemplate.Id);
                    email.setOrgWideEmailAddressId(orgWideAddr.Id);
                    email.setTargetObjectId(contactId);
                    String emailSubject = emailTemplate.Subject;
                    String emailBody = emailTemplate.HtmlValue;

                    email.setSubject(emailSubject);
                    email.setHtmlBody(emailBody);
                    emails.add(email);
                }

                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                    System.debug('Sent ' + emails.size() + ' email messages successfully.');
                }
            }
        } catch (Exception e) {
            System.debug('Exception occurred in sendRenewalDueEmail method: ' + e.getMessage());
        }
    }

    // Method to retrieve email template by Developer Name
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