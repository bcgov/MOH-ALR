/**********************************************************************************************
* @Author:      Accenture
* @Date:        06 Aug 2026
* @Description: Test class for VisitTriggerHandler, focused on updateRiskAssessmentEligibility().
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                06 Aug -  PHOCS-269         -  Accenture   -  test class for updateRiskAssessmentEligibility
***********************************************************************************************/
@isTest
public class VisitTriggerHandlerTest {

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Creates the shared Account, InspectionType, and Visit test data used across the
* updateRiskAssessmentEligibility() test methods. One completed PHOCS Inspection Visit is
* created per scenario: an eligible Routine visit, an eligible Routine Follow-up visit, an
* already-eligible account, an account with no InspectionType, an account with a non-qualifying
* InspectionType, and a visit with no AccountId.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @testSetup
    static void setupTestData() {
        Account routineAccount = new Account(Name = 'PHOCS Test Account - Routine', RiskAssessmentEligibility__c = false);
        Account followUpAccount = new Account(Name = 'PHOCS Test Account - FollowUp', RiskAssessmentEligibility__c = false);
        Account alreadyEligibleAccount = new Account(Name = 'PHOCS Test Account - AlreadyEligible', RiskAssessmentEligibility__c = true);
        Account noVisitTypeAccount = new Account(Name = 'PHOCS Test Account - NoVisitType', RiskAssessmentEligibility__c = false);
        Account wrongVisitTypeAccount = new Account(Name = 'PHOCS Test Account - WrongVisitType', RiskAssessmentEligibility__c = false);
        insert new List<Account>{ routineAccount, followUpAccount, alreadyEligibleAccount, noVisitTypeAccount, wrongVisitTypeAccount };

        InspectionType routineType = new InspectionType(Name = VisitTriggerHandler.VISIT_TYPE_ROUTINE);
        InspectionType followUpType = new InspectionType(Name = VisitTriggerHandler.VISIT_TYPE_ROUTINE_FOLLOW_UP);
        InspectionType adHocType = new InspectionType(Name = 'Ad-hoc');
        insert new List<InspectionType>{ routineType, followUpType, adHocType };

        Id phocsInspectionRecordTypeId = VisitTriggerHandler.recordTypePHOCSInspection;
        
        ContactPointAddress cpa = new ContactPointAddress(Name = 'Test Address', Street = '123 Test Lane',
                                                          City = 'Vancouver', State = 'BC', Country = 'Canada', PostalCode = 'M2H2E4');
        insert cpa;

        List<Visit> visits = new List<Visit>();
        visits.add(new Visit(AccountId = routineAccount.Id, VisitTypeId = routineType.Id, Status = 'planned', RecordTypeId = phocsInspectionRecordTypeId, PlaceId = cpa.Id, PlannedVisitStartTime = DateTime.now()));
        visits.add(new Visit(AccountId = followUpAccount.Id, VisitTypeId = followUpType.Id, Status = 'planned', RecordTypeId = phocsInspectionRecordTypeId, PlaceId = cpa.Id, PlannedVisitStartTime = DateTime.now()));
        visits.add(new Visit(AccountId = alreadyEligibleAccount.Id, VisitTypeId = routineType.Id, Status = 'planned', RecordTypeId = phocsInspectionRecordTypeId, PlaceId = cpa.Id, PlannedVisitStartTime = DateTime.now()));
        visits.add(new Visit(AccountId = noVisitTypeAccount.Id, VisitTypeId = null, Status = 'planned', RecordTypeId = phocsInspectionRecordTypeId, PlaceId = cpa.Id, PlannedVisitStartTime = DateTime.now()));
        visits.add(new Visit(AccountId = wrongVisitTypeAccount.Id, VisitTypeId = adHocType.Id, Status = 'planned', RecordTypeId = phocsInspectionRecordTypeId, PlaceId = cpa.Id, PlannedVisitStartTime = DateTime.now()));
        visits.add(new Visit(AccountId = null, VisitTypeId = routineType.Id, Status = 'planned', RecordTypeId = phocsInspectionRecordTypeId, PlaceId = cpa.Id, PlannedVisitStartTime = DateTime.now()));
        insert visits;

        for (Visit v : visits) {
            v.Status = 'Completed';
        }
        update visits;
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() for a completed Routine visit on an
* account that is not yet eligible, confirming RiskAssessmentEligibility__c is set to true.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_RoutineVisit_SetsAccountEligible() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - Routine' LIMIT 1];
        Visit visit = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];

        Test.startTest();
        VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>{ visit.Id });
        Test.stopTest();

        Account updatedAcc = [SELECT RiskAssessmentEligibility__c FROM Account WHERE Id = :acc.Id];
        Assert.isTrue(updatedAcc.RiskAssessmentEligibility__c, 'Account should become eligible after a completed Routine visit');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() for a completed Routine Follow-up
* visit on an account that is not yet eligible, confirming RiskAssessmentEligibility__c is set to true.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_RoutineFollowUpVisit_SetsAccountEligible() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - FollowUp' LIMIT 1];
        Visit visit = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];

        Test.startTest();
        VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>{ visit.Id });
        Test.stopTest();

        Account updatedAcc = [SELECT RiskAssessmentEligibility__c FROM Account WHERE Id = :acc.Id];
        Assert.isTrue(updatedAcc.RiskAssessmentEligibility__c, 'Account should become eligible after a completed Routine Follow-up visit');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() for an account that is already
* eligible, confirming the method does not error and the field remains true.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_AlreadyEligibleAccount_RemainsEligible() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - AlreadyEligible' LIMIT 1];
        Visit visit = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];

        Test.startTest();
        VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>{ visit.Id });
        Test.stopTest();

        Account updatedAcc = [SELECT RiskAssessmentEligibility__c FROM Account WHERE Id = :acc.Id];
        Assert.isTrue(updatedAcc.RiskAssessmentEligibility__c, 'Account should remain eligible when it was already eligible');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() for a visit with no VisitType,
* confirming the account is skipped and RiskAssessmentEligibility__c stays false.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_NoVisitType_AccountNotUpdated() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - NoVisitType' LIMIT 1];
        Visit visit = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];

        Test.startTest();
        VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>{ visit.Id });
        Test.stopTest();

        Account updatedAcc = [SELECT RiskAssessmentEligibility__c FROM Account WHERE Id = :acc.Id];
        Assert.isFalse(updatedAcc.RiskAssessmentEligibility__c, 'Account should not become eligible when the visit has no VisitType');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() for a visit whose VisitType is
* neither Routine nor Routine Follow-up, confirming RiskAssessmentEligibility__c stays false.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_NonQualifyingVisitType_AccountNotUpdated() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Account - WrongVisitType' LIMIT 1];
        Visit visit = [SELECT Id FROM Visit WHERE AccountId = :acc.Id LIMIT 1];

        Test.startTest();
        VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>{ visit.Id });
        Test.stopTest();

        Account updatedAcc = [SELECT RiskAssessmentEligibility__c FROM Account WHERE Id = :acc.Id];
        Assert.isFalse(updatedAcc.RiskAssessmentEligibility__c, 'Account should not become eligible for a non-qualifying VisitType such as Ad-hoc');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() for a visit with no AccountId,
* confirming the method completes without throwing an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_NoAccountId_DoesNotThrow() {
        Visit visit = [SELECT Id FROM Visit WHERE AccountId = null LIMIT 1];
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>{ visit.Id });
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'A visit with no AccountId should be skipped, not throw');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() with an empty set of inspection Ids,
* confirming the method completes without querying or updating any accounts.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_EmptySet_DoesNotThrow() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            VisitTriggerHandler.updateRiskAssessmentEligibility(new Set<Id>());
        } catch (Exception ex) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isFalse(exceptionThrown, 'An empty set of inspection Ids should be a no-op, not throw');
    }

/**
* @author: Accenture
* @date: 06 Aug 2026
* @description: Covers updateRiskAssessmentEligibility() bulk behaviour by passing every
* completed PHOCS Inspection Visit Id from test setup in a single call, confirming only the
* qualifying accounts (Routine and Routine Follow-up, not already eligible) get updated.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRiskAssessmentEligibility_BulkVisits_UpdatesOnlyQualifyingAccounts() {
        List<Visit> allVisits = [SELECT Id FROM Visit];
        Set<Id> allVisitIds = new Map<Id, Visit>(allVisits).keySet();

        Test.startTest();
        VisitTriggerHandler.updateRiskAssessmentEligibility(allVisitIds);
        Test.stopTest();

        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account acc : [SELECT Name, RiskAssessmentEligibility__c FROM Account]) {
            accountsByName.put(acc.Name, acc);
        }

        Assert.isTrue(accountsByName.get('PHOCS Test Account - Routine').RiskAssessmentEligibility__c, 'Routine account should be eligible');
        Assert.isTrue(accountsByName.get('PHOCS Test Account - FollowUp').RiskAssessmentEligibility__c, 'Routine Follow-up account should be eligible');
        Assert.isTrue(accountsByName.get('PHOCS Test Account - AlreadyEligible').RiskAssessmentEligibility__c, 'Already-eligible account should remain eligible');
        Assert.isFalse(accountsByName.get('PHOCS Test Account - NoVisitType').RiskAssessmentEligibility__c, 'No-VisitType account should remain ineligible');
        Assert.isFalse(accountsByName.get('PHOCS Test Account - WrongVisitType').RiskAssessmentEligibility__c, 'Wrong-VisitType account should remain ineligible');
    }
}