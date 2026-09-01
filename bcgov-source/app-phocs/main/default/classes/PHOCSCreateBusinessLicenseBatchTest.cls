@IsTest
private class PHOCSCreateBusinessLicenseBatchTest {
	 @testSetUp
     static void setupData() {

        // Create Custom Setting
        PHOCSBusinessLicenseBatchSetting__c setting =
            new PHOCSBusinessLicenseBatchSetting__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                CreatedByUserName__c = UserInfo.getUserName(),
                CreatedDateStart__c = System.now().addDays(-1),
                CreatedDateEnd__c = System.now().addDays(1),
                BatchResult__c = ''
            );
        insert setting;

        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Retrieve an existing License Type
        RegulatoryAuthorizationType licenseType = New RegulatoryAuthorizationType(Name='Drinking Water Operating Permit');
        Insert licenseType;

        // Create BLA
        BusinessLicenseApplication bla = new BusinessLicenseApplication(AccountId = acc.Id,LicenseTypeId = licenseType.Id,Status = 'Closed', AppliedDate=System.now());
        insert bla;
    }

    @IsTest
    static void testBatchSuccess() {

        Test.startTest();
        Database.executeBatch( new PHOCSCreateBusinessLicenseBatch(), 200);
        Test.stopTest();

        List<BusinessLicenseApplication> blas = [SELECT Id,LicensePermitNameId FROM BusinessLicenseApplication];

        System.assertEquals(1,blas.size(),'Expected one BLA');
        System.assertNotEquals(null, blas[0].LicensePermitNameId, 'Business License should be linked');

        List<BusinessLicense> licenses =
            [SELECT Id,
                    Name,
                    Status,
                    Account__c
             FROM BusinessLicense];

        System.assertEquals(1,licenses.size(),'One Business License should be created');
        System.assertEquals('Active',licenses[0].Status);
        PHOCSBusinessLicenseBatchSetting__c setting = PHOCSBusinessLicenseBatchSetting__c.getOrgDefaults();
        System.assert(setting.BatchResult__c.contains('Business License Batch Execution Summary'),'Finish method should update BatchResult');
    }

    @IsTest
    static void testNoMatchingBLAs() {	
        delete [SELECT Id FROM BusinessLicenseApplication];
        Test.startTest();
        Database.executeBatch(new PHOCSCreateBusinessLicenseBatch(), 200 );
        Test.stopTest();

        Integer licenseCount = [SELECT Count()FROM BusinessLicense];
        System.assertEquals(0,licenseCount);
    }

    @IsTest
    static void testInvalidDateRangeException() {

        PHOCSBusinessLicenseBatchSetting__c setting = PHOCSBusinessLicenseBatchSetting__c.getOrgDefaults();

        setting.CreatedDateStart__c = System.now();
        setting.CreatedDateEnd__c = System.now().addDays(-1);

        update setting;

        Test.startTest();

        try {
            new PHOCSCreateBusinessLicenseBatch();
            System.assert(false,'Expected constructor exception');
        } catch (
            PHOCSCreateBusinessLicenseBatch.PHOCSBusinessLicenseBatchException e
        ) {
            System.assert(e.getMessage().contains('Created Date Start cannot be later')
            );
        }

        Test.stopTest();
    }

    @IsTest
    static void testMissingCustomSettingException() {

        delete [SELECT Id FROM PHOCSBusinessLicenseBatchSetting__c];
        Test.startTest();
        try {
            new PHOCSCreateBusinessLicenseBatch();
            System.assert(false,'Expected constructor exception');
        } catch (
            PHOCSCreateBusinessLicenseBatch.PHOCSBusinessLicenseBatchException e
        ) {
            System.assert(e.getMessage().contains( 'custom setting is missing') );
        }
        Test.stopTest();
    }
}