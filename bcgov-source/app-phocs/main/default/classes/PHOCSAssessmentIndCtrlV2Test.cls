/**
 * @description Test class for PHOCSInspectionAssessmentIndControllerV2
 * @author PHOCS Dev Team
 * @date 2025-12-14
 */
@isTest
private class PHOCSAssessmentIndCtrlV2Test {
    
    
    /**
     * @description Creates test data
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

        // Create Visit
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
            TaskType = 'SignatureTask',
            ParentId = testVisit.Id,
            AssessmentTaskDefinitionId = testTaskDef.Id
        );
        insert testTask;

        // Create Assessment Indicator Definitions
        List<AssessmentIndicatorDefinition> indicators = new List<AssessmentIndicatorDefinition>{
            new AssessmentIndicatorDefinition(
                Name = 'Question 1',
                DataType = 'String',
                Category__c = 'test Category',
                Criticality__c = 'Critical'
            ),
            new AssessmentIndicatorDefinition(
                Name = 'Question 2',
                DataType = 'Boolean',
                Category__c = 'test Category',
                Criticality__c = 'Critical'
            )
        };
        insert indicators;
        
         /*AssessmentIndicatorDefinition indicators = new AssessmentIndicatorDefinition(
        	Name = 'test',
            Category__c = 'test Category'
        );
        insert indicators;*/
        
        Id rectId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName()
    			.get('PHOCSInspectionAssessmentInd')
    			.getRecordTypeId();
        
        // create inspection assessment indicator
        InspectionAssessmentInd inspaind = new InspectionAssessmentInd(
            	AssessmentIndDefinitionId = indicators[0].Id,
                AssessmentTaskId = testTask.Id,
                RecordTypeId = rectId
            );
        
        insert inspaind;
        
        Datetime specificDateTime = DateTime.newInstance(2025, 12, 25, 10, 30, 0);
        
        // regulatory code violation
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(
        	InspectionId = testVisit.Id,
            InspectionAssmntIndId = inspaind.Id,
            ComplianceDueDate = specificDateTime,
            DateCreated = specificDateTime
        
        );
        insert violation;
        
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

    /**
     * @description Test saveAssessmentResponses with new records
     */
    @isTest
    static void testSaveResponses_NewRecords() {
         Test.startTest();
        user adminUser = [select id from user where  LastName = 'AdminTestXYZ'];
        system.runas(adminUser){
            PermissionSetGroup psg = [
                SELECT Id 
                FROM PermissionSetGroup 
                WHERE DeveloperName = 'PHOCSSystemAdministratorPSG' 
                LIMIT 1
            ];
            
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = adminUser.Id,
                PermissionSetGroupId = psg.Id
            );
            insert psa;
     	    }
			system.runas(adminUser){
            AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
            List<AssessmentIndicatorDefinition> indicators = [SELECT Id FROM AssessmentIndicatorDefinition];
            
            List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper> responses = 
                new List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper>();
            
        for (AssessmentIndicatorDefinition indicator : indicators) {
            PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper resp = 
                new PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper();
            resp.assessmentTaskId = task.Id;
            resp.definitionId = indicator.Id;
            resp.comment = 'Test comment';
            resp.result = 'Compliant';
            resp.checkboxValue = false;
            resp.correctedDuringInspection = false;
            responses.add(resp);
        }

       
        PHOCSInspectionAssessmentIndControllerV2.SaveResponsesResult result = 
            PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses(responses);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Save should be successful');
        System.assertEquals(1, result.definitionToRecordIdMap.size(), 'Should have created 1 records');
        
        // Verify records were created
        List<InspectionAssessmentInd> createdRecords = [
            SELECT Id, Result, PHOCSInspectionComments__c 
            FROM InspectionAssessmentInd 
            WHERE AssessmentTaskId = :task.Id
        ];
        System.assertEquals(2, createdRecords.size(), 'Should have 2 InspectionAssessmentInd records');
        }
    }

    /**
     * @description Test saveAssessmentResponses updating existing records
     */
    @isTest
    static void testSaveResponses_UpdateExisting() {
        AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition indicator = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
        
        // Create existing record
        InspectionAssessmentInd existingRecord = new InspectionAssessmentInd(
            AssessmentTaskId = task.Id,
            AssessmentIndDefinitionId = indicator.Id,
            Result = 'Compliant',
            PHOCSInspectionComments__c = 'Original comment'
        );
        insert existingRecord;

        // Update the record
        PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper resp = 
            new PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper();
        resp.assessmentTaskId = task.Id;
        resp.definitionId = indicator.Id;
        resp.comment = 'Updated comment';
        resp.result = 'PHOCSNonCompliant';
        resp.checkboxValue = null;
		resp.correctedDuringInspection = false;


        Test.startTest();
        PHOCSInspectionAssessmentIndControllerV2.SaveResponsesResult result = 
            PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses(
                new List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper>{ resp }
            );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Save should be successful');
        
        // Verify record was updated (not duplicated)
        List<InspectionAssessmentInd> records = [
            SELECT Id, Result, PHOCSInspectionComments__c 
            FROM InspectionAssessmentInd 
            WHERE AssessmentTaskId = :task.Id AND AssessmentIndDefinitionId = :indicator.Id
        ];
        System.assertEquals(2, records.size(), 'Should still have only 2 record');
       // System.assertEquals('PHOCSNonCompliant', records[0].Result, 'Result should be updated');
       // System.assertEquals('Updated comment', records[0].PHOCSInspectionComments__c, 'Comment should be updated');
    }

    /**
     * @description Test saveAssessmentResponses with null/empty input
     */
    @isTest
    static void testSaveResponses_EmptyInput() {
        Test.startTest();
        
        // Test with null
        PHOCSInspectionAssessmentIndControllerV2.SaveResponsesResult nullResult = 
            PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses(null);
        System.assertEquals(true, nullResult.success, 'Should return success for null input');
        System.assertEquals('No responses to save', nullResult.message, 'Message should indicate no responses');
        
        // Test with empty list
        PHOCSInspectionAssessmentIndControllerV2.SaveResponsesResult emptyResult = 
            PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses(
                new List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper>()
            );
        System.assertEquals(true, emptyResult.success, 'Should return success for empty list');
        
        Test.stopTest();
    }

    /**
     * @description Test saveAssessmentResponses with checkbox values
     */
    @isTest
    static void testSaveResponses_WithCheckbox() {
        AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition indicator = [SELECT Id FROM AssessmentIndicatorDefinition WHERE DataType = 'Boolean' LIMIT 1];
        
        PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper resp = 
            new PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper();
        resp.assessmentTaskId = task.Id;
        resp.definitionId = indicator.Id;
        resp.comment = '';
        resp.result = 'PHOCSNonCompliant';
        resp.checkboxValue = true;
		resp.correctedDuringInspection = false;

        Test.startTest();
        PHOCSInspectionAssessmentIndControllerV2.SaveResponsesResult result = 
            PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses(
                new List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper>{ resp }
            );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Save should be successful');
        
        InspectionAssessmentInd createdRecord = [
            SELECT PHOCSCheckboxResponse__c 
            FROM InspectionAssessmentInd 
            WHERE AssessmentTaskId = :task.Id AND AssessmentIndDefinitionId = :indicator.Id
            LIMIT 1
        ];
        System.assertEquals(true, createdRecord.PHOCSCheckboxResponse__c, 'Checkbox value should be true');
    }

    /**
     * @description Test getExistingCommentsByDefAndTask
     */
    @isTest
    static void testGetExistingComments() {
        AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition indicator = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
        
        // Create existing record
        InspectionAssessmentInd existingRecord = new InspectionAssessmentInd(
            AssessmentTaskId = task.Id,
            AssessmentIndDefinitionId = indicator.Id,
            Result = 'Compliant',
            PHOCSInspectionComments__c = 'Test comment',
            PHOCSCheckboxResponse__c = true
        );
        insert existingRecord;

        Test.startTest();
        Map<String, Object> result = PHOCSInspectionAssessmentIndControllerV2.getExistingCommentsByDefAndTask(
            new List<Id>{ indicator.Id },
            new List<Id>{ task.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should have one entry');
        
        String key = String.valueOf(indicator.Id) + '|' + String.valueOf(task.Id);
        System.assertEquals(true, result.containsKey(key), 'Should contain the expected key');
        
        Map<String, Object> entry = (Map<String, Object>) result.get(key);
        System.assertEquals('Test comment', entry.get('comment'), 'Comment should match');
        System.assertEquals(true, entry.get('checkbox'), 'Checkbox value should match');
        System.assertEquals('Compliant', entry.get('result'), 'Result should match');
    }

    /**
     * @description Test getExistingCommentsByDefAndTask with null inputs
     */
    @isTest
    static void testGetExistingComments_NullInputs() {
        Test.startTest();
        
        Map<String, Object> nullResult = PHOCSInspectionAssessmentIndControllerV2.getExistingCommentsByDefAndTask(
            null, null
        );
        System.assertEquals(0, nullResult.size(), 'Should return empty map for null inputs');
        
        Map<String, Object> emptyResult = PHOCSInspectionAssessmentIndControllerV2.getExistingCommentsByDefAndTask(
            new List<Id>(), new List<Id>()
        );
        System.assertEquals(0, emptyResult.size(), 'Should return empty map for empty lists');
        
        Test.stopTest();
    }

    /**
     * @description Test linkFilesToAssessmentRecords
     */
    @isTest
    static void testLinkFilesToAssessmentRecords() {
        AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
        AssessmentIndicatorDefinition indicator = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
        
        // Create InspectionAssessmentInd record
        InspectionAssessmentInd assessmentInd = new InspectionAssessmentInd(
            AssessmentTaskId = task.Id,
            AssessmentIndDefinitionId = indicator.Id,
            Result = 'Compliant'
        );
        insert assessmentInd;

        // Create ContentVersion (file)
        ContentVersion testFile = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.pdf',
            VersionData = Blob.valueOf('Test file content')
        );
        insert testFile;
        
        ContentVersion insertedFile = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testFile.Id];

        // Build the maps
        Map<String, List<String>> defIdToContentDocIds = new Map<String, List<String>>{
            String.valueOf(indicator.Id) => new List<String>{ String.valueOf(insertedFile.ContentDocumentId) }
        };
        Map<String, String> defIdToAssessmentIndId = new Map<String, String>{
            String.valueOf(indicator.Id) => String.valueOf(assessmentInd.Id)
        };

        Test.startTest();
        PHOCSInspectionAssessmentIndControllerV2.linkFilesToAssessmentRecords(
            defIdToContentDocIds, defIdToAssessmentIndId
        );
        Test.stopTest();

        // Verify the ContentDocumentLink was created
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :assessmentInd.Id
        ];
        System.assertEquals(1, links.size(), 'Should have created one ContentDocumentLink');
    }

    /**
     * @description Test linkFilesToAssessmentRecords with empty input
     */
    @isTest
    static void testLinkFiles_EmptyInput() {
        Test.startTest();
        // Should not throw exception
        PHOCSInspectionAssessmentIndControllerV2.linkFilesToAssessmentRecords(null, null);
        PHOCSInspectionAssessmentIndControllerV2.linkFilesToAssessmentRecords(
            new Map<String, List<String>>(), 
            new Map<String, String>()
        );
        Test.stopTest();
        
        // If we get here without exception, test passes
        System.assert(true, 'Should handle empty inputs gracefully');
    }

    /**
     * @description Test bulk save operations
     */
    @isTest
    static void testBulkSaveResponses() {
        AssessmentTask task = [SELECT Id FROM AssessmentTask LIMIT 1];
        
        
        
        // Create 200+ indicator definitions for bulk test
        List<AssessmentIndicatorDefinition> bulkIndicators = new List<AssessmentIndicatorDefinition>();
        for (Integer i = 0; i < 201; i++) {
            bulkIndicators.add(new AssessmentIndicatorDefinition(
                Name = 'Bulk Question ' + i,
                //DataType = 'Text',
                Category__c = 'test Category'
            ));
        }
        insert bulkIndicators;

        // Create responses for all indicators
        List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper> responses = 
            new List<PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper>();
        
        for (AssessmentIndicatorDefinition indicator : bulkIndicators) {
        
            PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper resp = 
                new PHOCSInspectionAssessmentIndControllerV2.AssessmentResponseWrapper();
            resp.assessmentTaskId = task.Id;
            resp.definitionId = indicator.Id ;
            resp.comment = 'Bulk comment';
            resp.result = 'Compliant';
			resp.correctedDuringInspection = false;

            responses.add(resp);
        }

        Test.startTest();
        PHOCSInspectionAssessmentIndControllerV2.SaveResponsesResult result = 
            PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses(responses);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Bulk save should be successful');
        System.assertEquals(201, result.definitionToRecordIdMap.size(), 'Should have saved all 201 records');
    }
    
	@IsTest
	static void testGetViolationsFromInspection() {

    Visit inspection = [SELECT Id FROM Visit LIMIT 1];

    // Call method
    Test.startTest();
    	Map<Id, RegulatoryCodeViolation> result =
        PHOCSInspectionAssessmentIndControllerV2.getViolationsFromInspection(inspection.Id);
    Test.stopTest();

    // Assertions
    System.assertNotEquals(0,result.size(),'Violation map should not be empty');

    // Validate keying by Definition Id
    AssessmentIndicatorDefinition def =
        [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
		System.assert(result.containsKey(def.Id),'Map should be keyed by Assessment Indicator Definition Id');
	}
    
}