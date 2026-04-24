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
            
            Id phocsInspectionRecordTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
            Datetime targetDate = Datetime.now().addDays(-30);         
            Map<Id, Visit> abandonedInspectionsMap = new Map<Id, Visit>([
                SELECT Id, Name, Status, ActualVisitEndTime
                FROM Visit
                WHERE Status = 'Abandoned' 
                AND RecordTypeId =:phocsInspectionRecordTypeId 
                AND ActualVisitEndTime <= :targetDate
                LIMIT 10000
            ]);
            
            if (!abandonedInspectionsMap.isEmpty()){
                List<InspectionAssessmentInd> insAssessmentIndicators = [
                    SELECT Id
                    FROM InspectionAssessmentInd
                    WHERE AssessmentTask.ParentId IN :abandonedInspectionsMap.keySet()
                ];
                if (!insAssessmentIndicators.isEmpty()) {
                    Database.delete(insAssessmentIndicators, false);
                }
                Database.DeleteResult[] results = Database.delete(abandonedInspectionsMap.values(), false);
            }
        } catch (Exception e) {
            throw e;
        }
    }
}