@isTest
private class PHOCSInspectionAssessmentIndBatchTest {
	/**
     * @description Creates test data for violation service tests
     */
    @TestSetup
    static void setupTestData() {
        
        // Create RegulatoryAuthorizationType
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(
         Name = 'test reg type'
        );
        insert reg;
        
        // Create Account
        Account testAccount = new Account(
            Name = 'Test Facility',
             LicenseType__c = reg.Id
        );
        insert testAccount;
        
        ContactPointAddress cpa = new ContactPointAddress(
        Name = 'Test Address',
        Street = '123 Test Lane',
        City = 'Alberta',
        State = 'AL',
        Country = 'Canada',
        PostalCode = '500001'
    		);
    	insert cpa;

        // Create Visit - VisitTypeId is optional
        Visit testVisit = new Visit(
            AccountId = testAccount.Id,
            PlaceId = cpa.Id,
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(2)
        );
        insert testVisit;

        // Create Assessment Task Definition
        AssessmentTaskDefinition testTaskDef = new AssessmentTaskDefinition(
            Name = 'Test Category',
            TaskType = 'InspectionChecklist'
        );
        insert testTaskDef;

        // Create Assessment Task
        AssessmentTask testTask = new AssessmentTask(
            Name = 'Test Task',
            ParentId = testVisit.Id,
            AssessmentTaskDefinitionId = testTaskDef.Id
        );
        insert testTask;

        // Create parent Assessment Indicator Definition
        AssessmentIndicatorDefinition parentIndicator = new AssessmentIndicatorDefinition(
            Name = 'Is the facility properly maintained?',
            //DataType = 'Text'
            Category__c = 'test Category'
        );
        insert parentIndicator;

        // Create child Assessment Indicator Definition (canned comment)
        AssessmentIndicatorDefinition childIndicator = new AssessmentIndicatorDefinition(
            Name = 'Floor needs repair',
            //DataType = 'Boolean',
            Category__c = 'test Category',
            PHOCSParentId__c = parentIndicator.Id
        );
        insert childIndicator;
    }
    
    @isTest
    static void batchrunafterinspectionComplted(){
        
        Visit inspection = [SELECT Id,Status FROM Visit LIMIT 1];
        AssessmentTask task = [SELECT Id,ParentId FROM AssessmentTask
                               					  WHERE ParentId =:inspection.Id 
                               					  LIMIT 1];
       AssessmentIndicatorDefinition indicator = [SELECT Id,PHOCSParentId__c FROM AssessmentIndicatorDefinition 
                                                  							 WHERE PHOCSParentId__c = Null 
                                                  							 LIMIT 1];
       AssessmentIndicatorDefinition childindicator = new AssessmentIndicatorDefinition(
       				Name = 'Child rec',
           			PHOCSParentId__c = indicator.Id,
           			Category__c = 'test Category'
       				); 
        			insert childindicator;
        Id rectId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName()
    			.get('PHOCSInspectionAssessmentInd')
    			.getRecordTypeId();
        
        InspectionAssessmentInd ind = new InspectionAssessmentInd(
        	AssessmentTaskId = task.Id,
            AssessmentIndDefinitionId = childindicator.Id,
            Result = 'Non Compliant',
            RecordTypeId = rectId
        );
        insert ind;
        
         InspectionAssessmentInd childind = new InspectionAssessmentInd(
        	AssessmentTaskId = task.Id,
            AssessmentIndDefinitionId = childindicator.Id,
            PHOCSCheckboxResponse__c = false,
            RecordTypeId = rectId
        );
        insert childind;
        
        InspectionAssessmentInd childindc = new InspectionAssessmentInd(
        	AssessmentTaskId = task.Id,
            AssessmentIndDefinitionId = childindicator.Id,
            PHOCSCheckboxResponse__c = true,
            RecordTypeId = rectId
        );
        insert childindc;
        
        
        Test.startTest();
        inspection.Status = 'Completed';
        update inspection;
        Test.stopTest();
        
        List<InspectionAssessmentInd> insasstind = [SELECT ID,PHOCSCheckboxResponse__c
                                                   	FROM InspectionAssessmentInd
                                                   	WHERE AssessmentTaskId =:task.Id
                                                   	AND AssessmentIndDefinitionId =:childindicator.Id ];
        System.assertEquals(3,insasstind.size(),'Canned comment records with PHOCSCheckboxResponse__c checked will be present');
        System.assertEquals(true,insasstind[0].PHOCSCheckboxResponse__c);
    }
}