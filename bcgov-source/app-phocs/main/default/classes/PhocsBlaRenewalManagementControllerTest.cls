@IsTest
private class PhocsBlaRenewalManagementControllerTest {
    private static Account facility;
    private static BusinessLicenseApplication bla;
    private static RegulatoryTrxnFee renewalFee;
    private static RegulatoryTrxnFee dueFee;

    @TestSetup
    static void setupData() {
        Id parentRt = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Business_Entity')
            .getRecordTypeId();

        Account parentAccount = new Account(
            Name = 'Parent Renewal Account',
            Type = getValidAccountType(),
            RecordTypeId = parentRt,
            Status__c = 'Open'
        );
        insert parentAccount;

        Id facilityRt = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Facility')
            .getRecordTypeId();

        facility = new Account(
            Name = 'Renewal Facility',
            ParentId = parentAccount.Id,
            Type = getValidAccountType(),
            RecordTypeId = facilityRt,
            Status__c = 'Open',
            CategoryL1__c = 'Commercial',
            CategoryL2__c = 'Indoor cold plunge pool',
            OperatingMonths__c = 'January,February',
            MultiplePremiseFacility__c = true,
            PremiseRole__c = getFirstPicklistValue(Account.SObjectType, 'PremiseRole__c')
        );
        insert facility;

        RegulatoryAuthority auth = new RegulatoryAuthority(
            Name = 'Community Care & Assisted Living Act'
        );
        insert auth;

        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
            Name = 'Food Premises Operating Permit',
            RegulatoryAuthCategory = 'License',
            IssuingDepartmentId = auth.Id
        );
        insert licenseType;

        Id blaRt = Schema.SObjectType.BusinessLicenseApplication
            .getRecordTypeInfosByDeveloperName()
            .get('OperatingPermitApplication')
            .getRecordTypeId();

        bla = new BusinessLicenseApplication(
            AccountId = facility.Id,
            RecordTypeId = blaRt,
            Status = 'Closed',
            ClosureReason__c = 'Approved',
            ClosedDate__c = Date.today(),
            ClosedBy__c = UserInfo.getUserId(),
            Category = 'Permit',
            AppliedDate = Date.today().addMonths(-1),
            LicenseTypeId = licenseType.Id
        );
        insert bla;

        Id rtfRt = Schema.SObjectType.RegulatoryTrxnFee
            .getRecordTypeInfosByDeveloperName()
            .get('PHOCSNonDairyTransactionFee')
            .getRecordTypeId();

        Id rtfItemRt = Schema.SObjectType.RegulatoryTrxnFeeItem
            .getRecordTypeInfosByDeveloperName()
            .get('PHOCSNonDairyTransactionFeeItem')
            .getRecordTypeId();

        renewalFee = new RegulatoryTrxnFee(
            AccountId = facility.Id,
            ParentRecordId = bla.Id,
            RecordTypeId = rtfRt,
            Status__c = 'Draft',
            FeeType__c = 'Renewal',
            RenewalYear__c = String.valueOf(Date.today().year() + 1),
            DueDate = Date.today().addDays(10)
        );
        insert renewalFee;

        insert new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = renewalFee.Id,
            RecordTypeId = rtfItemRt,
            Name = 'Annual Operating Permit Fees',
            FeeType__c = 'Annual Operating Permit Fees',
            FeeAmount = 100,
            Status__c = 'Due'
        );

        dueFee = new RegulatoryTrxnFee(
            AccountId = facility.Id,
            ParentRecordId = bla.Id,
            RecordTypeId = rtfRt,
            Status__c = 'Due',
            FeeType__c = 'New Application',
            DueDate = Date.today().addDays(-3)
        );
        insert dueFee;

        insert new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = dueFee.Id,
            RecordTypeId = rtfItemRt,
            Name = 'Annual Operating Permit Fees',
            FeeType__c = 'Annual Operating Permit Fees',
            FeeAmount = 150,
            Status__c = 'Due'
        );
    }

    @IsTest
    static void testGetGenerationAccountsAndValidBL() {
        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Renewal Facility'
            LIMIT 1
        ];

        Test.startTest();

        PhocsBlaRenewalManagementController.GenerationResponse generationResponse =
            PhocsBlaRenewalManagementController.getGenerationAccounts(null, false);

        List<Id> validIds = PhocsBlaRenewalManagementController.hasBLAhasvalidBL(
            new List<Id>{ acc.Id }
        );

        Test.stopTest();

        System.assertNotEquals(null, generationResponse);
        System.assertNotEquals(null, generationResponse.records);
        System.assertNotEquals(null, generationResponse.accountTypeOptions);
        System.assertNotEquals(null, generationResponse.premiseRoleOptions);

        System.assertNotEquals(null, validIds);
    }

    @IsTest
    static void testGenerateRenewalRecordsAndSendRenewals() {
        Account acc = [
            SELECT Id
            FROM Account
            WHERE Name = 'Renewal Facility'
            LIMIT 1
        ];

        RegulatoryTrxnFee fee = [
            SELECT Id
            FROM RegulatoryTrxnFee
            WHERE FeeType__c = 'Renewal'
            LIMIT 1
        ];

        Test.startTest();

        PhocsBlaRenewalManagementController.OperationResponse generateResponse =
            PhocsBlaRenewalManagementController.generateRenewalRecords(
                new List<Id>{ acc.Id }
            );

        PhocsBlaRenewalManagementController.SendResponse sendResponse =
            PhocsBlaRenewalManagementController.getSendRenewals(
                null,
                null,
                false,
                null
            );

        PhocsBlaRenewalManagementController.OperationResponse sendSelectedResponse =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(
                new List<Id>{ fee.Id }
            );

        Test.stopTest();

        System.assertNotEquals(null, generateResponse);
        System.assert(String.isNotBlank(generateResponse.message),
            'Expected generate response message.');

        System.assertNotEquals(null, sendResponse);
        System.assertNotEquals(null, sendResponse.records);
        System.assertNotEquals(null, sendResponse.accountTypeOptions);
        System.assertNotEquals(null, sendResponse.premiseRoleOptions);

        System.assertNotEquals(null, sendSelectedResponse);
        System.assert(String.isNotBlank(sendSelectedResponse.message),
            'Expected send selected renewal response message.');
    }

    @IsTest
    static void testPaymentReminderAndLateFeeFlows() {
        Test.startTest();

        PHOCSRenewalPaymentReminderResponse paymentReminders =
            PhocsBlaRenewalManagementController.getPaymentReminders(
                null,
                null,
                'Regulatory Transaction Fee',
                1,
                20,
                'accountName',
                'asc'
            );

        PhocsBlaRenewalManagementController.OperationResponse paymentReminderResponse =
            PhocsBlaRenewalManagementController.sendPaymentReminders(
                null,
                null,
                'Regulatory Transaction Fee',
                null
            );

        PHOCSRenewalLateFeeResponse lateFeeManagement =
            PhocsBlaRenewalManagementController.getLateFeeManagement(
                null,
                null,
                'Regulatory Transaction Fee',
                1,
                20,
                'accountName',
                'asc'
            );

        PHOCSRenewalLateFeeManagementResponse lateFeeRecords =
            PhocsBlaRenewalManagementController.getLateFeeManagementRecords(
                null,
                null,
                'Regulatory Transaction Fee',
                1,
                20,
                'accountName',
                'asc'
            );

        PhocsBlaRenewalManagementController.OperationResponse lateFeeResponse =
            PhocsBlaRenewalManagementController.sendLateFees(
                null,
                null,
                'Regulatory Transaction Fee',
                null,
                10
            );

        Test.stopTest();

        System.assertNotEquals(null, paymentReminders);
        System.assertNotEquals(null, paymentReminders.records);
        System.assertNotEquals(null, paymentReminderResponse);
        System.assert(String.isNotBlank(paymentReminderResponse.message),
            'Expected payment reminder response message.');

        System.assertNotEquals(null, lateFeeManagement);
        System.assertNotEquals(null, lateFeeManagement.records);

        System.assertNotEquals(null, lateFeeRecords);
        System.assertNotEquals(null, lateFeeRecords.records);

        System.assertNotEquals(null, lateFeeResponse);
        System.assert(String.isNotBlank(lateFeeResponse.message),
            'Expected late fee response message.');
    }

    @IsTest
    static void testValidationGuardClauses() {
        Test.startTest();

        PhocsBlaRenewalManagementController.OperationResponse generateNull =
            PhocsBlaRenewalManagementController.generateRenewalRecords(null);

        PhocsBlaRenewalManagementController.OperationResponse generateEmpty =
            PhocsBlaRenewalManagementController.generateRenewalRecords(new List<Id>());

        PhocsBlaRenewalManagementController.OperationResponse sendNull =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(null);

        PhocsBlaRenewalManagementController.OperationResponse sendEmpty =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(new List<Id>());

        Test.stopTest();

        System.assertNotEquals(null, generateNull);
        System.assertEquals(false, generateNull.success);

        System.assertNotEquals(null, generateEmpty);
        System.assertEquals(false, generateEmpty.success);

        System.assertNotEquals(null, sendNull);
        System.assertEquals(false, sendNull.success);

        System.assertNotEquals(null, sendEmpty);
        System.assertEquals(false, sendEmpty.success);
    }

    private static String getValidAccountType() {
        for (Schema.PicklistEntry entry : Account.Type.getDescribe().getPicklistValues()) {
            if (entry.isActive() && (
                entry.getLabel() == 'Food' ||
                entry.getLabel() == 'Drinking water' ||
                entry.getLabel() == 'Recreational water'
            )) {
                return entry.getValue();
            }
        }
        return null;
    }

    private static String getFirstPicklistValue(
        Schema.SObjectType objectType,
        String fieldName
    ) {
        Map<String, Schema.SObjectField> fields =
            objectType.getDescribe().fields.getMap();

        if (!fields.containsKey(fieldName)) {
            return null;
        }

        Schema.DescribeFieldResult describeResult =
            fields.get(fieldName).getDescribe();

        if (describeResult.getType() != Schema.DisplayType.Picklist) {
            return null;
        }

        for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
            if (entry.isActive()) {
                return entry.getValue();
            }
        }
        return null;
    }
}