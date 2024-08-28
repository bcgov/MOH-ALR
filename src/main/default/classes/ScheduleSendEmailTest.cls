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
        List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
		Account acc = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        accList.add(acc);
        
        Account accRec =  [SELECT Id , Name , ParentId FROM Account where Id =: acc.Id];
 
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test.contact@example.com',
            AccountId=accRec.Id
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
      
}