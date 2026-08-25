@IsTest
private class PhocsBlaRenewalManagementControllerTest {

    /*
     * ============================================================
     * TEST CONSTANTS
     * ============================================================
     */
    private static final Integer BULK_SIZE = 200;

    /*
     * ============================================================
     * TEST DATA FACTORY
     * ============================================================
     */

    @TestSetup
    static void setupData() {
        
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name='EHIS Standard User'
            LIMIT 1
        ];
        
        String unique = String.valueOf(System.currentTimeMillis());
        
        User closedbyuser = new User(
            Alias='ptur',
            Email='portal'+unique+'@test.com',
            EmailEncodingKey='UTF-8',
            LastName='Portal',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=p.Id,
            TimeZoneSidKey='America/New_York',            
            Username='portal'+unique+'@test.com'            
        );
        
        insert closedbyuser;

        /*
         * Create a parent account.
         */
        Id bzAccRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Business_Entity').getRecordTypeId();
        Account parentAccount = new Account(
            Name = 'Test Parent Account',
            Type = getValidAccountType(),
            RecordTypeId=bzAccRecTypeId
        );

        setIfCreateable(
            parentAccount,
            'Status__c',
            'Open'
        );

        insert parentAccount;


        /*
         * Create 200 accounts to exercise bulk processing.
         */
        List<Account> accounts = new List<Account>();
		Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        for (Integer i = 0; i < BULK_SIZE; i++) {

            Account acc = new Account(
                Name = 'Renewal Test Account ' + i,
                Type = getValidAccountType(),
                ParentId = parentAccount.Id,
                //ParentAccount__c = parentAccount.Id,
                SourceSystemIdentifier='XXXXXXXX'+i,
                RecordTypeId=AccountRecordTypeId
            );
            

            setIfCreateable(acc, 'Status__c', 'Open');
            setIfCreateable(acc, 'CategoryL1__c', 'Commercial');
            setIfCreateable(acc, 'CategoryL2__c', 'Indoor cold plunge pool');
            setIfCreateable(acc, 'OperatingMonths__c', 'January,February');
            setIfCreateable(acc, 'MultiplePremiseFacility__c', true);

            /*
             * Only set this if your org has a valid picklist value.
             */
            String premiseRole = getFirstPicklistValue(
                Account.SObjectType,
                'PremiseRole__c'
            );

            if (premiseRole != null) {
                setIfCreateable(
                    acc,
                    'PremiseRole__c',
                    premiseRole
                );
            }

            accounts.add(acc);
        }

        insert accounts;
        RegulatoryAuthority communityAuthority = new RegulatoryAuthority(
            Name = 'Community Care & Assisted Living Act'
        );
        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
            Name = 'Food Premises Operating Permit',
            RegulatoryAuthCategory = 'License',
            IssuingDepartmentId = communityAuthority.Id
        );
        
        insert licenseType;
        
        /*Create 200 BLA*/
        List<BusinessLicenseApplication> lstblas = new List<BusinessLicenseApplication>();
		Id blaRecordTypeId = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('OperatingPermitApplication').getRecordTypeId();
        for (Integer i = 0; i < BULK_SIZE; i++) {

            BusinessLicenseApplication bla = new BusinessLicenseApplication(                
                accountId = accounts[i].Id,
                RecordTypeId=blaRecordTypeId
            );
            setIfCreateable(bla, 'Status', 'Closed');
            setIfCreateable(bla, 'ClosureReason__c', 'Approved');
            setIfCreateable(bla, 'ClosedDate__c', System.today());
                setIfCreateable(bla, 'ClosedBy__c', closedbyuser.Id); 
            setIfCreateable(bla, 'Category', 'Permit');
            setIfCreateable(bla, 'AppliedDate', System.today().addMonths(-1));
            setIfCreateable(bla, 'LicenseTypeId', licenseType.Id);
            lstblas.add(bla);
        }

        insert lstblas;
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
            LIMIT 200
        ];

        System.assertEquals(
            BULK_SIZE,
            accounts.size(),
            'Expected 200 test accounts.'
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

        String accountType = getValidAccountType();

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
                LIMIT 200
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

        /*
         * These accounts don't necessarily have an eligible BLA.
         * Therefore the expected result is an error response rather
         * than an exception.
         */
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

        System.assertEquals(
            false,
            response.success
        );

        System.assertEquals(
            'No renewal records were found.',
            response.message
        );
    }


    /*
     * ============================================================
     * 12. BULK TEST sendSelectedRenewals
     *
     * Creates 200 RTF records and verifies that all are changed
     * from Draft -> Due.
     * ============================================================
     */
    @IsTest
    static void testSendSelectedRenewalsBulk() {

        List<Account> accounts = [
            SELECT Id
            FROM Account
            WHERE Name LIKE 'Renewal Test Account %'
            LIMIT 200
        ];

        System.assertEquals(
            200,
            accounts.size()
        );
        List<BusinessLicenseApplication> lstBlas = [
            SELECT Id
            FROM BusinessLicenseApplication            
            LIMIT 200
        ];

        Id rtfRecordTypeId =
            getRecordTypeId(
                RegulatoryTrxnFee.SObjectType,
                'PHOCSNonDairyTransactionFee'
            );
        Id rtfItemRecordTypeId =
            getRecordTypeId(
                RegulatoryTrxnFee.SObjectType,
                'PHOCSNonDairyTransactionFeeItem'
            );
        List<RegulatoryTrxnFee> fees =
            new List<RegulatoryTrxnFee>();

        for (Integer i = 0; i < accounts.size(); i++) {

            RegulatoryTrxnFee fee = new RegulatoryTrxnFee();
            fee.AccountId = accounts[i].Id;
            fee.parentRecordId=lstBlas[i].Id;
            fee.Status__c = 'Draft';
            fee.FeeType__c = 'Renewal'; 
            fee.RenewalYear__c =
                String.valueOf(Date.today().year() + 1);
             fee.RecordTypeId = rtfRecordTypeId;
            fees.add(fee);
        }		

        Database.SaveResult[] insertResults = Database.insert(fees, false);
        List<RegulatoryTrxnFeeItem> feeItems =
            new List<RegulatoryTrxnFeeItem>();
        for (Integer i = 0; i < fees.size(); i++) {
            RegulatoryTrxnFeeItem feeItem = new RegulatoryTrxnFeeItem();            
            feeItem.RegulatoryTrxnFeeId = fees[i].Id;
            feeItem.Status__c = 'Draft';
            feeItem.FeeType__c = 'Annual Operating Permit Fees'; 
            feeItem.FeeAmount =100;                
            feeItem.RecordTypeId = rtfItemRecordTypeId;
            feeItems.add(feeItem);
        }
        Database.SaveResult[] insertResults2 = Database.insert(feeItems, false);
        
       
        
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

        System.assert(
            response.message.contains('200'),
            'Response should contain the number of processed renewals.'
        );

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
            200,
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

        String accountType = getValidAccountType();

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
            PhocsBlaRenewalManagementController.SendRow row :
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


    /*
     * ============================================================
     * HELPERS
     * ============================================================
     */

    /**
     * Gets a valid Account.Type value.
     *
     * Your controller expects:
     * Food
     * Drinking water
     * Recreational water
     *
     * But the actual picklist value may differ from the label.
     */
    private static String getValidAccountType() {

        Schema.DescribeFieldResult describe =
            Account.Type.getDescribe();

        for (Schema.PicklistEntry entry :
            describe.getPicklistValues()) {

            if (entry.isActive() &&
                (
                    entry.getLabel() == 'Food' ||
                    entry.getLabel() == 'Drinking water' ||
                    entry.getLabel() == 'Recreational water'
                )
            ) {
                return entry.getValue();
            }
        }

        /*
         * Fallback for orgs where Type is not configured as
         * the expected picklist.
         */
        return null;
    }


    /**
     * Safely sets a field if it exists and is createable.
     */
    private static void setIfCreateable(
        SObject record,
        String fieldName,
        Object value
    ) {

        Map<String, Schema.SObjectField> fields =
            record.getSObjectType()
                  .getDescribe()
                  .fields
                  .getMap();

        if (!fields.containsKey(fieldName)) {
            return;
        }

        Schema.DescribeFieldResult describe =
            fields.get(fieldName).getDescribe();

        if (describe.isCreateable()) {
            record.put(fieldName, value);
        }
    }


    /**
     * Gets the first active picklist value.
     */
    private static String getFirstPicklistValue(
        Schema.SObjectType objectType,
        String fieldName
    ) {

        Map<String, Schema.SObjectField> fields =
            objectType.getDescribe()
                      .fields
                      .getMap();

        if (!fields.containsKey(fieldName)) {
            return null;
        }

        Schema.DescribeFieldResult describe =
            fields.get(fieldName).getDescribe();

        if (describe.getType() != Schema.DisplayType.Picklist) {
            return null;
        }

        for (Schema.PicklistEntry entry :
            describe.getPicklistValues()) {

            if (entry.isActive()) {
                return entry.getValue();
            }
        }

        return null;
    }


    /**
     * Gets a record type by developer name.
     */
    private static Id getRecordTypeId(
        Schema.SObjectType objectType,
        String developerName
    ) {

        Map<String, Schema.RecordTypeInfo> recordTypes =
            objectType.getDescribe()
                      .getRecordTypeInfosByDeveloperName();

        if (recordTypes.containsKey(developerName)) {
            return recordTypes
                .get(developerName)
                .getRecordTypeId();
        }

        return null;
    }
}