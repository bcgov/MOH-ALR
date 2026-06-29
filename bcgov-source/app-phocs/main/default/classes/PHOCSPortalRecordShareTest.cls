/**
 * @description : test class for PHOCSPortalRecordShare
 * @author PHOCS Team
 * @version 1.0
 * @date 2026-01-20
 * 
 */
@IsTest
private class PHOCSPortalRecordShareTest {

   
    // ---------- 1️⃣ SUCCESS: Multi-level hierarchy ----------
    @IsTest
    static void testShareAllDescendantsSuccess() {
        User u =[SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];

        RegulatoryAuthorizationType reg =
            new RegulatoryAuthorizationType(Name = 'Reg Type');
        insert reg;
        Id accountRecordTypeIdBE =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Entity').getRecordTypeId();
        Id accountRecordTypeIdFacility =  Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        Account root = new Account(Name='Root', LicenseType__c=reg.Id);
        insert root;
	
        Account a1 = new Account(Name='A1', ParentId=root.Id, LicenseType__c=reg.Id,recordtypeid = accountRecordTypeIdBE);
        Account a2 = new Account(Name='A2', ParentId=a1.Id, LicenseType__c=reg.Id,recordtypeid = accountRecordTypeIdFacility);
        Account a3 = new Account(Name='A3', ParentId=a2.Id, LicenseType__c=reg.Id,recordtypeid = accountRecordTypeIdFacility);
        insert new List<Account>{ a1, a2, a3 };


        Map<String,Object> options = new Map<String,Object>{
            'parentAccountId' =>root.id ,
            'userOrGroupId' => u.Id,
            'accessLevel'   => 'Read'
        };

        Map<String,Object> args = new Map<String,Object>{
            'input' => new Map<String,Object>(),
            'output' => new Map<String,Object>(),
            'options' => options
        };

        Test.startTest();
            PHOCSPortalRecordShare svc = new PHOCSPortalRecordShare();
            Map<String,Object> result =
                (Map<String,Object>) svc.call('shareAllDescendantAccounts', args);

            System.assertEquals('SUCCESS', result.get('status'));
            System.assertEquals(0, result.get('sharedCount'));
        Test.stopTest();

        System.assertEquals(
            4,
            [SELECT COUNT() FROM AccountShare WHERE UserOrGroupId = :u.Id]
        );
    }

    // ---------- 2️⃣ NO CHILD ACCOUNTS ----------
    @IsTest
    static void testNoChildAccounts() {
  // Create RegulatoryAuthorizationType
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(
         Name = 'test reg type'
        );
        insert reg;
        Account root = new Account(Name='Root Only',licensetype__c =reg.Id);
        insert root;

        User u =[SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
      

        Map<String,Object> options = new Map<String,Object>{
            'parentAccountId' => root.id ,
            'userOrGroupId' => u.Id,
            'accessLevel'   => 'Read'
        };

        Map<String,Object> args = new Map<String,Object>{
            'input' => new Map<String,Object>(),
            'output' => new Map<String,Object>(),
            'options' => options
        };

        PHOCSPortalRecordShare svc = new PHOCSPortalRecordShare();
        Map<String,Object> result =(Map<String,Object>) svc.call('shareAllDescendantAccounts', args);

        System.assertEquals('SUCCESS', result.get('status'));
        System.assertEquals(0, result.get('sharedCount'));
    }

    // ---------- 3️⃣ INVALID ACCESS LEVEL ----------
    @IsTest
    static void testInvalidAccessLevel() {
          // Create RegulatoryAuthorizationType
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(
         Name = 'test reg type'
        );
        insert reg;

        Account root = new Account(Name='Root',licenseType__c =reg.Id);
        insert root;
        User u =[SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId()];
        Map<String,Object> options = new Map<String,Object>{
             'parentAccountId' =>root.id ,
            'userOrGroupId' => u.Id,
            'accessLevel'   => 'Delete'
        };

        Map<String,Object> args = new Map<String,Object>{
            'input' => new Map<String,Object>(),
            'output' => new Map<String,Object>(),
            'options' => options
        };

        PHOCSPortalRecordShare svc = new PHOCSPortalRecordShare();
        Map<String,Object> result =
            (Map<String,Object>) svc.call('shareAllDescendantAccounts', args);

        System.assertEquals('ERROR', result.get('status'));
    }

    // ---------- 4️⃣ MISSING USER ----------
    @IsTest
    static void testMissingUserId() {

        Map<String,Object> options = new Map<String,Object>{
            'accessLevel' => 'Read'
        };

        Map<String,Object> args = new Map<String,Object>{
            'input' => new Map<String,Object>(),
            'output' => new Map<String,Object>(),
            'options' => options
        };

        PHOCSPortalRecordShare svc = new PHOCSPortalRecordShare();
        Map<String,Object> result =
            (Map<String,Object>) svc.call('shareAllDescendantAccounts', args);

        System.assertEquals('ERROR', result.get('status'));
    }

    // ---------- 5️⃣ UNKNOWN ACTION ----------
    @IsTest
    static void testUnknownAction() {
        Boolean thrown = false;
        try {
            new PHOCSPortalRecordShare()
                .call('badAction', new Map<String,Object>());
        } catch (Exception e) {
            thrown = true;
        }
        System.assert(thrown);
    }
}