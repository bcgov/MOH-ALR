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

        Test.startTest();

               List<Id> contactIds = new List<Id>{ con.Id };
        ScheduledEmailTrigger.sendRenewalDueEmail(contactIds);

        Test.stopTest();

         List<EmailTemplate> emailTem = [SELECT Id FROM EmailTemplate];
          System.assertEquals(True, emailTem.size()>0, 'No Email is sent');
    }
}