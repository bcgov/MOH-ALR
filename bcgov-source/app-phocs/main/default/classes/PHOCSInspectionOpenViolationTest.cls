@isTest
private class PHOCSInspectionOpenViolationTest {
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

        // Create Visit
        Visit testVisit = new Visit(
            AccountId = testAccount.Id,
            PlaceId = cpa.Id,
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(2)
        );
        insert testVisit;
        
                Visit secondVisit = new Visit(
            AccountId = testAccount.Id,
            PlaceId = cpa.Id,
            PlannedVisitStartTime = DateTime.now().addDays(1),
            PlannedVisitEndTime = DateTime.now().addDays(1).addHours(2)
        );
        insert secondVisit;

        // Create Assessment Task Definition
        AssessmentTaskDefinition testTaskDef = new AssessmentTaskDefinition(
            Name = 'Test Category',
            TaskType = 'InspectionChecklist'
        );
        insert testTaskDef;

        // Create Assessment Task
        AssessmentTask testTask = new AssessmentTask(
            Name = 'Test Task',
            TaskType = 'SignatureTask',
            ParentId = testVisit.Id,
            AssessmentTaskDefinitionId = testTaskDef.Id
        );
        insert testTask;

        // Create Assessment Indicator Definitions
        AssessmentIndicatorDefinition indicators = new AssessmentIndicatorDefinition(
                Name = 'Question 1',
                DataType = 'String',
                Category__c = 'test Category',
                Criticality__c = 'Critical',
                PHOCSParentId__c = Null
            );
        
        insert indicators;
        
        Id rectId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName()
    			.get('PHOCSInspectionAssessmentInd')
    			.getRecordTypeId();
        
                    // create inspection assessment indicator
                    InspectionAssessmentInd inspaind = new InspectionAssessmentInd(
                AssessmentIndDefinitionId = indicators.Id,
                AssessmentTaskId = testTask.Id,
                RecordTypeId = rectId
            );
                    insert inspaind;
        
        Datetime specificDateTime = DateTime.newInstance(2025, 12, 25, 10, 30, 0);
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(
            InspectionId = testVisit.Id,
            InspectionAssmntIndId = inspaind.Id,
            ComplianceDueDate = specificDateTime,
            DateCreated = specificDateTime,
            Status = 'Open'
            
        );
        insert violation;
        
            RegulatoryCodeViolation violation2 = new RegulatoryCodeViolation(
            InspectionId = secondVisit.Id,
            InspectionAssmntIndId = inspaind.Id,
            ComplianceDueDate = specificDateTime,
            DateCreated = specificDateTime,
            Status = 'Open'
        
        );
        insert violation2;
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        
        User adminUser = new User(
            Alias = 'adm',
            Email = 'admin' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AdminTestXYZ',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'admin' + System.currentTimeMillis() + '@test.com'
        );
        insert adminUser;
       
        
        
    }
  	@isTest
    static void testGetParentQuestionsWithOpenViolations() {
        Visit v = [SELECT Id,AccountId FROM Visit LIMIT 1];
        AssessmentIndicatorDefinition aid = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];

			List<Id> aidIds = new List<Id>{ aid.Id };
                
            Test.startTest();
            List<Id> result = PHOCSInspectionOpenViolationController.getParentQuestionsWithOpenViolations(v.Id, aidIds);
            Test.stopTest();
        	System.assertEquals(1, result.size(), 'Should find exactly one parent question with an open violation');
    }
    
   
}