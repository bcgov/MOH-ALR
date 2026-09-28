/**********************************************************************************************
 * @Author:      Accenture
 * @Date:        03 Sep 2026
 * @Description: Trigger handler for the Assessment object. afterInsert() dispatches completed
 *               Risk Assessment/Risk re-assessment records to PHOCSRATInspectionGenerationService(),
 *               which generates and reconciles Routine (and, for Tobacco and Vapour facilities,
 *               MTS) PHOCS Inspection (Visit) records. Covers AC#1-AC#4 (generation) and AC#7
 *               (recalculation when a new RAT changes the frequency). Initial generation and
 *               recalculation share a single reconcile path - a facility with no existing future
 *               schedule simply has nothing to re-date or void. AC#8 (hiding Error-status records
 *               from related lists) is declarative configuration, not Apex.
 * @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
 *               03 Sep -  EHIS-5027         -  Deepak      -  Initial Routine/MTS inspection generation (AC#1-AC#4)
 *               17 Sep -  EHIS-5027         -  Deepak      -  Frequency-change recalculation (AC#7)
 *               17 Sep -  EHIS-5027         -  Deepak      -  Bulkified (no SOQL in loop), excluded Error records from
 *                                                             reconciliation, set the PHOCSInspection record type, and
 *                                                             counted migrated inspections toward the required frequency
 *               17 Sep -  EHIS-5027         -  Deepak      -  Blank MinimumInspectionFrequency__c/MTSInspectionFrequency__c
 *                                                             now resolves to a zero-record config, so a Completed RAT left
 *                                                             with a blank frequency voids any existing future RAT-generated
 *                                                             inspections via the same surplus-cleanup path, instead of being
 *                                                             silently ignored
 ***********************************************************************************************/
public with sharing class AssessmentTriggerHandler {
    private static final Id ASSESSMENT_RTID = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
    private static final Id INSPECTION_RTID = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    private static final String ASSESSMENT_STATUS_COMPLETED = 'Completed';
    private static final Set<String> QUALIFYING_ASSESSMENT_TYPES = new Set<String>{ 'Risk Assessment', 'Risk re-assessment' };
    private static final String FACILITY_TYPE_TOBACCO_VAPOUR = 'Tobacco and Vapour';
    private static final String INSPECTION_TYPE_ROUTINE = 'Routine';
    private static final String INSPECTION_TYPE_MTS = 'MTS (Minor Test Shopper)';
    private static final String VISIT_STATUS_PLANNED = 'Planned';
    private static final String VISIT_STATUS_COMPLETED = 'Completed';
    private static final String VISIT_STATUS_ERROR = 'Error';
    private static final String PACIFIC_TIME_ZONE = 'America/Los_Angeles';

/**
 * @author: Deepak
 * @date: 03 Sep 2026
 * @description: Carrier for an inspection frequency's generation rule - how many months apart
 *              each generated inspection is, and how many future inspection records to create.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private class IntervalConfig {
        Integer intervalMonths;
        Integer recordCount;

        IntervalConfig(Integer intervalMonths, Integer recordCount) {
            this.intervalMonths = intervalMonths;
            this.recordCount = recordCount;
        }
    }

    private static final Map<String, IntervalConfig> ROUTINE_INTERVALS = new Map<String, IntervalConfig>{
        '4 inspections per year' => new IntervalConfig(3, 4),
            '4 to 5 inspections per year' => new IntervalConfig(3, 4),
            '3 inspections per year' => new IntervalConfig(4, 3),
            '2 inspections per year' => new IntervalConfig(6, 2),
            '1 inspection per year' => new IntervalConfig(12, 1),
            '1 inspection every 2 years' => new IntervalConfig(24, 1),
            '1 inspection every 4 years' => new IntervalConfig(48, 1)
            };
                
    private static final Map<String, IntervalConfig> MTS_INTERVALS = new Map<String, IntervalConfig>{
                    '4 inspections per year' => new IntervalConfig(3, 4),
                        '4 to 5 inspections per year' => new IntervalConfig(3, 4),
                        '3 inspections per year' => new IntervalConfig(4, 3),
                        '2 inspections per year' => new IntervalConfig(6, 2),
                        '1 inspection per year' => new IntervalConfig(12, 1),
                        '1 inspection every 2 years' => new IntervalConfig(24, 1),
                        '1 inspection every 4 years' => new IntervalConfig(48, 1)
                        };
    
    private static final IntervalConfig ZERO_INSPECTIONS = new IntervalConfig(0, 0);

/**
 * @author: Deepak
 * @date: 03 Sep 2026
 * @description: Entry point intended to be called directly from the Assessment trigger's
 *              after-insert context. Passes every newly inserted Assessment through to
 *              PHOCSRATInspectionGenerationService(), which filters to qualifying records internally.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void afterInsert(List<Assessment> newList) {
        PHOCSRATInspectionGenerationService(newList);
    }

/**
 * @author: Deepak
 * @date: 03 Sep 2026
 * @description: Filters to qualifying Assessment records (PHOCSAssessment record type, Completed
 *              status, Risk Assessment/Risk re-assessment type), resolves every facility's anchor
 *              date and existing future schedule up front, then reconciles each facility's Routine
 *              (and, for Tobacco and Vapour, MTS) schedule against the newly determined frequency.
 *              All queries run before the loop so the handler stays bulk safe.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
 *                    17 Sep - EHIS-5027          - Deepak       - Bulkified and merged initial generation with frequency-change recalculation into one reconcile path.
 *                    17 Sep - EHIS-5027          - Deepak       - Resolves a blank frequency to ZERO_INSPECTIONS instead of passing null through to reconcileSchedule.
*/
    public static void PHOCSRATInspectionGenerationService(List<Assessment> newAssessments) {
        List<Assessment> qualifyingAssessments = filterQualifyingAssessments(newAssessments);

        if (qualifyingAssessments.isEmpty()) {
            return;
        }

        Map<Id, Assessment> assessmentByOriginatingInspectionId = new Map<Id, Assessment>();
        for (Assessment assessment : qualifyingAssessments) {
            if (assessment.ResponseContextId != null) {
                assessmentByOriginatingInspectionId.put(assessment.ResponseContextId, assessment);
            }
        }

        if (assessmentByOriginatingInspectionId.isEmpty()) {
            return;
        }

        Map<Id, Visit> originatingInspectionsById = new Map<Id, Visit>([SELECT Id, AccountId, PlaceId, ActualVisitStartTime, Account.Type, Account.HealthAuthority__c
                                                                        FROM Visit WHERE Id IN :assessmentByOriginatingInspectionId.keySet()
                                                                        AND RecordTypeId =: INSPECTION_RTID]);

        Set<Id> facilityIds = new Set<Id>();
        for (Visit originatingInspection : originatingInspectionsById.values()) {
            if (originatingInspection.AccountId != null) {
                facilityIds.add(originatingInspection.AccountId);
            }
        }

        if (facilityIds.isEmpty()) {
            return;
        }

        Map<String, Id> inspectionTypeIdsByValue = loadInspectionTypeIds();
        Map<Id, String> inspectionTypeValuesById = new Map<Id, String>();
        for (String typeValue : inspectionTypeIdsByValue.keySet()) {
            inspectionTypeValuesById.put(inspectionTypeIdsByValue.get(typeValue), typeValue);
        }

        Map<Id, Datetime> anchorByFacilityId = loadAnchorDates(facilityIds, inspectionTypeIdsByValue.get(INSPECTION_TYPE_ROUTINE));
        Map<String, List<Visit>> ratGeneratedByKey = new Map<String, List<Visit>>();
        Map<String, Integer> migratedCountByKey = new Map<String, Integer>();
        loadExistingFutureSchedule(facilityIds, inspectionTypeValuesById, ratGeneratedByKey, migratedCountByKey);

        List<Visit> inspectionsToInsert = new List<Visit>();
        List<Visit> inspectionsToUpdate = new List<Visit>();

        for (Id originatingInspectionId : assessmentByOriginatingInspectionId.keySet()) {
            Visit originatingInspection = originatingInspectionsById.get(originatingInspectionId);
            Assessment assessment = assessmentByOriginatingInspectionId.get(originatingInspectionId);

            if (originatingInspection == null || originatingInspection.AccountId == null) {
                continue;
            }

            Datetime anchor = anchorByFacilityId.containsKey(originatingInspection.AccountId)
                ? anchorByFacilityId.get(originatingInspection.AccountId)
                : originatingInspection.ActualVisitStartTime;

            if (anchor == null) {
                continue;
            }

            reconcileSchedule(assessment, originatingInspection, anchor, INSPECTION_TYPE_ROUTINE, inspectionTypeIdsByValue.get(INSPECTION_TYPE_ROUTINE),
                              resolveIntervalConfig(ROUTINE_INTERVALS, assessment.MinimumInspectionFrequency__c), ratGeneratedByKey, migratedCountByKey,
                              inspectionsToInsert, inspectionsToUpdate);

            if (originatingInspection.Account != null && originatingInspection.Account.Type == FACILITY_TYPE_TOBACCO_VAPOUR) {
                reconcileSchedule(assessment, originatingInspection, anchor, INSPECTION_TYPE_MTS, inspectionTypeIdsByValue.get(INSPECTION_TYPE_MTS),
                                  resolveIntervalConfig(MTS_INTERVALS, assessment.MTSInspectionFrequency__c), ratGeneratedByKey, migratedCountByKey,
                                  inspectionsToInsert, inspectionsToUpdate);
            }
        }

        if (!inspectionsToUpdate.isEmpty()) {
            update inspectionsToUpdate;
        }

        if (!inspectionsToInsert.isEmpty()) {
            insert inspectionsToInsert;
        }
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Resolves a frequency picklist value to its IntervalConfig. A blank value resolves
 *              to ZERO_INSPECTIONS (0 inspections/year), not null - this is what lets
 *              reconcileSchedule void any existing future RAT-generated inspections through its
 *              normal surplus-cleanup path rather than silently doing nothing. A genuinely
 *              unrecognized non-blank value still resolves to null, and reconcileSchedule still
 *              no-ops for it, since its intent isn't known.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static IntervalConfig resolveIntervalConfig(Map<String, IntervalConfig> intervalsByFrequency, String frequencyValue) {
        if (String.isBlank(frequencyValue)) {
            return ZERO_INSPECTIONS;
        }
        return intervalsByFrequency.get(frequencyValue);
    }

/**
 * @author: Deepak
 * @date: 03 Sep 2026
 * @description: Filters to Assessment records matching the PHOCSAssessment record type,
 *              AssessmentStatus = Completed, and Type of Risk Assessment or Risk re-assessment.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static List<Assessment> filterQualifyingAssessments(List<Assessment> assessments) {
        List<Assessment> result = new List<Assessment>();

        for (Assessment assessment : assessments) {
            if (assessment.RecordTypeId == ASSESSMENT_RTID && assessment.AssessmentStatus == ASSESSMENT_STATUS_COMPLETED && QUALIFYING_ASSESSMENT_TYPES.contains(assessment.Type)) {
                result.add(assessment);
            }
        }
        return result;
    }

/**
 * @author: Deepak
 * @date: 03 Sep 2026
 * @description: Loads the InspectionType record Id for each of Routine and MTS, keyed by the
 *              InspectionTypes__c picklist value. ASSUMPTION: exactly one canonical InspectionType
 *              record exists per value - if duplicates exist, the first one encountered wins silently.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, Id> loadInspectionTypeIds() {
        Map<String, Id> result = new Map<String, Id>();
        
        for (InspectionType inspType : [SELECT Id, Name FROM InspectionType WHERE Name IN (:INSPECTION_TYPE_ROUTINE, :INSPECTION_TYPE_MTS)]) {
            if (!result.containsKey(inspType.Name)) {
                result.put(inspType.Name, inspType.Id);
            }
        }
        return result;
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Resolves every facility's scheduling anchor in a single query - the Actual Visit
 *              Start Time of its most recently completed Routine inspection. Per AC#2 and AC#3 both
 *              the Routine and the MTS schedules anchor on the most recently completed Routine
 *              inspection. Historical/migrated inspections are included as long as they are
 *              Completed with an Actual Visit Start Time populated.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<Id, Datetime> loadAnchorDates(Set<Id> facilityIds, Id routineVisitTypeId) {
        Map<Id, Datetime> anchorByFacilityId = new Map<Id, Datetime>();

        if (routineVisitTypeId == null) {
            return anchorByFacilityId;
        }

        for (Visit completedInspection : [SELECT Id, AccountId, ActualVisitStartTime FROM Visit
                                          WHERE AccountId IN :facilityIds AND VisitTypeId = :routineVisitTypeId
                                          AND Status = :VISIT_STATUS_COMPLETED AND ActualVisitStartTime != null
                                          ORDER BY ActualVisitStartTime DESC]) {
            if (!anchorByFacilityId.containsKey(completedInspection.AccountId)) {
                anchorByFacilityId.put(completedInspection.AccountId, completedInspection.ActualVisitStartTime);
            }
        }
        return anchorByFacilityId;
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Loads every facility's existing future, uncompleted inspections in a single query
 *              and splits them per facility/inspection type into the RAT-generated records
 *              (eligible to be re-dated or voided, per AC#7) and a count of the non-RAT-generated
 *              ones (historical/migrated or manually created records, which are never modified but
 *              still count toward satisfying the required frequency). Records already voided to
 *              Error are excluded so a previous void is never silently resurrected.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void loadExistingFutureSchedule(Set<Id> facilityIds, Map<Id, String> inspectionTypeValuesById,
                                                   Map<String, List<Visit>> ratGeneratedByKey, Map<String, Integer> migratedCountByKey) {
        if (inspectionTypeValuesById.isEmpty()) {
            return;
        }

        Datetime nowValue = System.now();
        Set<Id> inspectionTypeIds = inspectionTypeValuesById.keySet();

        for (Visit futureInspection : [SELECT Id, AccountId, VisitTypeId, Status, PlannedVisitStartTime, RATGenerated__c FROM Visit
                                       WHERE AccountId IN :facilityIds AND VisitTypeId IN :inspectionTypeIds
                                       AND Status NOT IN (:VISIT_STATUS_COMPLETED, :VISIT_STATUS_ERROR)
                                       AND PlannedVisitStartTime >= :nowValue AND RecordTypeId =: INSPECTION_RTID
                                       ORDER BY PlannedVisitStartTime ASC]) {
            String typeValue = inspectionTypeValuesById.get(futureInspection.VisitTypeId);

            if (typeValue == null) {
                continue;
            }

            String key = buildScheduleKey(futureInspection.AccountId, typeValue);

            if (futureInspection.RATGenerated__c == true) {
                if (!ratGeneratedByKey.containsKey(key)) {
                    ratGeneratedByKey.put(key, new List<Visit>());
                }
                ratGeneratedByKey.get(key).add(futureInspection);
            } else {
                Integer currentCount = migratedCountByKey.containsKey(key) ? migratedCountByKey.get(key) : 0;
                migratedCountByKey.put(key, currentCount + 1);
            }
        }
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Reconciles one facility's schedule for a single inspection type against the newly
 *              determined frequency. Existing RAT-generated future records are re-dated to the new
 *              schedule first, any surplus beyond the new frequency is marked Error (AC#7 decrease,
 *              which also covers a blank frequency resolved to ZERO_INSPECTIONS - every existing
 *              RAT-generated record becomes surplus and none are re-dated), and any shortfall is
 *              inserted as new Planned records (AC#7 increase). A facility with no existing future
 *              schedule simply falls through to inserting the full set, which is the AC#1-AC#4
 *              initial generation case. Non-RAT-generated future inspections (historical/migrated)
 *              are never modified but do reduce the number of slots that need filling. Does nothing
 *              when config is null, i.e. the frequency value is non-blank but has no configured
 *              interval mapping.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void reconcileSchedule(Assessment assessment, Visit originatingInspection, Datetime anchor, String typeValue, Id visitTypeId,
                                          IntervalConfig config, Map<String, List<Visit>> ratGeneratedByKey, Map<String, Integer> migratedCountByKey,
                                          List<Visit> inspectionsToInsert, List<Visit> inspectionsToUpdate) {
        if (config == null || visitTypeId == null) {
            return;
        }

        String key = buildScheduleKey(originatingInspection.AccountId, typeValue);
        List<Visit> existingRatGenerated = ratGeneratedByKey.containsKey(key) ? ratGeneratedByKey.get(key) : new List<Visit>();
        Integer migratedCount = migratedCountByKey.containsKey(key) ? migratedCountByKey.get(key) : 0;

        List<Datetime> desiredDates = new List<Datetime>();
        Date anchorDate = anchor.date();

        for (Integer i = 1; i <= config.recordCount; i++) {
            desiredDates.add(buildNoonPacificDatetime(anchorDate.addMonths(config.intervalMonths * i)));
        }

        // Migrated or manually created future inspections already satisfy the earliest slots, so
        // the RAT-generated records only need to cover whatever remains after those.
        Integer slotsToFill = desiredDates.size() - migratedCount;

        if (slotsToFill < 0) {
            slotsToFill = 0;
        }

        List<Datetime> targetDates = new List<Datetime>();
        for (Integer i = desiredDates.size() - slotsToFill; i < desiredDates.size(); i++) {
            targetDates.add(desiredDates[i]);
        }

        Integer reusedCount = 0;

        while (reusedCount < targetDates.size() && reusedCount < existingRatGenerated.size()) {
            Visit existingInspection = existingRatGenerated[reusedCount];
            existingInspection.PlannedVisitStartTime = targetDates[reusedCount];
            inspectionsToUpdate.add(existingInspection);
            reusedCount++;
        }

        for (Integer i = reusedCount; i < existingRatGenerated.size(); i++) {
            Visit surplusInspection = existingRatGenerated[i];
            surplusInspection.Status = VISIT_STATUS_ERROR;
            inspectionsToUpdate.add(surplusInspection);
        }

        for (Integer i = reusedCount; i < targetDates.size(); i++) {
            inspectionsToInsert.add(buildInspection(assessment, originatingInspection, visitTypeId, targetDates[i]));
        }
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Builds the facility/inspection-type key used to bucket an existing schedule.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String buildScheduleKey(Id facilityId, String typeValue) {
        return String.valueOf(facilityId) + '|' + typeValue;
    }

/**
 * @author: Deepak
 * @date: 17 Sep 2026
 * @description: Builds a single planned RAT-generated Inspection record for the supplied inspection
 *              type and planned start time.
 *              NOTE: AC#1/AC#3 also require Created By to be the automation system user. Setting
 *              CreatedById requires the org-level "Set Audit Fields upon Record Creation"
 *              permission - without it the insert fails outright rather than defaulting - so it is
 *              deliberately not set here. Once that permission is enabled, add
 *              CreatedById = <automation user Id> to this constructor.
 * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
 *                    17 Sep - EHIS-5027 - Deepak - Set the PHOCSInspection record type and removed
 *                    the CreatedById assignment pending the audit-fields permission decision.
*/
    private static Visit buildInspection(Assessment assessment, Visit originatingInspection, Id visitTypeId, Datetime plannedStartTime) {
        return new Visit(
            RecordTypeId = INSPECTION_RTID,
            Status = VISIT_STATUS_PLANNED,
            VisitTypeId = visitTypeId,
            OwnerId = assessment.CreatedById,
            AccountId = originatingInspection.AccountId,
            PlaceId = originatingInspection.PlaceId,
            PlannedVisitStartTime = plannedStartTime,
            HealthAuthority__c = originatingInspection?.Account?.HealthAuthority__c,
            RATGenerated__c = true
        );
    }

/**
 * @author: Deepak
 * @date: 03 Sep 2026
 * @description: Builds a Datetime representing 12:00 PM Pacific Time on the given date, correctly
 *              accounting for PST/PDT daylight saving offset on that specific date.
 * @Modification Log: [Date] - [Change Reference] - [Description]
*/
    private static Datetime buildNoonPacificDatetime(Date targetDate) {
        Datetime naiveNoon = Datetime.newInstanceGmt(targetDate.year(), targetDate.month(), targetDate.day(), 12, 0, 0);
        TimeZone pacificTime = TimeZone.getTimeZone(PACIFIC_TIME_ZONE);
        Integer offsetMillis = pacificTime.getOffset(naiveNoon);
        return naiveNoon.addSeconds(-offsetMillis / 1000);
    }
}