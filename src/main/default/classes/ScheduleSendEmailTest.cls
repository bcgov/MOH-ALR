/***
* @Name              : ScheduledSendEmailTest
* @Description       : Test Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-562
***/

@isTest
private class ScheduleSendEmailTest {

    @isTest
    static void testExecute() {
         Account acc = new Account(
            Name = 'Test Account',
            Status__c = 'Registered Active'
        );
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert con;

        AccountContactRelation acr = new AccountContactRelation(
            AccountId = acc.Id,
            ContactId = con.Id,
            IsActive = true
        );
       
        
        
        Test.startTest();
        ScheduleSendEmail send=new ScheduleSendEmail();
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
        Test.startTest();
        ScheduleSendEmail.sendRenewalDueEmail(contactIds);
        Test.stopTest();
        
        List<EmailTemplate> emailTem = [SELECT Id FROM EmailTemplate];
          System.assertEquals(True, emailTem.size()>0, 'No Email is sent');
    }
    
}