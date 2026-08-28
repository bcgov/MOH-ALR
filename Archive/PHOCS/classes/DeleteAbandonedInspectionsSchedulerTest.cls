@IsTest
private class DeleteAbandonedInspectionsSchedulerTest {
    public static Id phocsInspectionRecordTypeId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();

    @IsTest
    static void testDeleteAbandonedInspections() {
        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(
        	Name = 'test regulatory',
            RegulatoryAuthCategory = 'License'     
        );
        insert licenseType;
        
        Account acc = new Account(
            Name = 'test account',
            Physical_Address__Street__s = '123 Test Lane',
            Physical_Address__City__s = 'Kelowna',
            Physical_Address__StateCode__s = 'BC',
            Physical_Address__PostalCode__s = 'V6X 5K8',
            Physical_Address__CountryCode__s ='CA',
            LicenseType__c = licenseType.Id
        );
        insert acc;
		ContactPointAddress cpa = new ContactPointAddress(
            Name = 'Test Address',
            Street = '123 Test Lane',
            City = 'Alberta',
            State = 'AL',
            Country = 'Canada',
            PostalCode = '500001'
        );
        insert cpa;
        DateTime visitDateTime = DateTime.newInstance(2025, 2, 10, 14, 30, 0);

        Visit vi = new Visit(
            AccountId = acc.Id,
            RecordTypeId = phocsInspectionRecordTypeId,
            PlannedVisitStartTime = visitDateTime,
            ActualVisitStartTime = visitDateTime,
            ActualVisitEndTime = visitDateTime.addHours(2),
            TimeSpentMinutes__c = '01:20',
            PlaceId = cpa.Id,
            Status = 'Abandoned',
            StatusRemarks = 'Inspection Completed'
        );
        insert vi;

        AssessmentTaskDefinition taskDef = new AssessmentTaskDefinition(
            Name = 'task def',
            TaskType = 'InspectionChecklist'
        );
        insert taskDef;

        AssessmentTask asstask = new AssessmentTask(
            Name = 'task',
            TaskType = 'InspectionChecklist',
            ParentId = vi.Id,
            AssessmentTaskDefinitionId = taskDef.Id
        );
        insert asstask;

        // Parent definition
        AssessmentIndicatorDefinition parentDef = new AssessmentIndicatorDefinition(
            Name = 'Parent Question',
            Category__c = 'Sanitation',
            Criticality__c = 'Critical'
        );
        insert parentDef;

        // Child definition (for canned comment)
        AssessmentIndicatorDefinition childDef = new AssessmentIndicatorDefinition(
            Name = 'Canned Comment 1',
            PHOCSParentId__c = parentDef.Id,
            Category__c = 'test Category'
        );
        insert childDef;

        // Non-compliant (Critical)
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'PHOCSNonCompliant',
            PHOCSInspectionComments__c = 'Needs correction',
            CorrectiveActionDescription__c = 'Fix immediately',
            ComplianceDueDate__c = System.today().addDays(5)
        );

        // Compliant
        InspectionAssessmentInd insAssessmentInd = new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'Compliant'
        );
        insert insAssessmentInd;

        // Not Assessed
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'N/S (Not Assessed)'
        );

        // Not Applicable
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = parentDef.Id,
            Result = 'N/A (Not Applicable)'
        );

        // Canned comment record
        insert new InspectionAssessmentInd(
            AssessmentTaskId = asstask.Id,
            AssessmentIndDefinitionId = childDef.Id,
            PHOCSCheckboxResponse__c = true
        );

        Test.startTest();

        // Run scheduler
        DeleteAbandonedInspectionsScheduler scheduler = new DeleteAbandonedInspectionsScheduler();
        scheduler.execute(null);

        Test.stopTest();

        //Verify Visit is deleted
        List<Visit> visits = [
            SELECT Id FROM Visit WHERE Id = :vi.Id
        ];
        System.assertEquals(0, visits.size(), 'Visit should be deleted');

        // Verify Indicator is deleted
        List<InspectionAssessmentInd> inds = [
            SELECT Id FROM InspectionAssessmentInd WHERE Id = :insAssessmentInd.Id
        ];
        System.assertEquals(0, inds.size(), 'InspectionAssessmentInd should be deleted');
    }
    
    @IsTest
    static void testScheduleDaily() {
        Test.startTest();
        
        String jobId = DeleteAbandonedInspectionsScheduler.scheduleDaily();
        
        Test.stopTest();
    
        // Verify job was scheduled
        CronTrigger ct = [
            SELECT Id, CronExpression, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
    
        System.assertEquals('Delete Abandoned Inspections - Daily', ct.CronJobDetail.Name);
        System.assertEquals('0 0 2 * * ?', ct.CronExpression);
        System.assertEquals('WAITING', ct.State);
    }
}