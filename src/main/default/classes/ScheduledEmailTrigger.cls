/**
* @Name              : ScheduledEmailTrigger
* @Description       : Class for Sending Email on  March-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-192
**/

public with sharing class ScheduledEmailTrigger implements Schedulable {
     public static Set<Id> accountIds = new Set<Id>();
 
         public void execute(SchedulableContext sc) {
         Date currentDate = Date.today();
         if(currentDate.month() == 3 && currentDate.day() == 15){
         try {
            
            Map<Id, Set<Id>> accountIdToContactIdsMap = new Map<Id, Set<Id>>();
            List<RegulatoryTrxnFee> fees = [
                SELECT Id,AccountId,ParentRecordId 
                FROM RegulatoryTrxnFee
                WHERE FeeType__c = 'Renewal Unit Fee'
                    AND Status = 'Due'
            ];
              for (RegulatoryTrxnFee fee : fees) {
                accountIds.add(fee.AccountId);
                accountIdToContactIdsMap.put(fee.AccountId, new Set<Id>());
            }
            
            Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>([
                SELECT Id,parentId,
                     (SELECT Id, ContactId, Contact.Name, Contact.Email
                      FROM AccountContactRelations
                      WHERE IsActive = true AND Contact.Email != null)
                FROM Account
                WHERE RecordType.DeveloperName = 'Residence'
                    AND Id IN :accountIds
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
                if(!contactIdsList.isEmpty()){
               sendRenewalDueEmail(contactIdsList);
            }
        }
         catch (Exception e) {
            System.debug('Exception occurred in execute method: ' + e.getMessage());
        }
    }
 }
    public static void sendRenewalDueEmail(List<Id> contactIds) {
        try {
            EmailTemplate emailTemplate = getEmailTemplate('Renewal_Reminder_Email');
           
            if (emailTemplate != null && emailTemplate.Id != null) {
                OrgWideEmailAddress orgWideAddr = [
                    SELECT Id, DisplayName, Address
                    FROM OrgWideEmailAddress
                    WHERE DisplayName = 'ALR Support Email'
                ];
               
                 List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

                 for (Id contactId : contactIds){
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
                List<Messaging.SendEmailResult> sendResults = Messaging.sendEmail(emails);
                
                for (Integer i = 0; i < sendResults.size(); i++) {
                    if (sendResults[i].isSuccess()) {
                        System.debug('Email sent successfully to ContactId: ' + contactIds[i]);
                        
                    } else {
                        System.debug('Failed to send email to ContactId: ' + contactIds[i] + '. Error: ' + sendResults[i].getErrors()[0].getMessage());
                    }
                }
            }
        } 
        }catch (Exception e) {
            System.debug('Exception occurred in sendRenewalDueEmail method: ' + e.getMessage());
        }
    }

    public static EmailTemplate getEmailTemplate(String templateDevName) {
        EmailTemplate emailTemplateRec = null;
        List<Id> contactIdsList = new List<Id>();
        try {
            emailTemplateRec = [
                SELECT Id, DeveloperName, Subject, HtmlValue
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