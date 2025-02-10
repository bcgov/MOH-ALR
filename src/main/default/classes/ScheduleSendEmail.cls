/**
* @Name              : ScheduleSendEmail
* @Description       : Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-562
* @Updated by        : Liliane Nassar (CGi) -BCMOHAM-22405
**/

public with sharing class ScheduleSendEmail implements Schedulable {
    
     public void execute(SchedulableContext sc) {
          List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
   
        try {
            EmailTemplate emailTemplate = getEmailTemplate('Upcoming_Renewal_Email_Template');
            
            OrgWideEmailAddress orgWideAddr = [
                SELECT Id, DisplayName, Address
                FROM OrgWideEmailAddress
                WHERE DisplayName = 'ALR Support Email'
            ];
            
              // Fetch all relevant accounts in one query
              List<Account> accountList = [SELECT Id, Name, ParentId FROM Account
                WHERE Status__c IN ('Registered Active', 'Registered Active with Conditions', 'Registered Active Progressive Enforcement')];
              
             Map<Id, Account> accountMap = new Map<Id, Account>();
                // Extract Account Ids for bulk querying contacts
                Set<Id> accountIds = new Set<Id>();
                for (Account acc : accountList) {
                    accountIds.add(acc.Id);
                    if (!accountMap.containsKey(acc.Id)) {    
                        accountMap.put(acc.Id, acc);
                    }
                    if (acc.ParentId != null) {
                        accountIds.add(acc.ParentId);
                        if (!accountMap.containsKey(acc.ParentId)) {    
                            accountMap.put(acc.ParentId, acc);
                        }
                   }
                }

                // Fetch all related contacts in one query
                Map<Id, List<AccountContactRelation>> accountContactMap = new Map<Id, List<AccountContactRelation>>();
                for (AccountContactRelation acr : [
                    SELECT Id, ContactId, AccountId, IsActive, Contact.Email 
                    FROM AccountContactRelation 
                    WHERE AccountId IN :accountIds AND IsActive = true AND Contact.Email != NULL
                ]) {
                    if (!accountContactMap.containsKey(acr.AccountId)) {  
                       accountContactMap.put(acr.AccountId, new List<AccountContactRelation>());
                    } 
                    accountContactMap.get(acr.AccountId).add(acr);
                   }
                   
                // Process each account
                Integer currentyear = Date.today().year();
                Integer previousyear = Date.today().year() - 1;
                Map<String, Boolean> processedEmails = new Map<String, Boolean>();

                for (Id acc : accountIds) {
                    List<AccountContactRelation> contacts = accountContactMap.get(acc);
                    if (contacts != null) {
                        for (AccountContactRelation acr : contacts) {
                            if (acr.Contact.Email != null) {
                            String emailKey = acc + '_' + acr.Contact.Email.toLowerCase();  
                                if (!processedEmails.containsKey(emailKey)) {
                                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                    email.setTemplateId(emailTemplate.Id);
                                    email.setOrgWideEmailAddressId(orgWideAddr.Id);
                                    email.setToAddresses(new String[]{acr.Contact.Email});
                                    email.setTargetObjectId(acr.Contact.Id);
                                    
                                    String emailBody = emailTemplate.HtmlValue;
                                    String emailSubject = emailTemplate.Subject;
                                    emailBody = emailBody.replace('{%%Account.Name%%}', accountMap.get(acc).Name);
                                    
                                    emailBody = emailBody.replace('{%%CurrentYear%%}', String.valueOf(currentYear));
                                    emailBody = emailBody.replace('{%%PreviousYear%%}', String.valueOf(previousYear));
                                    emailSubject = emailSubject.replace('{%%CurrentYear%%}', String.valueOf(currentYear));
                                    emailSubject = emailSubject.replace('{%%PreviousYear%%}', String.valueOf(previousYear));

                                    email.setSubject(emailSubject);
                                    email.setHtmlBody(emailBody);
                                    emails.add(email);
   
                                    processedEmails.put(emailKey, true); // Mark as processed
                                }
                            }
                        }
                    }
                }

                if (!emails.isEmpty()) {
                     sendEmailBatch(emails);
                }
            } catch (Exception e) {
                System.debug('Exception occurred in execute method: ' + e.getMessage());
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