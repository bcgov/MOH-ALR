public class DeleteAbandonedInspectionsScheduler implements Schedulable {
    
    /**
     * @description Schedules the job to run daily at 2:00 AM
     * @return String The scheduled job ID
     */
    public static String scheduleDaily() {
        String cronExpression = '0 0 2 * * ?';
        String jobName = 'Delete Abandoned Inspections - Daily';
        
        return System.schedule(jobName, cronExpression, new DeleteAbandonedInspectionsScheduler());
    }
    
    public void execute(SchedulableContext sc) {
        deleteAbandonedInspections();
    }

    public static void deleteAbandonedInspections() {
        try {
            Id phocsInspectionRecordTypeId = Schema.SObjectType.Visit
                .getRecordTypeInfosByDeveloperName()
                .get('PHOCSInspection')
                .getRecordTypeId();

            Datetime targetDate = Datetime.now().addDays(-30);

            Map<Id, Visit> abandonedInspectionsMap = new Map<Id, Visit>([
                SELECT Id, Name, Status, ActualVisitEndTime
                FROM Visit
                WHERE Status = 'Abandoned'
                AND RecordTypeId = :phocsInspectionRecordTypeId
                AND ActualVisitEndTime <= :targetDate
            ]);

            if (!abandonedInspectionsMap.isEmpty()) {
                Set<Id> parentVisitIds = abandonedInspectionsMap.keySet();

                List<Visit> childVisits = [
                    SELECT Id, Name
                    FROM Visit
                    WHERE ParentVisitId IN :parentVisitIds
                ];

                Set<Id> allVisitIds = new Set<Id>();
                allVisitIds.addAll(parentVisitIds);

                for (Visit childVisit : childVisits) {
                    allVisitIds.add(childVisit.Id);
                }

                List<RegulatoryCodeViolation> rcvList = [
                    SELECT Id
                    FROM RegulatoryCodeViolation
                    WHERE InspectionId IN :allVisitIds
                ];

                if (!rcvList.isEmpty()) {
                    Database.delete(rcvList, false);
                }

                List<InspectionAssessmentInd> insAssessmentIndicators = [
                    SELECT Id
                    FROM InspectionAssessmentInd
                    WHERE AssessmentTask.ParentId IN :allVisitIds
                ];

                if (!insAssessmentIndicators.isEmpty()) {
                    Database.delete(insAssessmentIndicators, false);
                }

                if (!childVisits.isEmpty()) {
                    Database.delete(childVisits, false);
                }

                List<Visit> visitsToDelete = abandonedInspectionsMap.values();
                Database.DeleteResult[] results = Database.delete(visitsToDelete, false);

                for (Integer i = 0; i < results.size(); i++) {
                    if (!results[i].isSuccess()) {
                        for (Database.Error err : results[i].getErrors()) {
                            System.debug(
                                LoggingLevel.ERROR,
                                'Failed to delete Visit ' + visitsToDelete[i].Id +
                                ' - ' + err.getStatusCode() + ': ' + err.getMessage()
                            );
                        }
                    }
                }
            }
        } catch (Exception e) {
            throw e;
        }
    }
}