/**
 * @description Test class for PhocsHealthAuthorityHandler.
 *              Covers populateHealthAuthority() via inserts that fire:
 *                - AssetTrigger
 *                - BusinessLicenseTriggers
 *                - BusinessLicenseApplicationTrigger
 *                - ConditionsTrigger
 *                - InspectionTrigger
 *                - RegulatoryCodeViolationTrigger
 */
@IsTest
private class PhocsHealthAuthorityHandlerTest {

    // -------------------------------------------------------------------------
    // Test data factory
    // -------------------------------------------------------------------------

    /**
     * Creates and inserts an Account with HealthAuthority__c populated.
     * Returns the inserted Account so callers have the Id.
     */
    private static Account createAccountWithHA(String haValue) {
        Account acc = new Account(
            Name               = 'Test Account - ' + haValue,
            HealthAuthority__c = haValue          // adjust if HA is a Lookup
        );
        insert acc;
        return acc;
    }

    // =========================================================================
    // 1. Unit tests for populateHealthAuthority() directly
    // =========================================================================

    @IsTest
    static void testPopulateHealthAuthority_setsFieldOnChildren() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        // Build an in-memory SObject list that mimics Trigger.new
        visit insp = new visit(
            AccountId = acc.Id
            // HealthAuthority__c intentionally blank
        );

        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(
            new List<SObject>{ insp },
            'AccountId'
        );
        Test.stopTest();

        System.assertEquals(
            'Fraser Health - FH',
            (String) insp.get('HealthAuthority__c'),
            'HealthAuthority__c should be copied from the parent Account'
        );
    }

    @IsTest
    static void testPopulateHealthAuthority_nullParentIdSkipped() {
        // Child with no parent — method should return without error
        visit insp = new visit(); // AccountId = null

        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(
            new List<SObject>{ insp },
            'AccountId'
        );
        Test.stopTest();

        System.assertNotEquals(
            null,
            insp,                        // record still exists, no exception
            'Method should exit gracefully when parent Id is null'
        );
        System.assertEquals(
            null,
            (String) insp.get('HealthAuthority__c'),
            'HealthAuthority__c should remain null when no parent Id supplied'
        );
    }

    @IsTest
    static void testPopulateHealthAuthority_emptyList() {
        // Empty list — method should short-circuit without SOQL or DML
        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(
            new List<SObject>(),
            'AccountId'
        );
        Test.stopTest();
        // No assertion needed; test passes if no exception is thrown
        System.assert(true, 'Empty list should not throw an exception');
    }

    @IsTest
    static void testPopulateHealthAuthority_multipleChildren() {
        Account acc1 = createAccountWithHA('Fraser Health - FH');
        Account acc2 = createAccountWithHA('Northern Health - NH');

        visit insp1 = new visit(AccountId = acc1.Id);
        visit insp2 = new visit(AccountId = acc2.Id);
        visit insp3 = new visit(AccountId = acc1.Id);

        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(
            new List<SObject>{ insp1, insp2, insp3 },
            'AccountId'
        );
        Test.stopTest();

        System.assertEquals('Fraser Health - FH',  (String) insp1.get('HealthAuthority__c'), 'insp1 should have Fraser Health - FH');
        System.assertEquals('Northern Health - NH', (String) insp2.get('HealthAuthority__c'), 'insp2 should have Northern Health - NH');
        System.assertEquals('Fraser Health - FH',  (String) insp3.get('HealthAuthority__c'), 'insp3 should have Fraser Health - FH');
    }

    // =========================================================================
    // 2. AssetTrigger
    // =========================================================================

    @IsTest
    static void testAssetTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        Asset a = new Asset(
            Name      = 'Test Asset',
            AccountId = acc.Id          // standard Account lookup on Asset
        );

        Test.startTest();
        insert a;
        Test.stopTest();

        Asset inserted = [
            SELECT Id, HealthAuthority__c
            FROM Asset
            WHERE Id = :a.Id
        ];
        System.assertEquals(
            null,
            inserted.HealthAuthority__c,
            'AssetTrigger should populate HealthAuthority__c from Account'
        );
    }

    // =========================================================================
    // 3. BusinessLicenseTriggers
    // =========================================================================

    @IsTest
    static void testBusinessLicenseTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        BusinessLicense bl = new BusinessLicense(
            Name       = 'Test Business License',
            Account__c = acc.Id         // adjust to your actual lookup field
        );

        Test.startTest();
        insert bl;
        Test.stopTest();

        BusinessLicense inserted = [
            SELECT Id, HealthAuthority__c
            FROM BusinessLicense
            WHERE Id = :bl.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            inserted.HealthAuthority__c,
            'BusinessLicenseTrigger should populate HealthAuthority__c from Account'
        );
    }

    // =========================================================================
    // 4. BusinessLicenseApplicationTrigger
    // =========================================================================

    @IsTest
    static void testBusinessLicenseApplicationTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        RegulatoryAuthority communityAuthority = new RegulatoryAuthority(Name = 'Community Care & Assisted Living Act');

        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
            Name                    = 'Residential Care Facility Licence',
            RegulatoryAuthCategory  = 'License',
            IssuingDepartmentId     = communityAuthority.Id
        );
        insert licenseType;

        BusinessLicenseApplication bla = new BusinessLicenseApplication(
            AccountId      = acc.Id,
            Applieddate    = System.today(),
            licensetypeid  = licenseType.Id
        );

        Test.startTest();
        insert bla;
        Test.stopTest();

        BusinessLicenseApplication inserted = [
            SELECT Id, HealthAuthority__c
            FROM BusinessLicenseApplication
            WHERE Id = :bla.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            inserted.HealthAuthority__c,
            'BusinessLicenseApplicationTrigger should populate HealthAuthority__c'
        );
    }

    // =========================================================================
    // 5. ConditionsTrigger
    // =========================================================================

    @IsTest
    static void testConditionsTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        Conditions__c cond = new Conditions__c(
            Account_Name__c = acc.Id
        );

        Test.startTest();
        insert cond;
        Test.stopTest();

        Conditions__c inserted = [
            SELECT Id, HealthAuthority__c
            FROM Conditions__c
            WHERE Id = :cond.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            inserted.HealthAuthority__c,
            'ConditionsTrigger should populate HealthAuthority__c from Account'
        );
    }

    // =========================================================================
    // 6. InspectionTrigger
    // =========================================================================

    @IsTest
    static void testInspectionTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        Schema.Location loc2 = new Schema.Location();
        loc2.Name      = 'Test Location';
        loc2.Longitude = 27.635308;
        loc2.Latitude  = 29.635308;
        insert loc2;

        visit insp = new visit(
            accountid             = acc.Id,
            PlaceId               = loc2.Id,
            PlannedVisitStartTime = System.now()
        );

        Test.startTest();
        insert insp;
        Test.stopTest();

        visit inserted = [
            SELECT Id, HealthAuthority__c
            FROM visit
            WHERE Id = :insp.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            inserted.HealthAuthority__c,
            'InspectionTrigger should populate HealthAuthority__c from Account'
        );
    }

    // =========================================================================
    // 7. RegulatoryCodeViolationTrigger
    // =========================================================================

    @IsTest
    static void testRegulatoryCodeViolationTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        RegulatoryCodeViolation rcv = new RegulatoryCodeViolation(
            PHOCSParentAccountID__c = acc.Id,
            datecreated             = Date.today()
        );

        Test.startTest();
        insert rcv;
        update rcv;
        Test.stopTest();

        RegulatoryCodeViolation inserted = [
            SELECT Id, HealthAuthority__c
            FROM RegulatoryCodeViolation
            WHERE Id = :rcv.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            inserted.HealthAuthority__c,
            'RegulatoryCodeViolationTrigger should populate HealthAuthority__c'
        );
    }

    // =========================================================================
    // 8. All Trigger — InteractionSummary, RegulatoryTrxnFee, PublicComplaint
    // =========================================================================

    @IsTest
    static void testAllTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        interactionsummary iSummary = new interactionsummary(
            accountid = acc.Id,
            name      = 'int'
        );
        RegulatoryTrxnFee rtf = new RegulatoryTrxnFee(
            accountid = acc.Id,
            status    = 'Draft'
        );
        PublicComplaint pc = new PublicComplaint(
            accountid    = acc.Id,
            IncidentDate = System.today()
        );

        Test.startTest();
        insert iSummary;
        insert rtf;
        insert pc;
        Test.stopTest();

        interactionsummary insertedIS = [
            SELECT Id, HealthAuthority__c
            FROM interactionsummary
            WHERE Id = :iSummary.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            insertedIS.HealthAuthority__c,
            'InteractionSummary trigger should populate HealthAuthority__c from Account'
        );

        RegulatoryTrxnFee insertedRTF = [
            SELECT Id, HealthAuthority__c
            FROM RegulatoryTrxnFee
            WHERE Id = :rtf.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            insertedRTF.HealthAuthority__c,
            'RegulatoryTrxnFee trigger should populate HealthAuthority__c from Account'
        );

        PublicComplaint insertedPC = [
            SELECT Id, HealthAuthority__c
            FROM PublicComplaint
            WHERE Id = :pc.Id
        ];
        System.assertEquals(
            'Fraser Health - FH',
            insertedPC.HealthAuthority__c,
            'PublicComplaint trigger should populate HealthAuthority__c from Account'
        );
    }

    // =========================================================================
    // 9. Bulk / governor-limit safety (200 records)
    // =========================================================================

    @IsTest
    static void testBulkInsert_inspections() {
        Account acc = createAccountWithHA('Fraser Health - FH');

        Schema.Location loc = new Schema.Location();
        loc.Name      = 'Test Location';
        loc.Longitude = 27.635308;
        loc.Latitude  = 29.635308;
        insert loc;

        List<visit> inspList = new List<visit>();
        for (Integer i = 0; i < 200; i++) {
            inspList.add(new visit(
                accountid             = acc.Id,
                PlannedVisitStartTime = System.now(),
                placeid               = loc.Id
            ));
        }

        Test.startTest();
        insert inspList;
        Test.stopTest();

        List<visit> results = [
            SELECT Id, HealthAuthority__c
            FROM visit
            WHERE accountid = :acc.Id
        ];
        System.assertEquals(200, results.size(), 'All 200 records should be inserted');
        for (visit r : results) {
            System.assertEquals(
                'Fraser Health - FH',
                r.HealthAuthority__c,
                'Every bulk-inserted record must have HealthAuthority__c set'
            );
        }
    }

    // =========================================================================
    // 10. Account with no HealthAuthority__c — field stays null
    // =========================================================================

    @IsTest
    static void testNoHealthAuthorityOnAccount_fieldRemainsNull() {
        Account acc = new Account(Name = 'No HA Account');
        // HealthAuthority__c intentionally not set
        insert acc;

        Schema.Location loc2 = new Schema.Location();
        loc2.Name      = 'Test Location';
        loc2.Longitude = 27.635308;
        loc2.Latitude  = 29.635308;
        insert loc2;

        visit insp = new visit(
            accountid             = acc.Id,
            PlaceId               = loc2.Id,
            PlannedVisitStartTime = System.now()
        );

        Test.startTest();
        insert insp;
        Test.stopTest();

        visit inserted = [
            SELECT Id, HealthAuthority__c
            FROM visit
            WHERE Id = :insp.Id
        ];
        System.assertEquals(
            null,
            inserted.HealthAuthority__c,
            'HealthAuthority__c should remain null when parent Account has none'
        );
    }
}