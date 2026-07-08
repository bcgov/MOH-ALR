@isTest
private class PhocsFacilityTileControllerTest {
    @TestSetup
    static void setupData() {
        
        User owner = [
            SELECT Id
            FROM User
            WHERE UserRoleId != null
            LIMIT 1
        ];
        
        RegulatoryAuthorizationType reg =
            new RegulatoryAuthorizationType(
                Name = 'Test Reg Type'
            );
        insert reg;
        
        RecordType businessEntityRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType='Account'
            AND DeveloperName='Business_Entity'
            LIMIT 1
        ];
        
        RecordType facilityRT = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType='Account'
            AND DeveloperName='Facility'
            LIMIT 1
        ];
        
        // Business Entity
        Account businessEntity = new Account(
            Name='Business Entity',
            RecordTypeId=businessEntityRT.Id,
            Status__c='Open',
            LicenseType__c=reg.Id,
            OwnerId=owner.Id
        );
        insert businessEntity;
        
        // Facility 1
        Account facility1 = new Account(
            Name='Facility One',
            RecordTypeId=facilityRT.Id,
            Status__c='Pending',
            LicenseType__c=reg.Id,
            ParentAccount__c=businessEntity.Id,
            OwnerId=owner.Id
        );
        
        // Facility 2
        Account facility2 = new Account(
            Name='Facility Two',
            RecordTypeId=facilityRT.Id,
            Status__c='Pending',
            LicenseType__c=reg.Id,
            ParentAccount__c=businessEntity.Id,
            OwnerId=owner.Id
        );
        
        insert new List<Account>{facility1,facility2};
            
            Contact con = new Contact(
                LastName='Portal User',
                AccountId=businessEntity.Id,
                Email='portal@test.com'
            );
        insert con;
        
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name='Customer Community Operator'
            LIMIT 1
        ];
        
        String unique = String.valueOf(System.currentTimeMillis());
        
        User portalUser = new User(
            Alias='ptur',
            Email='portal'+unique+'@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Portal',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='America/New_York',
            CommunityNickname='portal'+unique,
            Username='portal'+unique+'@test.com',
            ContactId=con.Id
        );
        
        insert portalUser;
    }
    
    @isTest
    static void getFacilitiesTest() {
        
        User portalUser = [
            SELECT Id
            FROM User
            WHERE Alias='ptur'
            LIMIT 1
        ];
        PermissionSet ps = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = 'PHOCSOperatorUserCREPS'
            LIMIT 1
        ];
        
        insert new PermissionSetAssignment(
            AssigneeId = portalUser.Id,
            PermissionSetId = ps.Id
        );
        
        Test.startTest();
        
        System.runAs(portalUser){
            
            List<Account> facilities =
                PhocsFacilityTileController.getfacilities();
            
            System.assertEquals(2, facilities.size());
            
        }
        
        Test.stopTest();
    }
    
}