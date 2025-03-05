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

        // Step 1: Query the Custom Permission
        CustomPermission customPerm = [
        SELECT Id FROM CustomPermission 
        WHERE Id = '0CPJQ0000001n0I4AQ'
        LIMIT 1
        ];

		// Step 2: Query the Permission Set that includes this Custom Permission	
        PermissionSet permSet = [
        SELECT Id FROM PermissionSet 
        WHERE Id IN (SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId = :customPerm.Id) 
        LIMIT 1
        ];

        User newUser = new User(
            FirstName = 'Testone',
            LastName = 'User1',
            Username = 'alrtest1user@test.com',
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

        System.runAs(newUser) { // Separate Setup Object DML
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = newUser.Id,
                PermissionSetId = permSet.Id
            );
            insert psa;
    	}

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
          
        system.runAs(oldUser) {
            Test.startTest();
                ChangeAccountOwner.transferAccountOwnership(inputs);
            Test.stopTest();
        }
                
        List<Account> updatedAccount = [SELECT Id, OwnerId FROM Account WHERE Id = :acc.Id];
        Assert.isNotNull(updatedAccount.size());
        
        List<Case> updatedCases = [SELECT Id, OwnerId FROM Case WHERE AccountId = :acc.Id];
        Assert.isNotNull(updatedCases.size());
        
        Id stExam = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByName().get('New License').getRecordTypeId();
        
        BusinessLicenseApplication updatedBlaRecords = new BusinessLicenseApplication();
        updatedBlaRecords.AccountId = acc.Id;
        updatedBlaRecords.RecordtypeId= stExam;
        updatedBlaRecords.Status = 'Approved';
        updatedBlaRecords.LicenseTypeId = acc.LicenseType__c;
        updatedBlaRecords.AppliedDate = System.today();
        insert updatedBlaRecords;
        
        System.assertNotEquals(null, updatedBlaRecords.Id);
        
        PublicComplaint publiccompliants = new PublicComplaint();
        publiccompliants.AccountId = acc.Id;
        publiccompliants.Status = 'Needs Review';
        publiccompliants.IncidentDate = System.today();
        publiccompliants.Category__c = 'ALR';
        publiccompliants.NeedFeedbackonResolution__c = 'No';
        publiccompliants.WishtoRemainAnonymous__c = 'No';
        publiccompliants.ResidentAwareOfComplaint__c = 'Yes';
        insert publiccompliants;
        
        System.assertNotEquals(null, publiccompliants.Id);
         
        Visit visits = new Visit();
        visits.AccountId = acc.Id;
        visits.Status = 'Planned';
        visits.PlannedVisitEndTime = System.today();
        visits.PlannedVisitStartTime = System.today();
        visits.ActualVisitStartTime = System.today();
        visits.PlaceId = loc.Id;
        insert visits;
       
        System.assertNotEquals(null, visits.Id);
        
        Map<Id, Id> currentOwnerIds = new Map<Id, Id>();
        for (Account a : [SELECT Id, OwnerId FROM Account WHERE Id = :acc.Id]) {
            currentOwnerIds.put(a.Id, a.OwnerId);
       }
      
        Map<Id, List<BusinessLicenseApplication>> blaRecordsMap = ChangeAccountOwner.getRelatedBlaRecords(new List<Id>{ acc.Id }, currentOwnerIds);
        Map<Id, List<PublicComplaint>> publicCompRecordsMap = ChangeAccountOwner.getRelatedPublicCompRecords(new List<Id>{ acc.Id }, currentOwnerIds);
        Map<Id, List<Case>> caseRecordsMap = ChangeAccountOwner.getRelatedCaseRecords(new List<Id>{ acc.Id }, currentOwnerIds);
        Map<Id, List<Visit>> visitRecordsMap = ChangeAccountOwner.getRelatedVisitRecords(new List<Id>{ acc.Id }, currentOwnerIds);
    }
    
    @isTest
    static void testTransferAccountOwnershipWithBLA() {
        
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

        // Step 1: Query the Custom Permission
        CustomPermission customPerm = [
        SELECT Id FROM CustomPermission 
        WHERE Id = '0CPJQ0000001n0I4AQ'
        LIMIT 1
        ];

		// Step 2: Query the Permission Set that includes this Custom Permission	
        PermissionSet permSet = [
        SELECT Id FROM PermissionSet 
        WHERE Id IN (SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId = :customPerm.Id) 
        LIMIT 1
        ];

        User newUser = new User(
            FirstName = 'Testone',
            LastName = 'User1',
            Username = 'alrtest1user@test.com',
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

        System.runAs(newUser) { // Separate Setup Object DML
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = newUser.Id,
            PermissionSetId = permSet.Id
        );
        insert psa;
    	}
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
        
        Id stExam = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByName().get('New License').getRecordTypeId();
        
        BusinessLicenseApplication updatedBlaRecords = new BusinessLicenseApplication();
        updatedBlaRecords.AccountId = acc.Id;
        updatedBlaRecords.RecordtypeId= stExam;
        updatedBlaRecords.Status = 'Approved';
        updatedBlaRecords.LicenseTypeId = acc.LicenseType__c;
        updatedBlaRecords.AppliedDate = System.today();
        insert updatedBlaRecords;
        
        
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
    }
    
    @isTest
    static void testTransferAccountOwnershipWithPublicComp() {
        
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

        // Step 1: Query the Custom Permission
        CustomPermission customPerm = [
        SELECT Id FROM CustomPermission 
        WHERE Id = '0CPJQ0000001n0I4AQ'
        LIMIT 1
        ];

		// Step 2: Query the Permission Set that includes this Custom Permission	
        PermissionSet permSet = [
        SELECT Id FROM PermissionSet 
        WHERE Id IN (SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId = :customPerm.Id) 
        LIMIT 1
        ];

        User newUser = new User(
            FirstName = 'Testone',
            LastName = 'User1',
            Username = 'alrtest1user@test.com',
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

        System.runAs(newUser) { // Separate Setup Object DML
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = newUser.Id,
            PermissionSetId = permSet.Id
        );
        insert psa;
    	}
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
        
        Id stExam = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByName().get('New License').getRecordTypeId();
        
        BusinessLicenseApplication updatedBlaRecords = new BusinessLicenseApplication();
        updatedBlaRecords.AccountId = acc.Id;
        updatedBlaRecords.RecordtypeId= stExam;
        updatedBlaRecords.Status = 'Approved';
        updatedBlaRecords.LicenseTypeId = acc.LicenseType__c;
        updatedBlaRecords.AppliedDate = System.today();
        insert updatedBlaRecords;
        
        PublicComplaint publiccompliants = new PublicComplaint();
        publiccompliants.AccountId = acc.Id;
        publiccompliants.Status = 'Needs Review';
        publiccompliants.IncidentDate = System.today();
        publiccompliants.Category__c = 'ALR';
        publiccompliants.NeedFeedbackonResolution__c = 'No';
        publiccompliants.WishtoRemainAnonymous__c = 'No';
        publiccompliants.ResidentAwareOfComplaint__c = 'Yes';
        insert publiccompliants;
        
        
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
    }   
}