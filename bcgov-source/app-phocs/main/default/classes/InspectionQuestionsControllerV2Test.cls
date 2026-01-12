/**
 * @description Test class for InspectionQuestionsController
 * @author PHOCS Team
 * @date 2025-12-14
 */
@isTest
private class InspectionQuestionsControllerV2Test {
    
    /**
     * @description Creates test data for inspection questions
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

        // Create Visit (Inspection) - VisitTypeId is optional
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

        // Create Assessment Indicator Definition (parent question)
        AssessmentIndicatorDefinition parentIndicator = new AssessmentIndicatorDefinition(
            Name = 'Is the facility properly maintained?',
            Category__c = 'test Category'
            //DataType = 'Text'
        );
        insert parentIndicator;

        // Create Assessment Indicator Definition (child question - canned comment)
        AssessmentIndicatorDefinition childIndicator = new AssessmentIndicatorDefinition(
            Name = 'Floor needs repair',
            //DataType = 'Boolean',
            Category__c = 'test Category',
            PHOCSParentId__c = parentIndicator.Id
        );
        insert childIndicator;

        // Create Assessment Task Ind Definition (links task def to indicator def)
        List<AssessmentTaskIndDefinition> taskIndDefs = new List<AssessmentTaskIndDefinition>{
            new AssessmentTaskIndDefinition(
                AssessmentTaskDefinitionId = testTaskDef.Id,
                AssessmentIndDefinitionId = parentIndicator.Id,
                DisplayOrder = 1
            ),
            new AssessmentTaskIndDefinition(
                AssessmentTaskDefinitionId = testTaskDef.Id,
                AssessmentIndDefinitionId = childIndicator.Id,
                DisplayOrder = 2
            )
        };
        insert taskIndDefs;

        // Create existing InspectionAssessmentInd response
        InspectionAssessmentInd existingResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = parentIndicator.Id,
            Result = 'Compliant',
            PHOCSInspectionComments__c = 'Test comment'
        );
        insert existingResponse;
        
        RegulatoryAuthority rcode = new RegulatoryAuthority(
         Name = 'test' 
        );
        insert rcode;
    }

    /**
     * @description Test getInspectionQuestions with valid Visit ID
     */
    @isTest
    static void testGetInspectionQuestions_ValidVisit() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        
        Test.startTest();
        List<InspectionQuestionsControllerV2.TaskGroupWrapper> result = 
            InspectionQuestionsControllerV2.getInspectionQuestions(testVisit.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(0, result.size(), 'Result should contain at least one task group');
        
        // Verify the task group has questions
        InspectionQuestionsControllerV2.TaskGroupWrapper taskGroup = result[0];
        System.assertNotEquals(null, taskGroup.parentQuestions, 'Parent questions should not be null');
        System.assertEquals('Test Category', taskGroup.taskDefinitionName, 'Task definition name should match');
        
        // Verify existing response is loaded
        if (!taskGroup.parentQuestions.isEmpty()) {
            InspectionQuestionsControllerV2.QuestionWrapper parentQuestion = taskGroup.parentQuestions[0];
            System.assertEquals('Compliant', parentQuestion.Result, 'Existing result should be loaded');
            System.assertEquals('Test comment', parentQuestion.PHOCSInspectionComments, 'Existing comment should be loaded');
        }
    }

    /**
     * @description Test getInspectionQuestions with null Visit ID
     */
    @isTest
    static void testGetInspectionQuestions_NullVisitId() {
        Test.startTest();
        List<InspectionQuestionsControllerV2.TaskGroupWrapper> result = 
            InspectionQuestionsControllerV2.getInspectionQuestions(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty for null visit ID');
    }

    /**
     * @description Test getInspectionQuestions with Visit that has no tasks
     */
    @isTest
    static void testGetInspectionQuestions_NoTasks() {
        // Create a new Visit with no tasks
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        ContactPointAddress cp = [SELECT Id FROM ContactPointAddress limit 1];
        
        Visit emptyVisit = new Visit(
            AccountId = testAccount.Id,
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(2),
            PlaceId = cp.Id
            
        );
        insert emptyVisit;

        Test.startTest();
        List<InspectionQuestionsControllerV2.TaskGroupWrapper> result = 
            InspectionQuestionsControllerV2.getInspectionQuestions(emptyVisit.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty for visit with no tasks');
    }

    /**
     * @description Test getRegulatoryCodesByIndicator with valid ID
     */
    @isTest
    static void testGetRegulatoryCodesByIndicator_ValidId() {
        AssessmentIndicatorDefinition indicator = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
        RegulatoryAuthority rc = [SELECT Id from RegulatoryAuthority LIMIT 1];
        
        // Create a Regulatory Code - IsActive is auto-set
        RegulatoryCode testCode = new RegulatoryCode(
            Name = 'test',
            Subject = 'Test Regulation',
            RegulatoryAuthorityId = rc.Id,
            EffectiveFrom = Date.today().addMonths(-1),
            EffectiveTo = Date.today().addMonths(12)
        );
        insert testCode;

        // Link the code to the indicator
        RegulatoryCodeAssessmentInd codeLink = new RegulatoryCodeAssessmentInd(
            AssessmentIndDefinitionId = indicator.Id,
            RegulatoryCodeId = testCode.Id
        );
        insert codeLink;

        Test.startTest();
        List<InspectionQuestionsControllerV2.RegulatoryCodeWrapper> result = 
            InspectionQuestionsControllerV2.getRegulatoryCodesByIndicator(indicator.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one regulatory code');
        System.assertEquals('Test Regulation', result[0].regulatoryCodeName, 'Regulatory code name should match');
    }

    /**
     * @description Test getRegulatoryCodesByIndicator with null ID
     */
    @isTest
    static void testGetRegulatoryCodesByIndicator_NullId() {
        Test.startTest();
        List<InspectionQuestionsControllerV2.RegulatoryCodeWrapper> result = 
            InspectionQuestionsControllerV2.getRegulatoryCodesByIndicator(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty for null ID');
    }

    /**
     * @description Test getRegulatoryCodesByIndicator with no linked codes
     */
    @isTest
    static void testGetRegulatoryCodesByIndicator_NoCodes() {
        // Create a new indicator with no linked codes
        AssessmentIndicatorDefinition newIndicator = new AssessmentIndicatorDefinition(
            Name = 'No Codes Indicator',
            Category__c = 'test Category'
            //DataType = 'Text'
        );
        insert newIndicator;

        Test.startTest();
        List<InspectionQuestionsControllerV2.RegulatoryCodeWrapper> result = 
            InspectionQuestionsControllerV2.getRegulatoryCodesByIndicator(newIndicator.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Result should be empty for indicator with no codes');
    }

    /**
     * @description Test parent-child question hierarchy
     */
    @isTest
    static void testParentChildQuestionHierarchy() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        
        Test.startTest();
        List<InspectionQuestionsControllerV2.TaskGroupWrapper> result = 
            InspectionQuestionsControllerV2.getInspectionQuestions(testVisit.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(0, result.size(), 'Should have task groups');
        
        // Find parent question with children - renamed from 'group' to avoid reserved keyword
        Boolean foundParentWithChildren = false;
        for (InspectionQuestionsControllerV2.TaskGroupWrapper taskGroup : result) {
            for (InspectionQuestionsControllerV2.QuestionWrapper parent : taskGroup.parentQuestions) {
                if (parent.childQuestions != null && !parent.childQuestions.isEmpty()) {
                    foundParentWithChildren = true;
                    System.assertEquals(1, parent.childQuestions.size(), 'Parent should have one child question');
                }
            }
        }
        
        System.assertEquals(true, foundParentWithChildren, 'Should find parent question with child questions');
    }
}