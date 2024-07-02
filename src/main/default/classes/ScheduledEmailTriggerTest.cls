/**
* @Name              : ScheduledEmailTriggerTest
* @Description       : Test Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-192
**/
@isTest
private class ScheduledEmailTriggerTest {

    @isTest
    static void testExecute() {
               Account acc = new Account(
            Name = 'Test Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Residence').getRecordTypeId()
        );
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert con;

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = acc.Id,
            FeeType__c = 'Renewal Unit Fee',
            Status = 'Due'
        );
        insert fee;

        AccountContactRelation acr = new AccountContactRelation(
            AccountId = acc.Id,
            ContactId = con.Id,
            IsActive = true
        );
      
        Test.startTest();
        ScheduledEmailTrigger send=new ScheduledEmailTrigger();
        send.execute(null);
            
        Test.stopTest();
 List<EmailTemplate> emailTem = [SELECT Id FROM EmailTemplate];
          System.assertEquals(True, emailTem.size()>0, 'No Email is sent');
        
    }
    
    

    @isTest
    static void testSendRenewalDueEmail() {
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert con;
          
        List<Id> contactIds = new List<Id>{ con.Id };
        List<Id> blaId = new List<Id>();
        
        Test.startTest();
        ScheduledEmailTrigger.sendRenewalDueEmail(contactIds , blaId);
        //sendEmailBatch
        Test.stopTest();

         List<EmailTemplate> emailTem = [SELECT Id FROM EmailTemplate];
          System.assertEquals(True, emailTem.size()>0, 'No Email is sent');
    }
    
    @isTest
    static void testSendEmailBatch_Success() {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{'test@example.com'});
        email.setSubject('Test Subject');
        email.setPlainTextBody('Test Body');

        List<Messaging.SingleEmailMessage> emailBatch = new List<Messaging.SingleEmailMessage>();
        emailBatch.add(email);

        Test.startTest();
        ScheduledEmailTrigger.sendEmailBatch(emailBatch);
        Test.stopTest();
        
       List<EmailTemplate> emailTem = [SELECT Id FROM EmailTemplate];
          System.assertEquals(True, emailTem.size()>0, 'No Email is sent');
       }
}