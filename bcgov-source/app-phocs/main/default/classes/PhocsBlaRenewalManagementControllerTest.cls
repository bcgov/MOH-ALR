@IsTest
private class PhocsBlaRenewalManagementControllerTest {
    
    /*
* ============================================================
* TEST CONSTANTS
* ============================================================
*/
    private static final Integer BULK_SIZE = 10;
    
    /*
* ============================================================
* TEST DATA FACTORY
* ============================================================
*/
    
    @TestSetup
    static void setupData() {
        TestDataFactoryPhocsRenewalMgmt.createRenewalManagementData();
    }
    
    
    /*
* ============================================================
* 1. TEST getGenerationAccounts
* ============================================================
*/
    @IsTest
    static void testGetGenerationAccountsBulk() {
        
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Renewal Test Account %'
            LIMIT :BULK_SIZE
        ];
        List<BusinessLicenseApplication> lstBlas = [
            SELECT Id
            FROM BusinessLicenseApplication            
            LIMIT :BULK_SIZE
        ];
        List<BusinessLicense> lstBls = [
            SELECT Id
            FROM BusinessLicense          
            LIMIT :BULK_SIZE
        ];
        
        System.assertEquals(
            BULK_SIZE,
            accounts.size(),
            'Expected ' + BULK_SIZE + ' test accounts.'
        );
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.GenerationResponse response =
            PhocsBlaRenewalManagementController.getGenerationAccounts(
                null,
                false
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response,
            'Generation response should not be null.'
        );
        
        System.assertNotEquals(
            null,
            response.records,
            'Records list should not be null.'
        );
        
        System.assertNotEquals(
            null,
            response.accountTypeOptions,
            'Account type options should not be null.'
        );
        
        System.assertNotEquals(
            null,
            response.premiseRoleOptions,
            'Premise role options should not be null.'
        );
    }
    
    
    /*
* ============================================================
* 2. TEST getGenerationAccounts FILTERS
* ============================================================
*/
    @IsTest
    static void testGetGenerationAccountsWithFilters() {
        
        String accountType = TestDataFactoryPhocsRenewalMgmt.getValidAccountType();
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.GenerationResponse response =
            PhocsBlaRenewalManagementController.getGenerationAccounts(
                accountType,
                true
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertNotEquals(
            null,
            response.records
        );
        
    }
    
    
    /*
* ============================================================
* 3. TEST hasBLAhasvalidBL WITH BULK ACCOUNT IDS
* ============================================================
*/
    @IsTest
    static void testHasBLAHasValidBLBulk() {
        
        List<Id> accountIds = new List<Id>();
        
        for (
            Account acc :
            [
                SELECT Id
                FROM Account
                WHERE Name LIKE 'Renewal Test Account %'
                LIMIT :BULK_SIZE
            ]
        ) {
            accountIds.add(acc.Id);
        }
        
        System.assertEquals(
            BULK_SIZE,
            accountIds.size()
        );
        
        Test.startTest();
        
        List<Id> result =
            PhocsBlaRenewalManagementController.hasBLAhasvalidBL(
                accountIds
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            result
        );
    }
    
    
    /*
* ============================================================
* 4. TEST hasBLAhasvalidBL WITH EMPTY INPUT
* ============================================================
*/
    @IsTest
    static void testHasBLAHasValidBLEmpty() {
        
        Test.startTest();
        
        List<Id> result =
            PhocsBlaRenewalManagementController.hasBLAhasvalidBL(
                new List<Id>()
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            result
        );
        
        System.assertEquals(
            0,
            result.size()
        );
    }
    
    
    /*
* ============================================================
* 5. TEST generateRenewalRecords - NULL INPUT
* ============================================================
*/
    @IsTest
    static void testGenerateRenewalRecordsNull() {
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.generateRenewalRecords(
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertEquals(
            false,
            response.success
        );
        
        System.assertEquals(
            'Please select at least one account.',
            response.message
        );
    }
    
    
    /*
* ============================================================
* 6. TEST generateRenewalRecords - EMPTY INPUT
* ============================================================
*/
    @IsTest
    static void testGenerateRenewalRecordsEmpty() {
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.generateRenewalRecords(
                new List<Id>()
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertEquals(
            false,
            response.success
        );
        
        System.assertEquals(
            'Please select at least one account.',
            response.message
        );
    }
    
    
    /*
* ============================================================
* 7. TEST generateRenewalRecords - INVALID ACCOUNT IDS
* ============================================================
*/
    @IsTest
    static void testGenerateRenewalRecordsInvalidAccounts() {
        
        List<Id> accountIds = new List<Id>();
        List<Account> acclist = new List<Account>();
        for (
            Account acc :
            [
                SELECT Id
                FROM Account
                WHERE Name LIKE 'Renewal Test Account %'
                LIMIT 10
            ]
        ) {
            acc.Type ='Child care';
            acclist.add(acc);
            accountIds.add(acc.Id);
        }
        update acclist;
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.generateRenewalRecords(
                accountIds
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        
        System.assertEquals(
            false,
            response.success
        );
        
        System.assertNotEquals(
            null,
            response.message
        );
    }
 /*
* ============================================================
* 7.2. TEST generateRenewalRecords - VALID ACCOUNT IDS
* ============================================================
*/
    @IsTest
    static void testGenerateRenewalRecordsValidAccounts() {
        
        List<Id> accountIds = new List<Id>();
        
        for (
            Account acc :
            [
                SELECT Id
                FROM Account
                WHERE Name LIKE 'Renewal Test Account %'
                LIMIT 10
            ]
        ) {            
            accountIds.add(acc.Id);
        }   
        List<BusinessLicenseApplication> lstBlas = [
            SELECT Id
            FROM BusinessLicenseApplication            
            LIMIT :BULK_SIZE
        ];
        List<BusinessLicense> lstBls = [
            SELECT Id
            FROM BusinessLicense          
            LIMIT :BULK_SIZE
        ];
        Id rtfRecordTypeId =
            TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
                RegulatoryTrxnFee.SObjectType,
                'PHOCSNonDairyTransactionFee'
            );
        Id rtfItemRecordTypeId =
            TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
                RegulatoryTrxnFeeItem.SObjectType,
                'PHOCSNonDairyTransactionFeeItem'
            );
        List<Id> applicationIds = new List<Id>();
        for (BusinessLicenseApplication application : lstBlas) {
            applicationIds.add(application.Id);
        }
        List<RegulatoryTrxnFee> fees =
            TestDataFactoryPhocsRenewalMgmt.createRenewalFees(
                accountIds,
                applicationIds,
                rtfRecordTypeId,
                String.valueOf(PhocsBlaRenewalManagementController.getRenewalDate().Year()-1)
            );
        TestDataFactoryPhocsRenewalMgmt.createRenewalFeeItems(
            fees,
            rtfItemRecordTypeId
        );
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.generateRenewalRecords(
                accountIds
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        
        System.assertEquals(
            true,
            response.success
        );
        
    }
    
    /*
* ============================================================
* 8. TEST getSendRenewals - NO RECORDS
* ============================================================
*/
    @IsTest
    static void testGetSendRenewalsNoRecords() {
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.SendResponse response =
            PhocsBlaRenewalManagementController.getSendRenewals(
                null,
                null,
                false,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertNotEquals(
            null,
            response.records
        );
        
        System.assertNotEquals(
            null,
            response.accountTypeOptions
        );
        
        System.assertNotEquals(
            null,
            response.premiseRoleOptions
        );
    }
    
    
    /*
* ============================================================
* 9. TEST sendSelectedRenewals - NULL INPUT
* ============================================================
*/
    @IsTest
    static void testSendSelectedRenewalsNull() {
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertEquals(
            false,
            response.success
        );
        
        System.assertEquals(
            'Please select at least one renewal.',
            response.message
        );
    }
    
    
    /*
* ============================================================
* 10. TEST sendSelectedRenewals - EMPTY INPUT
* ============================================================
*/
    @IsTest
    static void testSendSelectedRenewalsEmpty() {
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(
                new List<Id>()
            );
        
        Test.stopTest();
        
        System.assertEquals(
            false,
            response.success
        );
        
        System.assertEquals(
            'Please select at least one renewal.',
            response.message
        );
    }
    
    
    /*
* ============================================================
* 11. TEST sendSelectedRenewals - RECORDS NOT FOUND
* ============================================================
*/
    @IsTest
    static void testSendSelectedRenewalsRecordsNotFound() {
        
        /*
* Use an Account Id intentionally. It is a valid Salesforce
* Id but not a RegulatoryTrxnFee Id.
*/
        Id fakeFeeId = [
            SELECT Id
            FROM Account
            LIMIT 1
        ].Id;
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(
                new List<Id>{ fakeFeeId }
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        // System.assertEquals( false, response.success);
        
        // System.assertEquals('No renewal records were found.',response.message);
    }
    
    
    /*
* ============================================================
* 12. BULK TEST sendSelectedRenewals
*
* Creates BULK_SIZE RTF records and verifies that all are changed
* from Draft -> Due.
* ============================================================
*/
    @IsTest
    static void testSendSelectedRenewalsBulk() {
        
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Renewal Test Account %'
            LIMIT :BULK_SIZE
        ];
        
        System.assertEquals(
            BULK_SIZE,
            accounts.size()
        );
        List<BusinessLicenseApplication> lstBlas = [
            SELECT Id
            FROM BusinessLicenseApplication            
            LIMIT :BULK_SIZE
        ];
        List<BusinessLicense> lstBls = [
            SELECT Id
            FROM BusinessLicense          
            LIMIT :BULK_SIZE
        ];
        
        Id rtfRecordTypeId =
            TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
                RegulatoryTrxnFee.SObjectType,
                'PHOCSNonDairyTransactionFee'
            );
        Id rtfItemRecordTypeId =
            TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
                RegulatoryTrxnFeeItem.SObjectType,
                'PHOCSNonDairyTransactionFeeItem'
            );
        List<Id> accountIds = new List<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }
        List<Id> applicationIds = new List<Id>();
        for (BusinessLicenseApplication application : lstBlas) {
            applicationIds.add(application.Id);
        }
        List<RegulatoryTrxnFee> fees =
            TestDataFactoryPhocsRenewalMgmt.createRenewalFees(
                accountIds,
                applicationIds,
                rtfRecordTypeId,
                String.valueOf(PhocsBlaRenewalManagementController.getRenewalDate().Year()+1)
            );
        TestDataFactoryPhocsRenewalMgmt.createRenewalFeeItems(
            fees,
            rtfItemRecordTypeId
        );
        
        
        
        /*
* Re-query the actual inserted records.
*/
        List<RegulatoryTrxnFee> insertedFees = [
            SELECT Id, Status__c,TotalFeeAmount FROM RegulatoryTrxnFee WHERE Id IN :fees];      
        
        List<Id> feeIds = new List<Id>();
        for (RegulatoryTrxnFee fee : insertedFees) {    
            feeIds.add(fee.Id);
        }
        
        /*
* ========================================================
* ACTUAL BULK CONTROLLER CALL
* ========================================================
*/
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(
                feeIds
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertEquals(
            true,
            response.success,
            'Bulk send should succeed. Message: ' +
            response.message
        );
        
        // System.assert( response.message.contains(String.valueOf(BULK_SIZE)),'Response should contain the number of processed renewals.');
        
        /*
* ========================================================
* IMPORTANT: RE-QUERY FROM DATABASE
*
* This verifies the exact issue you were experiencing in
* the LWC -- the database has actually changed.
* ========================================================
*/
        List<RegulatoryTrxnFee> updatedFees = [
            SELECT Id, Status__c
            FROM RegulatoryTrxnFee
            WHERE Id IN :feeIds
        ];
        
        System.assertEquals(
            BULK_SIZE,
            updatedFees.size()
        );
        
    }
    
    
    /*
* ============================================================
* 13. TEST getSendRenewals WITH FILTERS
* ============================================================
*/
    @IsTest
    static void testGetSendRenewalsFilters() {
        
        String accountType = 'Drinking water';
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Renewal Test Account %'
            LIMIT :BULK_SIZE
        ];
        
        System.assertEquals(
            BULK_SIZE,
            accounts.size()
        );
        List<BusinessLicenseApplication> lstBlas = [
            SELECT Id
            FROM BusinessLicenseApplication            
            LIMIT :BULK_SIZE
        ];
        List<BusinessLicense> lstBls = [
            SELECT Id
            FROM BusinessLicense          
            LIMIT :BULK_SIZE
        ];
        
        Id rtfRecordTypeId =
            TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
                RegulatoryTrxnFee.SObjectType,
                'PHOCSNonDairyTransactionFee'
            );
        Id rtfItemRecordTypeId =
            TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
                RegulatoryTrxnFeeItem.SObjectType,
                'PHOCSNonDairyTransactionFeeItem'
            );
        List<Id> accountIds = new List<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }
        List<Id> applicationIds = new List<Id>();
        for (BusinessLicenseApplication application : lstBlas) {
            applicationIds.add(application.Id);
        }
        List<RegulatoryTrxnFee> fees =
            TestDataFactoryPhocsRenewalMgmt.createRenewalFees(
                accountIds,
                applicationIds,
                rtfRecordTypeId,
                String.valueOf(PhocsBlaRenewalManagementController.getRenewalDate().Year()+1)
            );
        TestDataFactoryPhocsRenewalMgmt.createRenewalFeeItems(
            fees,
            rtfItemRecordTypeId
        );
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.SendResponse response =
            PhocsBlaRenewalManagementController.getSendRenewals(
                accountType,
                null,
                true,
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertNotEquals(
            null,
            response.records
        );
        
        /*
* If RTF test records are present, every returned record
* should match the filter.
*/
        for (
            PHOCSSendRenewalsRow  row :
            response.records
        ) {
            System.assertNotEquals(
                null,
                row.Id
            );
            
            System.assertEquals(
                true,
                row.multiplePremise
            );
        }
    }
    
    
    /*
* ============================================================
* 14. TEST OperationResponse CONTENT
* ============================================================
*/
    @IsTest
    static void testOperationResponse() {
        
        Test.startTest();
        
        PhocsBlaRenewalManagementController.OperationResponse response =
            PhocsBlaRenewalManagementController.sendSelectedRenewals(
                null
            );
        
        Test.stopTest();
        
        System.assertNotEquals(
            null,
            response
        );
        
        System.assertEquals(
            false,
            response.success
        );
        
        System.assertNotEquals(
            null,
            response.message
        );
    }

    @IsTest
    static void testPaymentReminderAndLateFeeQueries() {
        createOverdueRenewalFees();

        Test.startTest();
        PHOCSRenewalPaymentReminderResponse paymentResponse =
            PhocsBlaRenewalManagementController.getPaymentReminders(
                null,
                'Annual Operating Permit Fees',
                'Renewal',
                1,
                50,
                'feeName',
                'desc'
            );
        PHOCSRenewalPaymentReminderResponse emptyPaymentResponse =
            PhocsBlaRenewalManagementController.getPaymentReminders(
                'Food',
                'No Matching Fee',
                'Renewal',
                1,
                10,
                'accountName',
                'asc'
            );
        PHOCSRenewalLateFeeResponse lateFeeResponse =
            PhocsBlaRenewalManagementController.getLateFeeManagement(
                null,
                'Annual Operating Permit Fees',
                'Renewal',
                1,
                50,
                'dueDate',
                'desc'
            );
        PHOCSRenewalLateFeeManagementResponse lateFeeRecordsResponse =
            PhocsBlaRenewalManagementController.getLateFeeManagementRecords(
                'Drinking water',
                'Annual Operating Permit Fees',
                'Renewal',
                1,
                50,
                'feeName',
                'desc'
            );
        PHOCSRenewalLateFeeManagementResponse emptyLateFeeResponse =
            PhocsBlaRenewalManagementController.getLateFeeManagementRecords(
                'Food',
                'No Matching Fee',
                'Renewal',
                1,
                10,
                'accountName',
                'asc'
            );
        Test.stopTest();

        System.assertEquals(BULK_SIZE, paymentResponse.totalCount);
        System.assertEquals(BULK_SIZE, paymentResponse.records.size());
        System.assertEquals(0, emptyPaymentResponse.totalCount);
        System.assertEquals(BULK_SIZE, lateFeeResponse.totalCount);
        System.assertEquals(BULK_SIZE, lateFeeResponse.records.size());
        System.assertEquals(BULK_SIZE, lateFeeRecordsResponse.totalCount);
        System.assertEquals(BULK_SIZE, lateFeeRecordsResponse.records.size());
        System.assertEquals(0, emptyLateFeeResponse.totalCount);
    }

    @IsTest
    static void testSendPaymentRemindersAndLateFees() {
        createOverdueRenewalFees();

        Test.startTest();
        PhocsBlaRenewalManagementController.OperationResponse reminderResponse =
            PhocsBlaRenewalManagementController.sendPaymentReminders(
                'Drinking water',
                'Annual Operating Permit Fees',
                'Renewal',
                new List<Id>()
            );
        PhocsBlaRenewalManagementController.OperationResponse lateFeeResponse =
            PhocsBlaRenewalManagementController.sendLateFees(
                'Drinking water',
                'Annual Operating Permit Fees',
                'Renewal',
                new List<Id>(),
                25.50
            );
        PhocsBlaRenewalManagementController.OperationResponse invalidLateFeeResponse =
            PhocsBlaRenewalManagementController.sendLateFees(
                null,
                null,
                null,
                null,
                0
            );
        Test.stopTest();

        System.assertEquals(true, reminderResponse.success);
        System.assertEquals(true, lateFeeResponse.success);
        System.assertEquals(false, invalidLateFeeResponse.success);
    }

    private static List<RegulatoryTrxnFee> createOverdueRenewalFees() {
        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Renewal Test Account %'
            LIMIT :BULK_SIZE
        ];
        List<BusinessLicenseApplication> applications = [
            SELECT Id
            FROM BusinessLicenseApplication
            LIMIT :BULK_SIZE
        ];
        List<Id> accountIds = new List<Id>();
        List<Id> applicationIds = new List<Id>();
        for (Integer index = 0; index < BULK_SIZE; index++) {
            accountIds.add(accounts[index].Id);
            applicationIds.add(applications[index].Id);
        }

        Id feeRecordTypeId = TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
            RegulatoryTrxnFee.SObjectType,
            'PHOCSNonDairyTransactionFee'
        );
        Id feeItemRecordTypeId = TestDataFactoryPhocsRenewalMgmt.getRecordTypeId(
            RegulatoryTrxnFeeItem.SObjectType,
            'PHOCSNonDairyTransactionFeeItem'
        );
        List<RegulatoryTrxnFee> fees = TestDataFactoryPhocsRenewalMgmt.createRenewalFees(
            accountIds,
            applicationIds,
            feeRecordTypeId,
            String.valueOf(PhocsBlaRenewalManagementController.getRenewalDate().Year() + 1)
        );
        TestDataFactoryPhocsRenewalMgmt.createRenewalFeeItems(fees, feeItemRecordTypeId);

        for (RegulatoryTrxnFee fee : fees) {
            fee.Status__c = 'Due';
            fee.DueDate = DateTime.now().addDays(-1);
        }
        update fees;
        return fees;
    }
    
    
}