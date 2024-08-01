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
        List<Id> accListforKeepingIds = new List<Id>();
        try {
            EmailTemplate emailTemplate = getEmailTemplate('Upcoming_Renewal_Email_Template');
            
            OrgWideEmailAddress orgWideAddr = [
                SELECT Id, DisplayName, Address
                FROM OrgWideEmailAddress
                WHERE DisplayName = 'ALR Support Email'
            ];
            List<AccountContactRelation> AccountcontactRecList = [SELECT Id, AccountId, Account.Name, ContactId, Contact.Email, Contact.IsEmailBounced FROM AccountContactRelation WHERE ContactId IN :contactIds];
            
            for(AccountContactRelation AccountconList : AccountcontactRecList){
                accListforKeepingIds.add(AccountconList.ContactId);
            }
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Map<String, List<String>> processedEmails = new Map<String, List<String>>();
            Integer currentyear = Date.today().year();
            Integer previousyear = Date.today().year() - 1;
            
            for (AccountContactRelation acrList : AccountcontactRecList) {
                if (acrList.contact.Email != null) {
                    String key = acrList.AccountId + '_' + acrList.contact.Email.toLowerCase();
                    if (!processedEmails.containsKey(key)) {
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setTemplateId(emailTemplate.Id);
                        email.setOrgWideEmailAddressId(orgWideAddr.Id);
                        email.setToAddresses(new String[]{acrList.contact.Email});
                        email.setTargetObjectId(acrList.contact.Id);
                        String emailBody = emailTemplate.HtmlValue;
                        String emailSubject = emailTemplate.Subject;
                        emailBody = emailBody.Replace('{%%Account.Name%%}', acrList.Account.Name);
                        emailBody = emailBody.Replace('{%%CurrentYear%%}', String.valueOf(currentyear));
                        emailBody = emailBody.Replace('{%%PreviousYear%%}', String.valueOf(previousyear));
                        emailSubject = emailSubject.Replace('{%%CurrentYear%%}', String.valueOf(currentyear));
                        emailSubject = emailSubject.Replace('{%%PreviousYear%%}', String.valueOf(previousyear));
                        email.setSubject(emailSubject);
                        email.setHtmlBody(emailBody);
                        emails.add(email);
                        processedEmails.put(key, new List<String>{acrList.contact.Email});
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