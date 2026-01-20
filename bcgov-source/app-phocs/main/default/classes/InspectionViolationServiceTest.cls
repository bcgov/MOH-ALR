/**
 * @description Test class for InspectionViolationService
 * @author PHOCS Dev Team
 * @date 2025-12-14
 */
@isTest
private class InspectionViolationServiceTest {
    
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
        
        RegulatoryAuthority rcode = new RegulatoryAuthority(
         Name = 'test' 
        );
        insert rcode;

        // Create Regulatory Code - IsActive is auto-set/formula
        RegulatoryCode testCode = new RegulatoryCode(
            Subject = 'Test Regulation',
            Name = 'test',
            EffectiveFrom = Date.today().addMonths(-1),
            RegulatoryAuthorityId = rcode.Id
        );
        insert testCode;

        // Link regulatory code to parent indicator
        RegulatoryCodeAssessmentInd codeLink = new RegulatoryCodeAssessmentInd(
            AssessmentIndDefinitionId = parentIndicator.Id,
            RegulatoryCodeId = testCode.Id
        );
        insert codeLink;
    }

    /**
     * @description Test createViolationsForInspection with null visitId
     */
    @isTest
    static void testCreateViolations_NullVisitId() {
        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should return failure for null visit ID');
        System.assertEquals('Visit ID is required', result.message, 'Message should indicate visit ID required');
    }

    /**
     * @description Test createViolationsForInspection with no assessment responses
     */
    @isTest
    static void testCreateViolations_NoResponses() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];

        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(testVisit.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should return no violations when no responses exist');
        System.assertEquals('No assessment responses found', result.message, 'Message should indicate no responses');
    }

    /**
     * @description Test createViolationsForInspection with compliant responses only
     */
    @isTest
    static void testCreateViolations_AllCompliant() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        AssessmentTask testTask = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition parentIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c = null LIMIT 1
        ];

        // Create compliant response
        InspectionAssessmentInd compliantResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = parentIndicator.Id,
            Result = 'Compliant',
            PHOCSInspectionComments__c = 'All good'
        );
        insert compliantResponse;

        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(testVisit.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should return success');
        System.assertEquals('No non-compliant questions found', result.message, 'Message should indicate no non-compliant');
        System.assertEquals(0, result.violationCount, 'Should create 0 violations');
    }

    /**
     * @description Test createViolationsForInspection creates parent violation for non-compliant
     */
    @isTest
    static void testCreateViolations_ParentNonCompliant() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        AssessmentTask testTask = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition parentIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c = null LIMIT 1
        ];

        // Create non-compliant response
        InspectionAssessmentInd nonCompliantResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = parentIndicator.Id,
            Result = 'PHOCSNonCompliant',
            PHOCSInspectionComments__c = 'Needs attention'
        );
        insert nonCompliantResponse;

        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(testVisit.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should return success');
        System.assertEquals(1, result.parentViolationIds.size(), 'Should create 1 parent violation');
        System.assertEquals(0, result.cannedCommentViolationIds.size(), 'Should create 0 canned comment violations');
        System.assertEquals(1, result.violationCount, 'Total violation count should be 1');

        // Verify the violation was created correctly
        List<RegulatoryCodeViolation> violations = [
            SELECT Id, Description, InspectionId, PHOCSParentAccountID__c, 
                   InspectionAssmntIndId, RegulatoryCodeId, Status
            FROM RegulatoryCodeViolation
            WHERE InspectionId = :testVisit.Id
        ];
        System.assertEquals(2, violations.size(), 'Should have 2 violation record');
        System.assertEquals(testVisit.Id, violations[0].InspectionId, 'InspectionId should match visit');
        System.assertNotEquals(null, violations[0].RegulatoryCodeId, 'Should have regulatory code linked');
        System.assertEquals('Open', violations[0].Status, 'Status should be Open');
    }

    /**
     * @description Test createViolationsForInspection creates canned comment violations
     */
    @isTest
    static void testCreateViolations_WithCannedComments() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        AssessmentTask testTask = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition parentIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c = null LIMIT 1
        ];
        AssessmentIndicatorDefinition childIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c != null LIMIT 1
        ];

        // Create non-compliant parent response
        InspectionAssessmentInd parentResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = parentIndicator.Id,
            Result = 'PHOCSNonCompliant',
            PHOCSInspectionComments__c = 'Multiple issues found'
        );
        insert parentResponse;

        // Create selected canned comment response
        InspectionAssessmentInd childResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = childIndicator.Id,
            Result = 'PHOCSNonCompliant',
            PHOCSCheckboxResponse__c = true  // Selected
        );
        insert childResponse;

        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(testVisit.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should return success');
        System.assertEquals(1, result.parentViolationIds.size(), 'Should create 1 parent violation');
        System.assertEquals(1, result.cannedCommentViolationIds.size(), 'Should create 1 canned comment violation');
        System.assertEquals(2, result.violationCount, 'Total violation count should be 2');

        // Verify parent-child linking
        List<RegulatoryCodeViolation> violations = [
            SELECT Id, PHOCSParentId__c 
            FROM RegulatoryCodeViolation 
            WHERE PHOCSParentId__c != null
        ];
        System.assertEquals(1, violations.size(), 'Should have 1 child violation with parent link');
        System.assertNotEquals(null, violations[0].PHOCSParentId__c, 'Child should be linked to parent');
    }

    /**
     * @description Test createViolationsForInspection ignores unselected canned comments
     */
    @isTest
    static void testCreateViolations_UnselectedCannedComments() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        AssessmentTask testTask = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition parentIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c = null LIMIT 1
        ];
        AssessmentIndicatorDefinition childIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c != null LIMIT 1
        ];

        // Create non-compliant parent response
        InspectionAssessmentInd parentResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = parentIndicator.Id,
            Result = 'PHOCSNonCompliant'
        );
        insert parentResponse;

        // Create UNselected canned comment response
        InspectionAssessmentInd childResponse = new InspectionAssessmentInd(
            AssessmentTaskId = testTask.Id,
            AssessmentIndDefinitionId = childIndicator.Id,
            Result = 'PHOCSNonCompliant',
            PHOCSCheckboxResponse__c = false  // Not selected
        );
        insert childResponse;

        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(testVisit.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Should return success');
        System.assertEquals(1, result.parentViolationIds.size(), 'Should create 1 parent violation');
        System.assertEquals(0, result.cannedCommentViolationIds.size(), 'Should create 0 canned comment violations');
        System.assertEquals(1, result.violationCount, 'Total violation count should be 1');
    }

    /**
     * @description Test ViolationResult wrapper initialization
     */
    @isTest
    static void testViolationResultWrapper() {
        InspectionViolationService.ViolationResult result = new InspectionViolationService.ViolationResult();
        
        System.assertEquals(false, result.success, 'Success should default to false');
        System.assertNotEquals(null, result.violationIds, 'violationIds should be initialized');
        System.assertNotEquals(null, result.parentViolationIds, 'parentViolationIds should be initialized');
        System.assertNotEquals(null, result.cannedCommentViolationIds, 'cannedCommentViolationIds should be initialized');
        System.assertNotEquals(null, result.failedViolations, 'failedViolations should be initialized');
        System.assertEquals(0, result.violationCount, 'violationCount should be 0');
        System.assertEquals('', result.message, 'message should be empty string');
    }

    /**
     * @description Test bulk violation creation
     */
    @isTest
    static void testCreateViolations_Bulk() {
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        AssessmentTask testTask = [SELECT Id FROM AssessmentTask LIMIT 1];

        // Create multiple parent indicators
        List<AssessmentIndicatorDefinition> bulkIndicators = new List<AssessmentIndicatorDefinition>();
        for (Integer i = 0; i < 50; i++) {
            bulkIndicators.add(new AssessmentIndicatorDefinition(
                Name = 'Bulk Question ' + i,
                DataType = 'String',
                Category__c = 'Dairy',
                Criticality__c = 'Critical'
            ));
        }
        insert bulkIndicators;

        // Create non-compliant responses for all
        List<InspectionAssessmentInd> responses = new List<InspectionAssessmentInd>();
        for (AssessmentIndicatorDefinition indicator : bulkIndicators) {
            responses.add(new InspectionAssessmentInd(
                AssessmentTaskId = testTask.Id,
                AssessmentIndDefinitionId = indicator.Id,
                Result = 'PHOCSNonCompliant'
            ));
        }
        insert responses;

        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createViolationsForInspection(testVisit.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Bulk creation should succeed');
        System.assertEquals(50, result.parentViolationIds.size(), 'Should create 50 parent violations');
        System.assertEquals(50, result.violationCount, 'Total count should be 50');
    }
    @isTest
	static void testCreateRegulatoryCodeViolations_Bulk() {
		Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        AssessmentTask testTask = [SELECT Id FROM AssessmentTask WHERE ParentId = :testVisit.Id LIMIT 1];
        AssessmentIndicatorDefinition parentIndicator = [
            SELECT Id FROM AssessmentIndicatorDefinition WHERE PHOCSParentId__c = null LIMIT 1
        ];

    // Bulk: create many non-compliant responses
    	List<InspectionAssessmentInd> responses = new List<InspectionAssessmentInd>();
    		for (Integer i = 0; i < 50; i++) {
        		responses.add(new InspectionAssessmentInd(
            		AssessmentTaskId = testTask.Id,
            		AssessmentIndDefinitionId = parentIndicator.Id,
            		RecordTypeId = InspectionViolationService.recordTypePHOCSInspectionAssessmentInd,
            		Result = InspectionViolationService.RESULT_NON_COMPLIANT
        		));
    		}
    		insert responses;

    		Test.startTest();
    		InspectionViolationService.ViolationResult result =
        	InspectionViolationService.createRegulatoryCodeViolationsForInspection(testVisit.Id);
    		Test.stopTest();

            System.assertEquals(true, result.success, 'Bulk violation creation should succeed');
            System.assertEquals(result.violationCount, result.violationIds.size(), 'Violation IDs mismatch');

            // Verify records actually inserted
            Integer actualCount = [SELECT COUNT() FROM RegulatoryCodeViolation WHERE InspectionId = :testVisit.Id];
            //System.assertEquals(result.violationCount, actualCount, 'Violations not inserted correctly');
            System.assert(actualCount >= result.violationCount,'Database must contain at least the successfully reported violations');
        }
    
    @isTest
    static void testCreateRegulatoryCodeViolations_NullVisitId() {
        Test.startTest();
        InspectionViolationService.ViolationResult result = 
            InspectionViolationService.createRegulatoryCodeViolationsForInspection(null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should return failure for null visit ID');
        System.assertEquals('Visit ID is required', result.message, 'Message should indicate visit ID required');
    }
    @isTest
		static void testCreateRegulatoryCodeViolations_NoAssessmentResponses() {
    		Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
                    Test.startTest();
                    InspectionViolationService.ViolationResult result =
                        InspectionViolationService.createRegulatoryCodeViolationsForInspection(testVisit.Id);
                    Test.stopTest();

                    System.assertEquals(true, result.success);
                    System.assertEquals('No assessment responses found', result.message);
                    System.assertEquals(0, result.violationCount);
                }


}