/**
* @Name              : ScheduleSendEmail
* @Description       : Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-562
**/

public with sharing class ScheduleSendEmail implements Schedulable {
    
    Map<Id, AccountContactRelation> contacts = new Map<Id, AccountContactRelation>();
    
     public void execute(SchedulableContext sc) {
          List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
   
        try {
            EmailTemplate emailTemplate = getEmailTemplate('Upcoming_Renewal_Email_Template');
            
            OrgWideEmailAddress orgWideAddr = [
                SELECT Id, DisplayName, Address
                FROM OrgWideEmailAddress
                WHERE DisplayName = 'ALR Support Email'
            ];
            
            for(Account accounts : [SELECT Id ,Name,ParentId FROM Account
                                    WHERE Status__c IN ('Registered Active', 'Registered Active with Conditions', 'Registered Active Progressive Enforcement')
                                   ]){
                                       contacts = getContacts(accounts.Id,accounts.ParentId);
                                       Map<String, List<String>> processedEmails = new Map<String, List<String>>();
                                       Integer currentyear = Date.today().year();
                                       Integer previousyear = Date.today().year() - 1;
                                       
                                       for (AccountContactRelation acrList : contacts.values()) {
                                           if (acrList.contact.Email != null) {
                                               String key = acrList.AccountId + '_' + acrList.contact.Email.toLowerCase();
                                               Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                               email.setTemplateId(emailTemplate.Id);
                                               email.setOrgWideEmailAddressId(orgWideAddr.Id);
                                               email.setToAddresses(new String[]{acrList.contact.Email});
                                               email.setTargetObjectId(acrList.contact.Id);
                                               String emailBody = emailTemplate.HtmlValue;
                                               String emailSubject = emailTemplate.Subject;
                                               emailBody = emailBody.Replace('{%%Account.Name%%}', accounts.Name);
                                               emailBody = emailBody.Replace('{%%CurrentYear%%}', String.valueOf(currentyear));
                                               emailBody = emailBody.Replace('{%%PreviousYear%%}', String.valueOf(previousyear));
                                               emailSubject = emailSubject.Replace('{%%CurrentYear%%}', String.valueOf(currentyear));
                                               emailSubject = emailSubject.Replace('{%%PreviousYear%%}', String.valueOf(previousyear));
                                               email.setSubject(emailSubject);
                                               email.setHtmlBody(emailBody);
                                               emails.add(email);
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
    
    public Static Map<Id, AccountContactRelation> getContacts(Id accountId, Id parentId){
        Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>();
        List<AccountContactRelation> acrListcontacts = [Select Id,ContactId,AccountId,IsActive,Contact.Email from AccountContactRelation where (AccountId = :accountId OR AccountId =: parentId) AND IsActive =true AND Contact.Email != NULL];
        for(AccountContactRelation acr : acrListcontacts){
            acrMap.put(acr.ContactId, acr);
        }
        return acrMap;
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