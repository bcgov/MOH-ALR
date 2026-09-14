/**********************************************************************************************
* @Author:      Accenture
* @Date:        24 Aug 2026
* @Description: The purpose of this class is to cover code coverage of
*                PHOCSCCFLViolationAssessmentController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               24 Aug -  PHOCS-4817        -  Deepak      -  Initial test class for getViolations.
*               01 Sep -  PHOCS-4817        -  Deepak      -  Added test coverage for getReassessmentViolations.
*               01 Sep -  PHOCS-4817        -  Deepak      -  Added required Name field on Assessment inserts and corrected Scope__c/Severity__c to valid restricted picklist values.
*               01 Sep -  PHOCS-271         -  Deepak      -  Updated matched-violation test to assert the completed violation's own data is displayed (not the current violation's), and added coverage for selected being gated on the completed violation's Scope/Severity.
*               03 Sep -  PHOCS-271         -  Deepak      -  getReassessmentViolations now requires a SelectedViolationsJSON__c match (by violationId, falling back to category/inspectionQuestion) to prepopulate a matched violation. Updated the two matched-violation tests to populate SelectedViolationsJSON__c, and added coverage for the category/inspectionQuestion fallback match and for a composite-key match with no corresponding JSON entry.
***********************************************************************************************/
@isTest
public class PHOCSCCFLViolationAsmntControllerTest {    
    public static Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public static Id recordTypePHOCSInspectionType = Schema.SObjectType.InspectionType.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionType').getRecordTypeId();
    public static Id recordTypePHOCSDairyAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();
    public static Id recordTypePHOCSAssessment = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
    
    /**
* @author: Deepak
* @date: 24 Aug 2026
* @description: The purpose of this method is to create common test data, including a Regulatory
*                Authority and Regulatory Code lookup record, and return a map of key record Ids
*                for use across all test methods.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, Id> createTestData() {
        Account acc = new Account(Name = 'Test Dairy Facility', Type = 'Dairy', RecordTypeId = recordTypePHOCSDairyAccount);
        insert acc;
        
        Schema.Location loc = new Schema.Location(Name = 'Test Location', Longitude = 27.635308, Latitude = 29.635308);
        insert loc;
        
        InspectionType inspType = new InspectionType(Name = 'Test Inspection Type', InspectionTypes__c = 'Routine', Description = 'Test', RecordTypeId = recordTypePHOCSInspectionType);
        insert inspType;
        
        Visit insp = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = acc.Id, PlaceId = loc.Id, PlannedVisitStartTime = System.now(), RecordTypeId = recordTypePHOCSInspection, VisitTypeId = inspType.Id);
        insert insp;
        
        AssessmentIndicatorDefinition indDef = new AssessmentIndicatorDefinition(Name = 'Test Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean');
        insert indDef;
        
        AssessmentTaskDefinition taskDef = new AssessmentTaskDefinition(Name = 'Test Task Definition', TaskType = 'InspectionChecklist');
        insert taskDef;
        
        AssessmentTask assessmentTask = new AssessmentTask(Name = 'Test Assessment Task', ParentId = insp.Id, AssessmentTaskDefinitionId = taskDef.Id, TaskType = 'InspectionChecklist');
        insert assessmentTask;
        
        InspectionAssessmentInd inspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = assessmentTask.Id, AssessmentIndDefinitionId = indDef.Id);
        insert inspAsmInd;
        
        RegulatoryAuthority regAuth = new RegulatoryAuthority(Name = 'Test Regulatory Authority');
        insert regAuth;
        
        RegulatoryCode regCode = new RegulatoryCode(Name = 'Test Regulatory Code', Subject = 'Test Subject', Description = 'Test Description', RegulatoryAuthorityId = regAuth.Id, EffectiveFrom = System.today());
        insert regCode;
        
        Map<String, Id> dataMap = new Map<String, Id>();
        dataMap.put('facilityId', acc.Id);
        dataMap.put('locationId', loc.Id);
        dataMap.put('inspId', insp.Id);
        dataMap.put('inspAsmIndId', inspAsmInd.Id);
        dataMap.put('regCodeId', regCode.Id);
        dataMap.put('indDefId', indDef.Id);
        dataMap.put('assessmentTaskId', assessmentTask.Id);
        dataMap.put('assessmentTaskDefinitionId', taskDef.Id);
        
        return dataMap;
    }
    
    /**
* @author: Deepak
* @date: 24 Aug 2026
* @description: The purpose of this method is to cover positive test coverage of getViolations, verifying
*                that a top-level Open violation is returned and its wrapper fields are correctly populated.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetViolations_ReturnsTopLevelOpenViolation() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                        InspectionAssmntIndId = dataMap.get('inspAsmIndId'), RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                        ComplianceDueDate = System.now().addDays(5), DateCreated = System.now(), Status = 'Open');
        insert violation;
        
        Test.startTest();
        List<PHOCSCCFLViolationAssessmentController.ViolationWrapper> results = PHOCSCCFLViolationAssessmentController.getViolations(dataMap.get('inspId'));
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'One top-level Open violation should be returned.');
        Assert.areEqual(violation.Id, results[0].id, 'Returned wrapper Id should match the inserted violation Id.');
        Assert.areEqual('Test Regulatory Code', results[0].regulatoryCode, 'RegulatoryCode name should be populated on the wrapper.');
        Assert.areEqual('Test Description', results[0].regulatoryCodeDescription, 'RegulatoryCode description should be populated on the wrapper.');
        Assert.areEqual('Test Assessment Task', results[0].category, 'Category should reflect the related AssessmentTask name.');
        Assert.areEqual('Test Assessment Definition', results[0].inspectionQuestion, 'Inspection question should reflect the related AssessmentIndDefinition name.');
    }
    
    /**
* @author: Deepak
* @date: 24 Aug 2026
* @description: The purpose of this method is to cover negative test coverage of getViolations when a null
*                Inspection Id is passed, verifying an AuraHandledException is thrown.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetViolations_NullInspectionId_ThrowsException() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            PHOCSCCFLViolationAssessmentController.getViolations(null);
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'An AuraHandledException should be thrown when Inspection Id is null.');
    }
    
    /**
* @author: Deepak
* @date: 24 Aug 2026
* @description: The purpose of this method is to verify that violations are excluded from getViolations
*                when their related Assessment Indicator Definition has a parent definition set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetViolations_ExcludesChildViolations() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation parentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                              InspectionAssmntIndId = dataMap.get('inspAsmIndId'), RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                              ComplianceDueDate = System.now().addDays(5), DateCreated = System.now(), Status = 'Open');
        insert parentViolation;
        
        AssessmentIndicatorDefinition childIndDef = new AssessmentIndicatorDefinition(Name = 'Test Child Assessment Definition', Category__c = 'Compliance',
                                                                                      DataType = 'Boolean', PHOCSParentId__c = dataMap.get('indDefId'));
        insert childIndDef;
        
        InspectionAssessmentInd childInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = dataMap.get('assessmentTaskId'), AssessmentIndDefinitionId = childIndDef.Id);
        insert childInspAsmInd;
        
        RegulatoryCodeViolation childViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                             InspectionAssmntIndId = childInspAsmInd.Id, RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                             ComplianceDueDate = System.now().addDays(5), DateCreated = System.now(), Status = 'Open');
        insert childViolation;
        
        Test.startTest();
        List<PHOCSCCFLViolationAssessmentController.ViolationWrapper> results = PHOCSCCFLViolationAssessmentController.getViolations(dataMap.get('inspId'));
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Only the violation linked to a top-level Assessment Indicator Definition should be returned.');
        Assert.areEqual(parentViolation.Id, results[0].id, 'Returned violation should be the one whose Assessment Indicator Definition has no parent.');
    }
    
    /**
* @author: Deepak
* @date: 24 Aug 2026
* @description: The purpose of this method is to verify that violations not in Open status are excluded
*                from the results returned by getViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetViolations_ExcludesNonOpenStatus() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation resolvedViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                                ComplianceDueDate = System.now().addDays(5), DateCreated = System.now(), Status = 'Resolved');
        insert resolvedViolation;
        
        Test.startTest();
        List<PHOCSCCFLViolationAssessmentController.ViolationWrapper> results = PHOCSCCFLViolationAssessmentController.getViolations(dataMap.get('inspId'));
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Resolved violations should not be returned by getViolations.');
    }
    
    /**
* @author: Deepak
* @date: 24 Aug 2026
* @description: The purpose of this method is to cover the scenario where no violations exist for the
*                given Inspection, verifying an empty list is returned without error.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetViolations_NoViolations_ReturnsEmptyList() {
        Map<String, Id> dataMap = createTestData();
        
        Test.startTest();
        List<PHOCSCCFLViolationAssessmentController.ViolationWrapper> results = PHOCSCCFLViolationAssessmentController.getViolations(dataMap.get('inspId'));
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'An empty list should be returned when no violations exist for the Inspection.');
    }
    
    /**
* @author: Deepak
* @date: 01 Sep 2026
* @description: Verifies that hasCompletedAssessment is false and no violations are returned when
*                the Facility does not have a completed Risk Assessment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_NoCompletedAssessment() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                        InspectionAssmntIndId = dataMap.get('inspAsmIndId'), RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                        ComplianceDueDate = System.now().addDays(5), DateCreated = System.now(), Status = 'Open');
        insert violation;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.isFalse(result.hasCompletedAssessment, 'hasCompletedAssessment should be false when no completed Risk Assessment exists.');
        Assert.areEqual(null, result.completedAssessmentId, 'completedAssessmentId should be null when no completed Risk Assessment exists.');
        Assert.areEqual(0, result.violations.size(), 'No violations should be returned when no completed Risk Assessment exists.');
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Verifies that when a current violation's slot matches a completed violation via
*                the composite key, AND the completed Assessment's SelectedViolationsJSON__c has
*                an entry whose violationId matches the completed violation's own Id, the returned
*                wrapper displays the completed violation's own data (Id, category) and is
*                prepopulated/selected from that JSON entry's Scope and Severity.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_MatchedByJsonViolationId_DisplaysCompletedViolationAndSelected() {
        Map<String, Id> dataMap = createTestData();
        
        Account facility = [SELECT Id FROM Account WHERE Id = :dataMap.get('facilityId') LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location WHERE Id = :dataMap.get('locationId') LIMIT 1];
        InspectionType inspType = [SELECT Id FROM InspectionType LIMIT 1];
        
        Visit completedInspection = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = facility.Id, PlaceId = loc.Id,
                                              PlannedVisitStartTime = System.now().addDays(-10), RecordTypeId = recordTypePHOCSInspection,
                                              VisitTypeId = inspType.Id);
        insert completedInspection;
        
        AssessmentTask completedAssessmentTask = new AssessmentTask(Name = 'Completed Assessment Task', ParentId = completedInspection.Id,
                                                                    AssessmentTaskDefinitionId = dataMap.get('assessmentTaskDefinitionId'),
                                                                    TaskType = 'InspectionChecklist');
        insert completedAssessmentTask;
        
        InspectionAssessmentInd completedInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = completedAssessmentTask.Id,
                                                                                  AssessmentIndDefinitionId = dataMap.get('indDefId'));
        insert completedInspAsmInd;
        
        RegulatoryCodeViolation completedViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                                 InspectionId = completedInspection.Id,
                                                                                 InspectionAssmntIndId = completedInspAsmInd.Id,
                                                                                 RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                                 ComplianceDueDate = System.now().addDays(5),
                                                                                 DateCreated = System.now(),
                                                                                 Status = 'Open');
        insert completedViolation;
        
        String selectedViolationsJson = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{
                'violationId' => String.valueOf(completedViolation.Id),
                'category' => 'Completed Assessment Task',
                'regulatoryCode' => 'Test Regulatory Code',
                'inspectionQuestion' => 'Test Assessment Definition',
                'scope' => 'Isolated',
                'severity' => 'Potential for minimal harm',
                'comments' => null
            }
        });
        
        Assessment completedAssessment = new Assessment(Name = 'Test Completed Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = facility.Id,
                                                        ResponseContextId = completedInspection.Id, Type = 'Risk Assessment',
                                                        AssessmentStatus = 'Completed', SelectedViolationsJSON__c = selectedViolationsJson);
        insert completedAssessment;
        
        RegulatoryCodeViolation currentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                               InspectionId = dataMap.get('inspId'),
                                                                               InspectionAssmntIndId = dataMap.get('inspAsmIndId'),
                                                                               RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                               ComplianceDueDate = System.now().addDays(5),
                                                                               DateCreated = System.now(),
                                                                               Status = 'Open');
        insert currentViolation;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.isTrue(result.hasCompletedAssessment, 'hasCompletedAssessment should be true when a completed Risk Assessment exists.');
        Assert.areEqual(completedAssessment.Id, result.completedAssessmentId, 'The completed Assessment Id should be returned.');
        Assert.areEqual(1, result.violations.size(), 'One matched violation slot should be returned.');
        Assert.areEqual(completedViolation.Id, result.violations[0].id, 'On a match, the wrapper should display the completed violation, not the current violation.');
        Assert.areEqual('Completed Assessment Task', result.violations[0].category, 'Category should reflect the completed violations own AssessmentTask, not the current violations.');
        Assert.isTrue(result.violations[0].selected, 'The violation should be selected when the matched JSON entry has both Scope and Severity populated.');
        Assert.areEqual('Isolated', result.violations[0].scope, 'Scope should come from the matched SelectedViolationsJSON__c entry.');
        Assert.areEqual('Potential for minimal harm', result.violations[0].severity, 'Severity should come from the matched SelectedViolationsJSON__c entry.');
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Verifies that when the matched JSON entry (by violationId) has null Scope/Severity,
*                the wrapper still displays the completed violation's own data but is not selected.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_MatchedJsonEntryMissingScopeOrSeverity_NotSelected() {
        Map<String, Id> dataMap = createTestData();
        
        Account facility = [SELECT Id FROM Account WHERE Id = :dataMap.get('facilityId') LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location WHERE Id = :dataMap.get('locationId') LIMIT 1];
        InspectionType inspType = [SELECT Id FROM InspectionType LIMIT 1];
        
        Visit completedInspection = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = facility.Id, PlaceId = loc.Id,
                                              PlannedVisitStartTime = System.now().addDays(-10), RecordTypeId = recordTypePHOCSInspection,
                                              VisitTypeId = inspType.Id);
        insert completedInspection;
        
        AssessmentTask completedAssessmentTask = new AssessmentTask(Name = 'Completed Assessment Task No Scope', ParentId = completedInspection.Id,
                                                                    AssessmentTaskDefinitionId = dataMap.get('assessmentTaskDefinitionId'),
                                                                    TaskType = 'InspectionChecklist');
        insert completedAssessmentTask;
        
        InspectionAssessmentInd completedInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = completedAssessmentTask.Id,
                                                                                  AssessmentIndDefinitionId = dataMap.get('indDefId'));
        insert completedInspAsmInd;
        
        RegulatoryCodeViolation completedViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                                 InspectionId = completedInspection.Id,
                                                                                 InspectionAssmntIndId = completedInspAsmInd.Id,
                                                                                 RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                                 ComplianceDueDate = System.now().addDays(5),
                                                                                 DateCreated = System.now(),
                                                                                 Status = 'Open');
        insert completedViolation;
        
        String selectedViolationsJson = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{
                'violationId' => String.valueOf(completedViolation.Id),
                'category' => 'Completed Assessment Task No Scope',
                'regulatoryCode' => 'Test Regulatory Code',
                'inspectionQuestion' => 'Test Assessment Definition',
                'scope' => null,
                'severity' => null,
                'comments' => null
            }
        });
        
        Assessment completedAssessment = new Assessment(Name = 'Test Completed Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = facility.Id,
                                                        ResponseContextId = completedInspection.Id, Type = 'Risk Assessment',
                                                        AssessmentStatus = 'Completed', SelectedViolationsJSON__c = selectedViolationsJson);
        insert completedAssessment;
        
        RegulatoryCodeViolation currentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                               InspectionId = dataMap.get('inspId'),
                                                                               InspectionAssmntIndId = dataMap.get('inspAsmIndId'),
                                                                               RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                               ComplianceDueDate = System.now().addDays(5),
                                                                               DateCreated = System.now(),
                                                                               Status = 'Open');
        insert currentViolation;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.areEqual(1, result.violations.size(), 'One matched violation slot should be returned.');
        Assert.areEqual(completedViolation.Id, result.violations[0].id, 'On a JSON violationId match, the wrapper should display the completed violation even when Scope/Severity are null.');
        Assert.isFalse(result.violations[0].selected, 'The violation should not be selected when the matched JSON entry is missing Scope or Severity.');
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Verifies the category/inspectionQuestion fallback match: when the JSON's
*                violationId does not correspond to the matched completed violation's Id, but a
*                JSON entry's category/inspectionQuestion matches the current violation's
*                Assessment Task/Indicator Definition names, Scope and Severity are still
*                prepopulated from that entry.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_MatchedByCategoryAndQuestionFallback_PrepopulatesScopeSeverity() {
        Map<String, Id> dataMap = createTestData();
        
        Account facility = [SELECT Id FROM Account WHERE Id = :dataMap.get('facilityId') LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location WHERE Id = :dataMap.get('locationId') LIMIT 1];
        InspectionType inspType = [SELECT Id FROM InspectionType LIMIT 1];
        
        Visit completedInspection = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = facility.Id, PlaceId = loc.Id,
                                              PlannedVisitStartTime = System.now().addDays(-10), RecordTypeId = recordTypePHOCSInspection,
                                              VisitTypeId = inspType.Id);
        insert completedInspection;
        
        AssessmentTask completedAssessmentTask = new AssessmentTask(Name = 'Completed Assessment Task', ParentId = completedInspection.Id,
                                                                    AssessmentTaskDefinitionId = dataMap.get('assessmentTaskDefinitionId'),
                                                                    TaskType = 'InspectionChecklist');
        insert completedAssessmentTask;
        
        InspectionAssessmentInd completedInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = completedAssessmentTask.Id,
                                                                                  AssessmentIndDefinitionId = dataMap.get('indDefId'));
        insert completedInspAsmInd;
        
        RegulatoryCodeViolation completedViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                                 InspectionId = completedInspection.Id,
                                                                                 InspectionAssmntIndId = completedInspAsmInd.Id,
                                                                                 RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                                 ComplianceDueDate = System.now().addDays(5),
                                                                                 DateCreated = System.now(),
                                                                                 Status = 'Open');
        insert completedViolation;
        
        RegulatoryCodeViolation currentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                               InspectionId = dataMap.get('inspId'),
                                                                               InspectionAssmntIndId = dataMap.get('inspAsmIndId'),
                                                                               RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                               ComplianceDueDate = System.now().addDays(5),
                                                                               DateCreated = System.now(),
                                                                               Status = 'Open');
        insert currentViolation;
        
        // A JSON entry whose violationId does NOT match the completed violation's Id, so the
        // controller must fall back to matching category/inspectionQuestion against the CURRENT
        // violation's own AssessmentTask.Name ('Test Assessment Task') and
        // AssessmentIndDefinition.Name ('Test Assessment Definition'), not the completed
        // violation's task name.
        String selectedViolationsJson = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{
                'violationId' => '0fv000000000000AAA',
                'category' => 'Test Assessment Task',
                'regulatoryCode' => 'Test Regulatory Code',
                'inspectionQuestion' => 'Test Assessment Definition',
                'scope' => 'Pattern',
                'severity' => 'Potential for significant harm',
                'comments' => 'Fallback match comment'
            }
        });
        
        Assessment completedAssessment = new Assessment(Name = 'Test Completed Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = facility.Id,
                                                        ResponseContextId = completedInspection.Id, Type = 'Risk Assessment',
                                                        AssessmentStatus = 'Completed', SelectedViolationsJSON__c = selectedViolationsJson);
        insert completedAssessment;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.areEqual(1, result.violations.size(), 'One matched violation slot should be returned.');
        Assert.areEqual(completedViolation.Id, result.violations[0].id, 'The wrapper should still display the completed violation found via the composite key.');
        Assert.isTrue(result.violations[0].selected, 'The violation should be selected via the category/inspectionQuestion fallback match.');
        Assert.areEqual('Pattern', result.violations[0].scope, 'Scope should come from the category/inspectionQuestion fallback-matched JSON entry.');
        Assert.areEqual('Potential for significant harm', result.violations[0].severity, 'Severity should come from the category/inspectionQuestion fallback-matched JSON entry.');
    }
    
    /**
* @author: Deepak
* @date: 03 Sep 2026
* @description: Verifies that a composite-key match with no corresponding entry in
*                SelectedViolationsJSON__c (neither by violationId nor by category/
*                inspectionQuestion) falls back to displaying the plain current violation.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_MatchedButNoJsonEntry_DisplaysCurrentViolation() {
        Map<String, Id> dataMap = createTestData();
        
        Account facility = [SELECT Id FROM Account WHERE Id = :dataMap.get('facilityId') LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location WHERE Id = :dataMap.get('locationId') LIMIT 1];
        InspectionType inspType = [SELECT Id FROM InspectionType LIMIT 1];
        
        Visit completedInspection = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = facility.Id, PlaceId = loc.Id,
                                              PlannedVisitStartTime = System.now().addDays(-10), RecordTypeId = recordTypePHOCSInspection,
                                              VisitTypeId = inspType.Id);
        insert completedInspection;
        
        AssessmentTask completedAssessmentTask = new AssessmentTask(Name = 'Completed Assessment Task', ParentId = completedInspection.Id,
                                                                    AssessmentTaskDefinitionId = dataMap.get('assessmentTaskDefinitionId'),
                                                                    TaskType = 'InspectionChecklist');
        insert completedAssessmentTask;
        
        InspectionAssessmentInd completedInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = completedAssessmentTask.Id,
                                                                                  AssessmentIndDefinitionId = dataMap.get('indDefId'));
        insert completedInspAsmInd;
        
        RegulatoryCodeViolation completedViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                                 InspectionId = completedInspection.Id,
                                                                                 InspectionAssmntIndId = completedInspAsmInd.Id,
                                                                                 RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                                 ComplianceDueDate = System.now().addDays(5),
                                                                                 DateCreated = System.now(),
                                                                                 Status = 'Open');
        insert completedViolation;
        
        // SelectedViolationsJSON__c is left blank, so no violationId or category/inspectionQuestion
        // match is possible even though the composite key matches a completed violation.
        Assessment completedAssessment = new Assessment(Name = 'Test Completed Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = facility.Id,
                                                        ResponseContextId = completedInspection.Id, Type = 'Risk Assessment',
                                                        AssessmentStatus = 'Completed');
        insert completedAssessment;
        
        RegulatoryCodeViolation currentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                               InspectionId = dataMap.get('inspId'),
                                                                               InspectionAssmntIndId = dataMap.get('inspAsmIndId'),
                                                                               RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                               ComplianceDueDate = System.now().addDays(5),
                                                                               DateCreated = System.now(),
                                                                               Status = 'Open');
        insert currentViolation;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.areEqual(1, result.violations.size(), 'One current violation should be returned.');
        Assert.areEqual(currentViolation.Id, result.violations[0].id, 'With no matching JSON entry, the wrapper should fall back to the current violation, not the completed one.');
        Assert.isFalse(result.violations[0].selected, 'A violation with no matching JSON entry should not be selected.');
    }
    
    /**
* @author: Deepak
* @date: 01 Sep 2026
* @description: Verifies that the latest completed Risk Assessment is selected when more than one
*                completed Risk Assessment exists for the Facility.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_ReturnsLatestCompletedAssessment() {
        Map<String, Id> dataMap = createTestData();
        
        Assessment olderAssessment = new Assessment(Name = 'Older Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = dataMap.get('facilityId'),
                                                    ResponseContextId = dataMap.get('inspId'), Type = 'Risk Assessment',
                                                    AssessmentStatus = 'Completed');
        insert olderAssessment;
        
        // Both Assessments would otherwise be inserted with the same CreatedDate (down to the
        // millisecond) within this single transaction, making CreatedDate DESC LIMIT 1
        // non-deterministic. Force a real gap so "latest" is unambiguous.
        Test.setCreatedDate(olderAssessment.Id, System.now().addDays(-1));
        
        Assessment latestAssessment = new Assessment(Name = 'Latest Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = dataMap.get('facilityId'),
                                                     ResponseContextId = dataMap.get('inspId'), Type = 'Risk Assessment',
                                                     AssessmentStatus = 'Completed');
        insert latestAssessment;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.isTrue(result.hasCompletedAssessment, 'A completed Risk Assessment should be found.');
        Assert.areEqual(latestAssessment.Id, result.completedAssessmentId, 'The latest completed Risk Assessment should be returned.');
    }
    
    /**
* @author: Deepak
* @date: 01 Sep 2026
* @description: Verifies that a current violation without a matching completed Assessment violation
*                displays the current violation as-is, remains unselected, and has null Scope/Severity.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_NoMatchingViolationNotSelected() {
        Map<String, Id> dataMap = createTestData();
        
        Assessment completedAssessment = new Assessment(Name = 'Test Completed Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = dataMap.get('facilityId'),
                                                        ResponseContextId = dataMap.get('inspId'), Type = 'Risk Assessment',
                                                        AssessmentStatus = 'Completed');
        insert completedAssessment;
        
        AssessmentIndicatorDefinition differentIndDef = new AssessmentIndicatorDefinition(Name = 'Different Assessment Definition',
                                                                                          Category__c = 'Compliance',
                                                                                          DataType = 'Boolean');
        insert differentIndDef;
        
        InspectionAssessmentInd differentInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = dataMap.get('assessmentTaskId'),
                                                                                  AssessmentIndDefinitionId = differentIndDef.Id);
        insert differentInspAsmInd;
        
        RegulatoryCodeViolation currentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                               InspectionId = dataMap.get('inspId'),
                                                                               InspectionAssmntIndId = differentInspAsmInd.Id,
                                                                               RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                               ComplianceDueDate = System.now().addDays(5),
                                                                               DateCreated = System.now(),
                                                                               Status = 'Open');
        insert currentViolation;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.isTrue(result.hasCompletedAssessment, 'A completed Risk Assessment should be found.');
        Assert.areEqual(1, result.violations.size(), 'One current violation should be returned.');
        Assert.areEqual(currentViolation.Id, result.violations[0].id, 'With no match, the wrapper should display the current violation.');
        Assert.isFalse(result.violations[0].selected, 'A violation without a matching completed violation should not be selected.');
        Assert.areEqual(null, result.violations[0].scope, 'Scope should not be prepopulated when no matching violation exists.');
        Assert.areEqual(null, result.violations[0].severity, 'Severity should not be prepopulated when no matching violation exists.');
    }
    
    /**
* @author: Deepak
* @date: 01 Sep 2026
* @description: Verifies that child violations are excluded from reassessment violations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_ExcludesChildViolations() {
        Map<String, Id> dataMap = createTestData();
        
        Assessment completedAssessment = new Assessment(Name = 'Test Completed Assessment', RecordTypeId = recordTypePHOCSAssessment, AccountId = dataMap.get('facilityId'),
                                                        ResponseContextId = dataMap.get('inspId'), Type = 'Risk Assessment',
                                                        AssessmentStatus = 'Completed');
        insert completedAssessment;
        
        RegulatoryCodeViolation parentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                              InspectionId = dataMap.get('inspId'),
                                                                              InspectionAssmntIndId = dataMap.get('inspAsmIndId'),
                                                                              RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                              ComplianceDueDate = System.now().addDays(5),
                                                                              DateCreated = System.now(),
                                                                              Status = 'Open');
        insert parentViolation;
        
        AssessmentIndicatorDefinition childIndDef = new AssessmentIndicatorDefinition(Name = 'Child Assessment Definition',
                                                                                      Category__c = 'Compliance',
                                                                                      DataType = 'Boolean',
                                                                                      PHOCSParentId__c = dataMap.get('indDefId'));
        insert childIndDef;
        
        InspectionAssessmentInd childInspAsmInd = new InspectionAssessmentInd(AssessmentTaskId = dataMap.get('assessmentTaskId'),
                                                                              AssessmentIndDefinitionId = childIndDef.Id);
        insert childInspAsmInd;
        
        RegulatoryCodeViolation childViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                             InspectionId = dataMap.get('inspId'),
                                                                             InspectionAssmntIndId = childInspAsmInd.Id,
                                                                             RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                             ComplianceDueDate = System.now().addDays(5),
                                                                             DateCreated = System.now(),
                                                                             Status = 'Open');
        insert childViolation;
        
        Test.startTest();
        PHOCSCCFLViolationAssessmentController.ReassessmentResponse result = PHOCSCCFLViolationAssessmentController.getReassessmentViolations(dataMap.get('inspId'), dataMap.get('facilityId'));
        Test.stopTest();
        
        Assert.areEqual(1, result.violations.size(), 'Child violations should be excluded from reassessment results.');
        Assert.areEqual(parentViolation.Id, result.violations[0].id, 'Only the top-level violation should be returned.');
    }
    
    /**
* @author: Deepak
* @date: 01 Sep 2026
* @description: Verifies that an AuraHandledException is thrown when a null Inspection Id is passed
*                to getReassessmentViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetReassessmentViolations_NullInspectionId_ThrowsException() {
        Map<String, Id> dataMap = createTestData();
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            PHOCSCCFLViolationAssessmentController.getReassessmentViolations(null, dataMap.get('facilityId'));
        } catch (AuraHandledException ex) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        Assert.isTrue(exceptionThrown, 'An AuraHandledException should be thrown when Inspection Id is null.');
    }
}