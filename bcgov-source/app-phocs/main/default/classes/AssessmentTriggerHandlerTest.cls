/**********************************************************************************************
 * @Author:      Accenture
 * @Date:        17 Sep 2026
 * @Description: The purpose of this class is to cover code coverage of AssessmentTriggerHandler -
 *               RAT-driven Routine/MTS inspection generation (AC#1-AC#4) and frequency-change
 *               recalculation (AC#7).
 * @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
 *               17 Sep -  EHIS-5027         -  Deepak      -  Initial test class
 ***********************************************************************************************/
@isTest
public class AssessmentTriggerHandlerTest {

    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public static Id recordTypePHOCSInspectionType = Schema.SObjectType.InspectionType.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionType').getRecordTypeId();
    public static Id recordTypePHOCSAssessment = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
    public static Id recordTypeFacilityAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();

    private static final String PACIFIC_TIME_ZONE = 'America/Los_Angeles';

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Creates the common test data - a Facility Account of the supplied type, a
 *              Location, Routine and MTS InspectionType records, and a completed Routine
 *              Inspection that acts as the RAT-originating inspection and schedule anchor.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, Id> createTestData(String facilityType, Datetime actualStartTime) {
        Account facility = new Account(Name = 'RAT Test Facility', Type = facilityType, RecordTypeId = recordTypeFacilityAccount);
        insert facility;

        Schema.Location loc = new Schema.Location(Name = 'RAT Test Location', Longitude = 27.635308, Latitude = 29.635308);
        insert loc;

        List<InspectionType> inspectionTypes = new List<InspectionType>{
            new InspectionType(Name = 'Routine', Description = 'Test', RecordTypeId = recordTypePHOCSInspectionType),
            new InspectionType(Name = 'MTS (Minor Test Shopper)', Description = 'Test', RecordTypeId = recordTypePHOCSInspectionType)
        };
        insert inspectionTypes;

        // A Visit cannot be inserted directly as Completed, so insert it Planned first and then
        // move it to Completed with its Actual Visit Start Time populated.
        Visit originatingInspection = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = facility.Id, PlaceId = loc.Id,
                                                PlannedVisitStartTime = actualStartTime, RecordTypeId = recordTypePHOCSInspection,
                                                VisitTypeId = inspectionTypes[0].Id);
        insert originatingInspection;

        originatingInspection.Status = 'Completed';
        originatingInspection.ActualVisitStartTime = actualStartTime;
        update originatingInspection;

        Map<String, Id> dataMap = new Map<String, Id>();
        dataMap.put('facilityId', facility.Id);
        dataMap.put('locationId', loc.Id);
        dataMap.put('routineTypeId', inspectionTypes[0].Id);
        dataMap.put('mtsTypeId', inspectionTypes[1].Id);
        dataMap.put('originatingInspectionId', originatingInspection.Id);

        return dataMap;
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Builds an Assessment record for the supplied facility, originating inspection
 *              and frequencies.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Assessment buildAssessment(Map<String, Id> dataMap, String assessmentType, String assessmentStatus, String routineFrequency, String mtsFrequency) {
        return new Assessment(
            Name = 'RAT Test Assessment',
            RecordTypeId = recordTypePHOCSAssessment,
            AccountId = dataMap.get('facilityId'),
            ResponseContextId = dataMap.get('originatingInspectionId'),
            Type = assessmentType,
            AssessmentStatus = assessmentStatus,
            MinimumInspectionFrequency__c = routineFrequency,
            MTSInspectionFrequency__c = mtsFrequency
        );
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Returns the generated inspections for a facility and inspection type, excluding
 *              the originating inspection, ordered chronologically.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static List<Visit> getGeneratedInspections(Map<String, Id> dataMap, Id visitTypeId) {
        return [SELECT Id, Status, PlannedVisitStartTime, AccountId, PlaceId, VisitTypeId, RATGenerated__c FROM Visit
                WHERE AccountId = :dataMap.get('facilityId') AND VisitTypeId = :visitTypeId AND Id != :dataMap.get('originatingInspectionId')
                ORDER BY PlannedVisitStartTime ASC];
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Formats a Datetime as a Pacific Time yyyy-MM-dd HH:mm string, so assertions are
 *              independent of the running user's time zone.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String formatPacific(Datetime value) {
        return value.format('yyyy-MM-dd HH:mm', PACIFIC_TIME_ZONE);
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#1/AC#2 and the user story's Example 1 - a completed Routine Inspection
 *              plus a 2-per-year frequency generates two Routine inspections six and twelve
 *              months after the completed inspection, each Planned, RAT-generated and defaulted
 *              to 12:00 PM Pacific.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_TwoInspectionsPerYear_CreatesTwoRoutineInspections() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '2 inspections per year', null);
        Test.stopTest();

        List<Visit> generated = getGeneratedInspections(dataMap, dataMap.get('routineTypeId'));

        Assert.areEqual(2, generated.size(), 'Two Routine inspections should be generated for a 2-per-year frequency.');
        Assert.areEqual(formatPacific(anchor).substring(0, 10), anchor.format('yyyy-MM-dd', PACIFIC_TIME_ZONE), 'Anchor formatting sanity check.');

        Date anchorDate = anchor.date();
        Assert.areEqual(anchorDate.addMonths(6).format(), generated[0].PlannedVisitStartTime.date().format(), 'First inspection should be six months after the completed inspection.');
        Assert.areEqual(anchorDate.addMonths(12).format(), generated[1].PlannedVisitStartTime.date().format(), 'Second inspection should be twelve months after the completed inspection.');

        for (Visit generatedInspection : generated) {
            Assert.areEqual('Planned', generatedInspection.Status, 'Generated inspections should be Planned.');
            Assert.isTrue(generatedInspection.RATGenerated__c, 'Generated inspections should be flagged as RAT generated.');
            Assert.areEqual(dataMap.get('facilityId'), generatedInspection.AccountId, 'Generated inspections should be linked to the facility.');
            Assert.areEqual(dataMap.get('locationId'), generatedInspection.PlaceId, 'Generated inspections should carry the facility location.');
            Assert.areEqual('12:00', formatPacific(generatedInspection.PlannedVisitStartTime).substring(11), 'Planned Start Time should default to 12:00 PM Pacific.');
        }
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#2 - a 4-per-year frequency generates four Routine inspections three
 *              months apart.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_FourInspectionsPerYear_CreatesFourRoutineInspections() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '4 inspections per year', null);
        Test.stopTest();

        List<Visit> generated = getGeneratedInspections(dataMap, dataMap.get('routineTypeId'));
        Date anchorDate = anchor.date();

        Assert.areEqual(4, generated.size(), 'Four Routine inspections should be generated for a 4-per-year frequency.');
        Assert.areEqual(anchorDate.addMonths(3).format(), generated[0].PlannedVisitStartTime.date().format(), 'Inspections should be three months apart.');
        Assert.areEqual(anchorDate.addMonths(12).format(), generated[3].PlannedVisitStartTime.date().format(), 'The final inspection should be twelve months out.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#3/AC#4 - a Tobacco and Vapour facility generates both Routine and MTS
 *              inspections per their respective frequencies.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_TobaccoAndVapour_GeneratesRoutineAndMtsInspections() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Tobacco and Vapour', anchor);

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '1 inspection per year', '3 inspections per year');
        Test.stopTest();

        List<Visit> routineInspections = getGeneratedInspections(dataMap, dataMap.get('routineTypeId'));
        List<Visit> mtsInspections = getGeneratedInspections(dataMap, dataMap.get('mtsTypeId'));
        Date anchorDate = anchor.date();

        Assert.areEqual(1, routineInspections.size(), 'One Routine inspection should be generated for a 1-per-year frequency.');
        Assert.areEqual(3, mtsInspections.size(), 'Three MTS inspections should be generated for a 3x MTS/year frequency.');
        Assert.areEqual(anchorDate.addMonths(4).format(), mtsInspections[0].PlannedVisitStartTime.date().format(), 'MTS inspections should be four months apart.');
        Assert.isTrue(mtsInspections[0].RATGenerated__c, 'MTS inspections should be flagged as RAT generated.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#3 - facilities other than Tobacco and Vapour must not receive MTS
 *              inspection records even when an MTS frequency is populated.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_NonTobaccoFacility_DoesNotGenerateMtsInspections() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '1 inspection per year', '3 inspections per year');
        Test.stopTest();

        Assert.areEqual(0, getGeneratedInspections(dataMap, dataMap.get('mtsTypeId')).size(), 'Non-Tobacco facilities should not receive MTS inspections.');
        Assert.areEqual(1, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'Routine inspections should still be generated.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers the filtering logic - an Assessment that is not Completed generates no
 *              inspection records.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_AssessmentNotCompleted_GeneratesNothing() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk Assessment', 'In Progress', '2 inspections per year', null);
        Test.stopTest();

        Assert.areEqual(0, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'No inspections should be generated for an Assessment that is not Completed.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers the filtering logic - an Assessment whose Type is neither Risk Assessment
 *              nor Risk re-assessment generates no inspection records.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_NonQualifyingAssessmentType_GeneratesNothing() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        Assessment assessment = buildAssessment(dataMap, 'Risk Assessment', 'Completed', '2 inspections per year', null);
        assessment.Type = 'Some Non Qualifying Type';

        Test.startTest();
        AssessmentTriggerHandler.afterInsert(new List<Assessment>{ assessment });
        Test.stopTest();

        Assert.areEqual(0, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'No inspections should be generated for a non-qualifying Assessment Type.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers the ResponseContextId guard - an Assessment with no originating Inspection
 *              generates no inspection records.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGeneration_NullResponseContext_GeneratesNothing() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        Assessment assessment = buildAssessment(dataMap, 'Risk Assessment', 'Completed', '2 inspections per year', null);
        assessment.ResponseContextId = null;

        Test.startTest();
        insert assessment;
        Test.stopTest();

        Assert.areEqual(0, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'No inspections should be generated without an originating Inspection.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#7 and the user story's Example 2 - when the frequency decreases from
 *              4x to 2x per year, the surviving future records are re-dated to the new schedule
 *              and the excess records are marked Error rather than deleted.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testRecalculation_FrequencyDecrease_VoidsExcessAndRedatesRemainder() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '4 inspections per year', null);
        Assert.areEqual(4, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'The initial 4-per-year schedule should exist before recalculation.');

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk re-assessment', 'Completed', '2 inspections per year', null);
        Test.stopTest();

        List<Visit> allInspections = getGeneratedInspections(dataMap, dataMap.get('routineTypeId'));
        List<Visit> plannedInspections = new List<Visit>();
        List<Visit> erroredInspections = new List<Visit>();

        for (Visit inspection : allInspections) {
            if (inspection.Status == 'Error') {
                erroredInspections.add(inspection);
            } else {
                plannedInspections.add(inspection);
            }
        }

        Date anchorDate = anchor.date();

        Assert.areEqual(4, allInspections.size(), 'Excess records should be voided rather than deleted, so the total record count is unchanged.');
        Assert.areEqual(2, plannedInspections.size(), 'Only two Planned Routine inspections should remain for a 2-per-year frequency.');
        Assert.areEqual(2, erroredInspections.size(), 'The two excess inspections should be marked Error.');
        Assert.areEqual(anchorDate.addMonths(6).format(), plannedInspections[0].PlannedVisitStartTime.date().format(), 'The retained inspections should be re-dated to the new six-month schedule.');
        Assert.areEqual(anchorDate.addMonths(12).format(), plannedInspections[1].PlannedVisitStartTime.date().format(), 'The retained inspections should be re-dated to the new twelve-month schedule.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#7 - when the frequency increases from 1x to 4x per year, the existing
 *              future record is re-dated and the additional records required by the new
 *              frequency are inserted.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testRecalculation_FrequencyIncrease_RedatesExistingAndInsertsRemainder() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '1 inspection per year', null);
        Assert.areEqual(1, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'The initial 1-per-year schedule should exist before recalculation.');

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk re-assessment', 'Completed', '4 inspections per year', null);
        Test.stopTest();

        List<Visit> generated = getGeneratedInspections(dataMap, dataMap.get('routineTypeId'));
        Date anchorDate = anchor.date();

        Assert.areEqual(4, generated.size(), 'Four Routine inspections should exist after increasing to a 4-per-year frequency.');
        Assert.areEqual(anchorDate.addMonths(3).format(), generated[0].PlannedVisitStartTime.date().format(), 'The schedule should start three months after the completed inspection.');
        Assert.areEqual(anchorDate.addMonths(12).format(), generated[3].PlannedVisitStartTime.date().format(), 'The schedule should end twelve months after the completed inspection.');

        for (Visit inspection : generated) {
            Assert.areNotEqual('Error', inspection.Status, 'No records should be voided when the frequency increases.');
        }
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#7 - the completed Routine inspection that anchors the schedule is
 *              never modified or voided by a recalculation.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testRecalculation_CompletedInspectionIsNotModified() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Food', anchor);

        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '4 inspections per year', null);

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk re-assessment', 'Completed', '1 inspection per year', null);
        Test.stopTest();

        Visit originatingInspection = [SELECT Id, Status, ActualVisitStartTime FROM Visit WHERE Id = :dataMap.get('originatingInspectionId')];

        Assert.areEqual('Completed', originatingInspection.Status, 'The completed originating inspection must not be voided or re-statused.');
        Assert.areEqual(anchor.date().format(), originatingInspection.ActualVisitStartTime.date().format(), 'The completed inspection Actual Visit Start Time must not be changed.');
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Covers AC#7 for Tobacco and Vapour facilities - an MTS frequency decrease voids
 *              the excess MTS records while leaving the Routine schedule intact.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testRecalculation_MtsFrequencyDecrease_VoidsExcessMtsInspections() {
        Datetime anchor = System.now().addDays(-10);
        Map<String, Id> dataMap = createTestData('Tobacco and Vapour', anchor);

        insert buildAssessment(dataMap, 'Risk Assessment', 'Completed', '1 inspection per year', '3 inspections per year');
        Assert.areEqual(3, getGeneratedInspections(dataMap, dataMap.get('mtsTypeId')).size(), 'The initial 3x MTS schedule should exist before recalculation.');

        Test.startTest();
        insert buildAssessment(dataMap, 'Risk re-assessment', 'Completed', '1 inspection per year', '1 inspection per year');
        Test.stopTest();

        List<Visit> mtsInspections = getGeneratedInspections(dataMap, dataMap.get('mtsTypeId'));
        Integer plannedCount = 0;
        Integer erroredCount = 0;

        for (Visit inspection : mtsInspections) {
            if (inspection.Status == 'Error') {
                erroredCount++;
            } else {
                plannedCount++;
            }
        }

        Assert.areEqual(1, plannedCount, 'Only one Planned MTS inspection should remain for a 1x MTS/year frequency.');
        Assert.areEqual(2, erroredCount, 'The two excess MTS inspections should be marked Error.');
        Assert.areEqual(1, getGeneratedInspections(dataMap, dataMap.get('routineTypeId')).size(), 'The Routine schedule should be unaffected by the MTS change.');
    }
}