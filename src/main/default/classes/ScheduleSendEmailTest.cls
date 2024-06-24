/**
* @Name              : ScheduledSendEmailTest
* @Description       : Test Class for Sending Email on  Jan-15
* @Author            : Keerthana Srinivasan (Accenture)
* @StoryNo           : ALR-562
**/
@isTest
private class ScheduleSendEmailTest {

    @TestSetup
    static void setup() {
        // Create test data for EmailTemplate
        EmailTemplate testTemplate = new EmailTemplate(
            DeveloperName = 'Upcoming_Renewal_Email_Template',
            Subject = 'Test Subject',
            HtmlValue = '<html><body>Test Body</body></html>',
            Body = 'Test Body',
            Name= 'Upcoming Renewal Email Template', 
            FolderId='00lJQ000002JQ8vYAG' ,
            TemplateType='custom'
        );
       // insert testTemplate;

        // Create test data for OrgWideEmailAddress
        OrgWideEmailAddress testOrgWideAddr = new OrgWideEmailAddress(
            DisplayName = 'ALR Support Email',
            Address = 'support@example.com'
        );
        //insert testOrgWideAddr;

        // Create test data for Account with related Contact and AccountContactRelation
        Account testAccount = new Account(
            Name = 'Test Account',
            Status__c = 'Registered Active'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com'
        );
       
        AccountContactRelation testACR = new AccountContactRelation(
            AccountId = testAccount.Id,
            ContactId = testContact.Id,
            IsActive = true
        );
     
    }

    @isTest
    static void testScheduledJob() {
        Test.startTest();        
        String cronExp = '0 0 0 15 1 ?'; // March 15th at midnight
        System.schedule('Test Schedule', cronExp, new ScheduleSendEmail());
    }
    
    
    
}