/**
* @Name              : ScheduledSendEmailTest
* @Description       : Test Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-562
**/

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

        String cronExp = '0 0 0 15 1 ?'; // Cron expression for 15th January midnight
        System.schedule('TestSchedule', cronExp, new ScheduleSendEmail());

        Test.stopTest();
        
        List<EmailTemplate> emailTem = [SELECT Id FROM EmailTemplate];
          System.assertEquals(1, emailTem.size(), 'Expected 1 email to be sent');
       
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
          System.assertEquals(1, emailTem.size(), 'Expected 1 email to be sent');
    }
}