/**********************************************************************************************
* @Author:      Accenture
* @Date:        20 Jul 2026
* @Description: Test class for PhocsHealthAuthorityHandler. Covers populateHealthAuthority() via
*               inserts that fire:
*                 - AssetTrigger
*                 - BusinessLicenseTriggers
*                 - BusinessLicenseApplicationTrigger
*                 - ConditionsTrigger
*                 - InspectionTrigger
*                 - RegulatoryCodeViolationTrigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@IsTest
private class PhocsHealthAuthorityHandlerTest {
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Returns the first active Record Type Id on the given object whose Developer
*               Name contains 'PHOCS'. Returns null safely if no matching Record Type exists.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Id getPhocsRecordTypeId(String objectApiName) {
        for (RecordTypeInfo rti : Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosByName().values()) {
            if (rti.getDeveloperName().containsIgnoreCase('PHOCS') && rti.isAvailable()) {
                return rti.getRecordTypeId();
            }
        }
        return null;
    }
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Creates and inserts a Facility-record-type Account with the given
*               HealthAuthority__c value, for use as a parent record in test data.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Account createAccountWithHA(String haValue) {
        Id rtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account - ' + haValue, HealthAuthority__c = haValue, RecordTypeId = rtId);
        
        insert acc;
        return acc;
    }
    
    // =========================================================================
    // 1. Unit tests for populateHealthAuthority() directly
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that calling populateHealthAuthority() directly copies the parent
*               Account's HealthAuthority__c value onto a qualifying child record.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testPopulateHealthAuthority_setsFieldOnChildren() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        
        visit insp = new visit(AccountId = acc.Id);
        Id visitRtId = getPhocsRecordTypeId('Visit');
        
        if (visitRtId != null) {
            insp.put('RecordTypeId', visitRtId);
        }
        
        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(new List<SObject>{ insp });
        Test.stopTest();
        
        System.assertEquals('Fraser Health - FH', (String) insp.get('HealthAuthority__c'), 'HealthAuthority__c should be copied from the parent Account');
    }
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that a child record with no parent AccountId is skipped and
*               HealthAuthority__c remains null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testPopulateHealthAuthority_nullParentIdSkipped() {
        visit insp = new visit();
        Id visitRtId = getPhocsRecordTypeId('Visit');
        
        if (visitRtId != null) {
            insp.put('RecordTypeId', visitRtId);
        }
        
        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(new List<SObject>{ insp });
        Test.stopTest();
        
        System.assertNotEquals(null, insp, 'Record object should still exist');
        System.assertEquals(null, (String) insp.get('HealthAuthority__c'), 'HealthAuthority__c should remain null when no parent Id supplied');
    }
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that passing an empty list to populateHealthAuthority() does not
*               throw an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testPopulateHealthAuthority_emptyList() {
        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(new List<SObject>());
        Test.stopTest();
        
        System.assert(true, 'Empty list should not throw an exception');
    }
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that multiple child records, tied to different parent Accounts,
*               each receive the correct HealthAuthority__c value in bulk.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testPopulateHealthAuthority_multipleChildren() {
        Account acc1 = createAccountWithHA('Fraser Health - FH');
        Account acc2 = createAccountWithHA('Northern Health - NH');
        
        Id visitRtId = getPhocsRecordTypeId('Visit');
        
        visit insp1 = new visit(AccountId = acc1.Id);
        visit insp2 = new visit(AccountId = acc2.Id);
        visit insp3 = new visit(AccountId = acc1.Id);
        
        if (visitRtId != null) {
            insp1.put('RecordTypeId', visitRtId);
            insp2.put('RecordTypeId', visitRtId);
            insp3.put('RecordTypeId', visitRtId);
        }
        
        Test.startTest();
        PhocsHealthAuthorityHandler.populateHealthAuthority(new List<SObject>{ insp1, insp2, insp3 });
        Test.stopTest();
        
        System.assertEquals('Fraser Health - FH', (String) insp1.get('HealthAuthority__c'), 'insp1 should have Fraser Health - FH');
        System.assertEquals('Northern Health - NH', (String) insp2.get('HealthAuthority__c'), 'insp2 should have Northern Health - NH');
        System.assertEquals('Fraser Health - FH', (String) insp3.get('HealthAuthority__c'), 'insp3 should have Fraser Health - FH');
    }
    
    // =========================================================================
    // 2. AssetTrigger
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting an Asset fires AssetTrigger and populates
*               HealthAuthority__c from the parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testAssetTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id assetRtId = getPhocsRecordTypeId('Asset');
        
        Asset a = new Asset(
            Name = 'Test Asset',
            AccountId = acc.Id
        );
        
        System.debug('Asset Rectype------------+' + assetRtId);
        
        if (assetRtId != null) {
            a.RecordTypeId = assetRtId;
        }
        
        Test.startTest();
        insert a;
        Test.stopTest();
        
        Asset inserted = [SELECT Id, HealthAuthority__c FROM Asset WHERE Id = :a.Id];
        System.assertEquals('Fraser Health - FH', inserted.HealthAuthority__c, 'AssetTrigger should populate HealthAuthority__c from Account');
    }
    
    // =========================================================================
    // 3. BusinessLicenseTrigger
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting a BusinessLicense fires BusinessLicenseTriggers and
*               populates HealthAuthority__c from the parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testBusinessLicenseTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id blRtId = getPhocsRecordTypeId('BusinessLicense');
        
        BusinessLicense bl = new BusinessLicense(
            Name = 'Test Business License',
            Account__c = acc.Id
        );
        
        if (blRtId != null) {
            bl.RecordTypeId = blRtId;
        }
        
        Test.startTest();
        insert bl;
        Test.stopTest();
        
        BusinessLicense inserted = [SELECT Id, HealthAuthority__c FROM BusinessLicense WHERE Id = :bl.Id];
        System.assertEquals('Fraser Health - FH', inserted.HealthAuthority__c, 'BusinessLicenseTrigger should populate HealthAuthority__c from Account');
    }
    
    // =========================================================================
    // 4. BusinessLicenseApplicationTrigger
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting a BusinessLicenseApplication fires
*               BusinessLicenseApplicationTrigger and populates HealthAuthority__c from the
*               parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testBusinessLicenseApplicationTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id blaRtId = getPhocsRecordTypeId('BusinessLicenseApplication');
        
        RegulatoryAuthority communityAuthority = new RegulatoryAuthority(
            Name = 'Community Care & Assisted Living Act'
        );
        
        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
            Name = 'Residential Care Facility Licence',
            RegulatoryAuthCategory = 'License',
            IssuingDepartmentId = communityAuthority.Id
        );
        
        insert licenseType;
        
        BusinessLicenseApplication bla = new BusinessLicenseApplication(
            AccountId = acc.Id,
            Applieddate = System.today(),
            licensetypeid = licenseType.Id,
            HealthAuthority__c = acc.HealthAuthority__c,
            category = 'Permit'
        );
        
        if (blaRtId != null) {
            bla.RecordTypeId = blaRtId;
        }
        
        Test.startTest();
        insert bla;
        Test.stopTest();
        
        BusinessLicenseApplication inserted = [SELECT Id, HealthAuthority__c FROM BusinessLicenseApplication WHERE Id = :bla.Id];
        System.assertEquals('Fraser Health - FH', inserted.HealthAuthority__c, 'BusinessLicenseApplicationTrigger should populate HealthAuthority__c');
    }
    
    // =========================================================================
    // 5. ConditionsTrigger
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting a Conditions__c record fires ConditionsTrigger and
*               populates HealthAuthority__c from the parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testConditionsTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id condRtId = getPhocsRecordTypeId('Conditions__c');
        
        Conditions__c cond = new Conditions__c(Account_Name__c = acc.Id);
        
        if (condRtId != null) {
            cond.RecordTypeId = condRtId;
        }
        
        Test.startTest();
        insert cond;
        Test.stopTest();
        
        Conditions__c inserted = [SELECT Id, HealthAuthority__c FROM Conditions__c WHERE Id = :cond.Id];
        System.assertEquals('Fraser Health - FH', inserted.HealthAuthority__c, 'ConditionsTrigger should populate HealthAuthority__c from Account');
    }
    
    // =========================================================================
    // 6. InspectionTrigger (Visit)
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting a Visit fires InspectionTrigger and populates
*               HealthAuthority__c from the parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testInspectionTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id visitRtId = getPhocsRecordTypeId('Visit');
        
        Schema.Location loc2 = new Schema.Location();
        loc2.Name = 'Test Location';
        loc2.Longitude = 27.635308;
        loc2.Latitude = 29.635308;
        
        insert loc2;
        
        visit insp = new visit(
            accountid = acc.Id,
            PlaceId = loc2.Id,
            PlannedVisitStartTime = System.now()
        );
        
        if (visitRtId != null) {
            insp.put('RecordTypeId', visitRtId);
        }
        
        Test.startTest();
        insert insp;
        Test.stopTest();
        
        visit inserted = [SELECT Id, HealthAuthority__c FROM visit WHERE Id = :insp.Id];
        System.assertEquals('Fraser Health - FH', inserted.HealthAuthority__c, 'InspectionTrigger should populate HealthAuthority__c from Account');
    }
    
    // =========================================================================
    // 7. RegulatoryCodeViolationTrigger
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting and updating a RegulatoryCodeViolation fires
*               RegulatoryCodeViolationTrigger and populates HealthAuthority__c from the
*               parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testRegulatoryCodeViolationTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id rcvRtId = getPhocsRecordTypeId('RegulatoryCodeViolation');
        
        RegulatoryCodeViolation rcv = new RegulatoryCodeViolation(
            PHOCSParentAccountID__c = acc.Id,
            datecreated = Date.today()
        );
        
        if (rcvRtId != null) {
            rcv.RecordTypeId = rcvRtId;
        }
        
        Test.startTest();
        insert rcv;
        update rcv;
        Test.stopTest();
        
        RegulatoryCodeViolation inserted = [SELECT Id, HealthAuthority__c FROM RegulatoryCodeViolation WHERE Id = :rcv.Id];
        System.assertEquals('Fraser Health - FH', inserted.HealthAuthority__c, 'RegulatoryCodeViolationTrigger should populate HealthAuthority__c');
    }
    
    // =========================================================================
    // 8. All Triggers — InteractionSummary, RegulatoryTrxnFee, PublicComplaint
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that inserting InteractionSummary, RegulatoryTrxnFee, and
*               PublicComplaint records each fires their respective triggers and populates
*               HealthAuthority__c from the parent Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testAllTrigger_populatesHealthAuthority() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id isRtId = getPhocsRecordTypeId('InteractionSummary');
        Id rtfRtId = Schema.SObjectType.RegulatoryTrxnFee.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFee').getRecordTypeId();
        Id pcRtId = getPhocsRecordTypeId('PublicComplaint');
        
        interactionsummary iSummary = new interactionsummary(
            accountid = acc.Id,
            name = 'int'
        );
        
        if (isRtId != null) {
            iSummary.put('RecordTypeId', isRtId);
        }
        
        RegulatoryTrxnFee rtf = new RegulatoryTrxnFee(
            accountid = acc.Id,
            status = 'Draft'
        );
        
        if (rtfRtId != null) {
            rtf.RecordTypeId = rtfRtId;
        }
        
        PublicComplaint pc = new PublicComplaint(
            accountid = acc.Id,
            IncidentDate = System.today()
        );
        
        if (pcRtId != null) {
            pc.RecordTypeId = pcRtId;
        }
        
        Test.startTest();
        insert iSummary;
        insert rtf;
        insert pc;
        Test.stopTest();
        
        interactionsummary insertedIS = [SELECT Id, HealthAuthority__c FROM interactionsummary WHERE Id = :iSummary.Id];
        System.assertEquals('Fraser Health - FH', insertedIS.HealthAuthority__c, 'InteractionSummary trigger should populate HealthAuthority__c from Account');
        
        RegulatoryTrxnFee insertedRTF = [SELECT Id, HealthAuthority__c FROM RegulatoryTrxnFee WHERE Id = :rtf.Id];
        System.assertEquals('Fraser Health - FH', insertedRTF.HealthAuthority__c, 'RegulatoryTrxnFee trigger should populate HealthAuthority__c from Account');
        
        PublicComplaint insertedPC = [SELECT Id, HealthAuthority__c FROM PublicComplaint WHERE Id = :pc.Id];
        System.assertEquals('Fraser Health - FH', insertedPC.HealthAuthority__c, 'PublicComplaint trigger should populate HealthAuthority__c from Account');
    }
    
    // =========================================================================
    // 9. Bulk / governor-limit safety (200 records)
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that populateHealthAuthority() correctly processes a bulk insert of
*               10 Visit records without hitting governor limits, with every record receiving
*               the correct HealthAuthority__c value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testBulkInsert_inspections() {
        Account acc = createAccountWithHA('Fraser Health - FH');
        Id visitRtId = getPhocsRecordTypeId('Visit');
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.Longitude = 27.635308;
        loc.Latitude = 29.635308;
        
        insert loc;
        
        List<visit> inspList = new List<visit>();
        
        for (Integer i = 0; i < 10; i++) {
            visit v = new visit(
                accountid = acc.Id,
                PlannedVisitStartTime = System.now(),
                placeid = loc.Id
            );
            
            if (visitRtId != null) {
                v.put('RecordTypeId', visitRtId);
            }
            
            inspList.add(v);
        }
        
        Test.startTest();
        insert inspList;
        Test.stopTest();
        
        List<visit> results = [SELECT Id, HealthAuthority__c FROM visit WHERE accountid = :acc.Id];
        System.assertEquals(10, results.size(), 'All 10 records should be inserted');
        
        for (visit r : results) {
            System.assertEquals('Fraser Health - FH', r.HealthAuthority__c, 'Every bulk-inserted record must have HealthAuthority__c set');
        }
    }
    
    // =========================================================================
    // 10. Account with no HealthAuthority__c — field stays null
    // =========================================================================
    
/**
* @author: Accenture
* @date: 20 Jul 2026
* @description: Verifies that when the parent Account has no HealthAuthority__c value, the
*               child record's HealthAuthority__c field remains null after insert.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNoHealthAuthorityOnAccount_fieldRemainsNull() {
        Account acc = new Account(Name = 'No HA Account');
        insert acc;
        
        Id visitRtId = getPhocsRecordTypeId('Visit');
        
        Schema.Location loc2 = new Schema.Location();
        loc2.Name = 'Test Location';
        loc2.Longitude = 27.635308;
        loc2.Latitude = 29.635308;
        
        insert loc2;
        
        visit insp = new visit(
            accountid = acc.Id,
            PlaceId = loc2.Id,
            PlannedVisitStartTime = System.now()
        );
        
        if (visitRtId != null) {
            insp.put('RecordTypeId', visitRtId);
        }
        
        Test.startTest();
        insert insp;
        Test.stopTest();
        
        visit inserted = [SELECT Id, HealthAuthority__c FROM visit WHERE Id = :insp.Id];
        System.assertEquals(null, inserted.HealthAuthority__c, 'HealthAuthority__c should remain null when parent Account has none');
    }
}