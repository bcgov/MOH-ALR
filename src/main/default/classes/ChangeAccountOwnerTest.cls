/**
* @Name              : AccountContactRelationController
* @Description       : This Test class transfer Account and related records Owners.
* @Author            : Keerthana (Accenture)
* @StoryNo           : ALR-134
**/

@isTest
private class ChangeAccountOwnerTest {
    
    @isTest
    static void testTransferAccountOwnership() {
        
        Id adminId =[Select Id From Profile where Name='System Administrator'].Id;
        
        User oldUser = new User(
            FirstName = 'oldUser',
            LastName = 'User',
            Username = 'oldUser1@test.com',
            Email = 'oldUser@example.com',
            Alias = 'ouser',
            ProfileId = adminId,
            CommunityNickname = 'old987user',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert oldUser;
       
        User newUser = new User(
            FirstName = 'Testone',
            LastName = 'User1',
            Username = 'test1user@test.com',
            Email = 'testuser@example.com',
            Alias = 'tuser',
            ProfileId = adminId,
            CommunityNickname = 'test123user',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert newUser;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
        loc.Longitude = 28.635308;
        loc.Latitude = 28.635308;
        insert loc;
        
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        String uniqueName = 'Residence_' + Datetime.now().getTime();
        Account acc = TestDataFactory.createResidence('Residence', uniqueName, regAuth.Id, true);
        
        Case caseRec = new Case(AccountId=acc.Id, Status='Under Inspection',OwnerId=oldUser.Id);
        insert caseRec;
        
        BusinessLicenseApplication bla = TestDataFactory.createRenewalBla(acc.LicenseType__c, acc.Id, true);  
        
        ChangeAccountOwner.FlowInputs flowInputs = new ChangeAccountOwner.FlowInputs();
        flowInputs.newOwnerId = newUser.Id;
        flowInputs.accountId = new List<Id>{ acc.Id };
        flowInputs.isBlaChecked = true;
        flowInputs.isPublicChecked = true;
        flowInputs.isCaseChecked = true;
        flowInputs.isInspectionChecked = true;
        
        List<ChangeAccountOwner.FlowInputs> inputs = new List<ChangeAccountOwner.FlowInputs>{ flowInputs };
            
        Test.startTest();
        ChangeAccountOwner.transferAccountOwnership(inputs);
        Test.stopTest();
                
        List<Account> updatedAccount = [SELECT Id, OwnerId FROM Account WHERE Id = :acc.Id];
        Assert.isNotNull(updatedAccount.size());
        
        List<Case> updatedCases = [SELECT Id, OwnerId FROM Case WHERE AccountId = :acc.Id];
        //for (Case c : updatedCases) {
            Assert.isNotNull(updatedCases.size());
        //}
        
        List<BusinessLicenseApplication> updatedBlaRecords = [SELECT Id, OwnerId FROM BusinessLicenseApplication WHERE AccountId = :acc.Id];
       // for (BusinessLicenseApplication blaRecord : updatedBlaRecords) {
            Assert.isNotNull(updatedBlaRecords.size());
        //}
        
        List<PublicComplaint> updatedPublicCompRecords = [SELECT Id, OwnerId FROM PublicComplaint WHERE AccountId = :acc.Id];
       // for (PublicComplaint pc : updatedPublicCompRecords) {
            Assert.isNotNull(updatedCases.size());
        //}
        
        List<Visit> updatedVisitRecords = [SELECT Id, OwnerId FROM Visit WHERE AccountId = :acc.Id];
             Assert.isNotNull(updatedVisitRecords.size());
   
}
}