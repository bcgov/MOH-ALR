/**********************************************************************************************
* @Author:      Accenture
* @Date:        25 Aug 2026
* @Description: Test class for PHOCSAsmntVioRelatedController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@isTest
public class PHOCSAsmntVioRelatedControllerTest {
    
    @TestSetup
    public static void setupTestData() {
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(Name = 'Test Regulatory Type');
        insert reg;
        
        Id facilityRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        
        Account testAccount = new Account(Name = 'Test Facility', LicenseType__c = reg.Id, RecordTypeId = facilityRTId);
        insert testAccount;
        
        ContactPointAddress cpa = new ContactPointAddress(Name = 'Test Address', Street = '123 Test Lane', City = 'Alberta', State = 'AL', Country = 'Canada', PostalCode = 'M2H2E4');
        insert cpa;
        
        Id visitRTId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
        
        Visit testVisit = new Visit(AccountId = testAccount.Id, PlaceId = cpa.Id, RecordTypeId = visitRTId, PlannedVisitStartTime = DateTime.now(), PlannedVisitEndTime = DateTime.now().addHours(2));
        insert testVisit;
        
        AssessmentTaskDefinition testTaskDef = new AssessmentTaskDefinition(Name = 'Test Category', TaskType = 'InspectionChecklist');
        insert testTaskDef;
        
        AssessmentTask testTask = new AssessmentTask(Name = 'Test Task', TaskType = 'SignatureTask', ParentId = testVisit.Id, AssessmentTaskDefinitionId = testTaskDef.Id);
        insert testTask;
        
        AssessmentIndicatorDefinition indicator = new AssessmentIndicatorDefinition(Name = 'Question 1', DataType = 'String', Category__c = 'Test Category', Criticality__c = 'Critical', PHOCSParentId__c = null);
        insert indicator;
        
        Id inspAmntRTId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
        
        InspectionAssessmentInd inspAssmntInd = new InspectionAssessmentInd(AssessmentIndDefinitionId = indicator.Id, AssessmentTaskId = testTask.Id, RecordTypeId = inspAmntRTId);
        insert inspAssmntInd;
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(InspectionId = testVisit.Id, InspectionAssmntIndId = inspAssmntInd.Id, ComplianceDueDate = System.now().addDays(2), DateCreated = System.now(), Status = 'Open', Scope__c = 'Isolated', Severity__c = 'Potential for significant harm');
        insert violation;
        
        Id assessmentRTId = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
        
        Assessment assessment = new Assessment(Name = 'Test Assessment', RecordTypeId = assessmentRTId, ResponseContextId = testVisit.Id, AssessmentStatus = 'In Progress');
        insert assessment;
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that null Assessment Id returns an empty list.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_NullAssessmentId() {
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(null);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(0, result.size(), 'Null Assessment Id should return an empty list.');
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that an invalid Assessment Id returns an empty list.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_InvalidAssessmentId() {
        Id assessmentId = '001000000000001AAA';
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessmentId);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(0, result.size(), 'An invalid Assessment Id should return an empty list.');
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that an Assessment without ResponseContextId returns an empty list.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_AssessmentWithoutResponseContext() {
        Id assessmentRTId = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
        
        Assessment assessmentWithoutContext = new Assessment(Name = 'Assessment Without Context', RecordTypeId = assessmentRTId, AssessmentStatus = 'In Progress');
        insert assessmentWithoutContext;
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessmentWithoutContext.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(0, result.size(), 'Assessment without ResponseContextId should return an empty list.');
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that qualifying Regulatory Code Violations are returned for the Inspection associated with the Assessment.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_ReturnsQualifyingViolations() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND ResponseContextId != NULL LIMIT 1];
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(1, result.size(), 'Expected one qualifying Regulatory Code Violation.');
        Assert.areEqual(assessment.ResponseContextId, result[0].InspectionId, 'Returned violation must belong to the Assessment Inspection.');
        Assert.areNotEqual(null, result[0].Scope__c, 'Scope must be populated.');
        Assert.areNotEqual(null, result[0].Severity__c, 'Severity must be populated.');
        Assert.areEqual(false, result[0].IsChildViolation__c, 'Child violations must not be returned.');
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that all fields required by the related-list LWC are returned.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_ReturnsRequiredFields() {
        Assessment assessment = [SELECT Id FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND ResponseContextId != NULL LIMIT 1];
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(1, result.size(), 'Expected one qualifying Regulatory Code Violation.');
        
        RegulatoryCodeViolation violation = result[0];
        
        Assert.areNotEqual(null, violation.Id, 'Violation Id should be populated.');
        Assert.areNotEqual(null, violation.Name, 'Violation Name should be populated.');
        Assert.areNotEqual(null, violation.InspectionId, 'Inspection Id should be populated.');
        Assert.areNotEqual(null, violation.Scope__c, 'Scope should be populated.');
        Assert.areNotEqual(null, violation.Severity__c, 'Severity should be populated.');
        Assert.areEqual(false, violation.IsChildViolation__c, 'Returned violation must not be a child violation.');
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that violations without Scope are excluded from the results.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_ExcludesMissingScope() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND ResponseContextId != NULL LIMIT 1];
        
        RegulatoryCodeViolation existingViolation = [SELECT Id, InspectionId, InspectionAssmntIndId FROM RegulatoryCodeViolation WHERE InspectionId = :assessment.ResponseContextId LIMIT 1];
        
        RegulatoryCodeViolation incompleteViolation = new RegulatoryCodeViolation(InspectionId = existingViolation.InspectionId, InspectionAssmntIndId = existingViolation.InspectionAssmntIndId, ComplianceDueDate = System.now().addDays(2), DateCreated = System.now(), Status = 'Open', Scope__c = null, Severity__c = 'Potential for significant harm');
        insert incompleteViolation;
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.size(), 'Violation without Scope should be excluded.');
        
        for (RegulatoryCodeViolation violation : result) {
            Assert.areNotEqual(null, violation.Scope__c, 'Returned violation must have Scope.');
        }
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that violations without Severity are excluded from the results.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_ExcludesMissingSeverity() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND ResponseContextId != NULL LIMIT 1];
        
        RegulatoryCodeViolation existingViolation = [SELECT Id, InspectionId, InspectionAssmntIndId FROM RegulatoryCodeViolation WHERE InspectionId = :assessment.ResponseContextId LIMIT 1];
        
        RegulatoryCodeViolation incompleteViolation = new RegulatoryCodeViolation(InspectionId = existingViolation.InspectionId, InspectionAssmntIndId = existingViolation.InspectionAssmntIndId, ComplianceDueDate = System.now().addDays(2), DateCreated = System.now(), Status = 'Open', Scope__c = 'Isolated', Severity__c = null);
        insert incompleteViolation;
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.size(), 'Violation without Severity should be excluded.');
        
        for (RegulatoryCodeViolation violation : result) {
            Assert.areNotEqual(null, violation.Severity__c, 'Returned violation must have Severity.');
        }
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that returned violations belong to the Inspection referenced by Assessment.ResponseContextId.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_InspectionRelationship() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND ResponseContextId != NULL LIMIT 1];
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.size(), 'Expected one qualifying violation.');
        Assert.areEqual(assessment.ResponseContextId, result[0].InspectionId, 'Violation must belong to the Assessment ResponseContextId.');
    }
    
    /**
    * @author: Deepak
    * @date: 25 Aug 2026
    * @description: Verifies that child violations are excluded based on the IsChildViolation__c formula field.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testGetRelatedViolations_ExcludesChildViolations() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND ResponseContextId != NULL LIMIT 1];
        
        List<RegulatoryCodeViolation> expectedViolations = [SELECT Id, InspectionId, InspectionAssmntIndId, IsChildViolation__c, Scope__c, Severity__c FROM RegulatoryCodeViolation WHERE InspectionId = :assessment.ResponseContextId AND Scope__c != NULL AND Severity__c != NULL LIMIT 20];
        
        Integer nonChildCount = 0;
        
        for (RegulatoryCodeViolation violation : expectedViolations) {
            if (!violation.IsChildViolation__c) {
                nonChildCount++;
            }
        }
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(nonChildCount, result.size(), 'Only non-child qualifying violations should be returned.');
        
        for (RegulatoryCodeViolation violation : result) {
            Assert.areEqual(false, violation.IsChildViolation__c, 'Returned violation must not be a child violation.');
        }
    }
}