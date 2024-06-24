/**
* @Name              : ScheduledEmailTriggerTest
* @Description       : Test Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-192
**/
@isTest
private class ScheduledEmailTriggerTest {

    @isTest
    static void testScheduledEmailTrigger() {
         Account testAccount = new Account(
            Name = 'Test Account',
            RecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Residence']
           
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
        insert testContact;

        RegulatoryTrxnFee testFee = new RegulatoryTrxnFee(
            AccountId = testAccount.Id,
            FeeType__c = 'Renewal Unit Fee',
            Status = 'Due'
        );
        insert testFee;

        String jobId = System.schedule('Test Scheduled Job', '0 0 0 15 1 ?', new ScheduledEmailTrigger());

        System.assertNotEquals(null, jobId);

        List<CronTrigger> cronTriggers = [SELECT Id, CronExpression, CronJobDetail.Name FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, cronTriggers.size());

        
    }
}