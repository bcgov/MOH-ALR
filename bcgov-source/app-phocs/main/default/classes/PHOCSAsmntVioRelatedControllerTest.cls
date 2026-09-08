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
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(InspectionId = testVisit.Id, InspectionAssmntIndId = inspAssmntInd.Id, ComplianceDueDate = System.now().addDays(2), DateCreated = System.now(), Status = 'Open', Scope__c = 'Isolated', Severity__c = 'Potential for significant harm', ResolutionNotes = 'Test Comment');
        insert violation;
        
        Id assessmentRTId = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
        
        String selectedViolationsJson = '[{"comments":"Test Comment","severity":"Potential for significant harm","scope":"Isolated","inspectionQuestion":"Question 1","regulatoryCode":"5(2)(a)","category":"Test Category","violationId":"' + violation.Id + '"}]';
        
        Assessment assessment = new Assessment(Name = 'Test Assessment', RecordTypeId = assessmentRTId, ResponseContextId = testVisit.Id, AssessmentStatus = 'In Progress', SelectedViolationsJSON__c = selectedViolationsJson);
        insert assessment;
        
        String riskReAssessmentJson = '[{"comments":"Risk re-assessment comment","severity":"Potential for significant harm","scope":"Pattern","inspectionQuestion":"Question 1","regulatoryCode":"5(2)(a)","category":"Test Category","violationId":"' + violation.Id + '"}]';
        
        Assessment riskReAssessment = new Assessment(Name = 'Test Risk Re-assessment', RecordTypeId = assessmentRTId, ResponseContextId = testVisit.Id, AssessmentStatus = 'In Progress', Type = 'Risk Re-assessment', SelectedViolationsJSON__c = riskReAssessmentJson);
        insert riskReAssessment;
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that null Assessment Id returns an empty response.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_NullAssessmentId() {
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(null);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areNotEqual(null, result.violations, 'Violations should not be null.');
        Assert.areEqual(0, result.violations.size(), 'Null Assessment Id should return an empty violation list.');
        Assert.areEqual(false, result.isRiskReAssessment, 'Null Assessment Id should not be identified as Risk Re-assessment.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that an invalid Assessment Id returns an empty response.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_InvalidAssessmentId() {
        Id assessmentId = '001000000000001AAA';
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessmentId);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areNotEqual(null, result.violations, 'Violations should not be null.');
        Assert.areEqual(0, result.violations.size(), 'An invalid Assessment Id should return an empty violation list.');
        Assert.areEqual(false, result.isRiskReAssessment, 'Invalid Assessment should not be identified as Risk Re-assessment.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that an Assessment without SelectedViolationsJSON__c returns an empty violation list.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_EmptySelectedViolations() {
        Id assessmentRTId = Schema.SObjectType.Assessment.getRecordTypeInfosByDeveloperName().get('PHOCSAssessment').getRecordTypeId();
        
        Assessment assessment = new Assessment(Name = 'Assessment Without Selected Violations', RecordTypeId = assessmentRTId, ResponseContextId = [SELECT Id FROM Visit LIMIT 1].Id, AssessmentStatus = 'In Progress');
        insert assessment;
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areNotEqual(null, result.violations, 'Violations should not be null.');
        Assert.areEqual(0, result.violations.size(), 'Assessment without SelectedViolationsJSON__c should return an empty violation list.');
        Assert.areEqual(false, result.isRiskReAssessment, 'Assessment should not be identified as Risk Re-assessment.');
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Verifies that selected violations are returned for a normal Assessment from SelectedViolationsJSON__c.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_ReturnsSelectedViolations() {
        Assessment assessment = [SELECT Id, ResponseContextId, Type FROM Assessment 
                                 WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND Type != 'Risk Re-assessment' LIMIT 1];
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areNotEqual(null, result.violations, 'Violations should not be null.');
        Assert.areEqual(1, result.violations.size(), 'Expected one selected Regulatory Code Violation.');
        Assert.areEqual(false, result.isRiskReAssessment, 'Assessment should not be identified as Risk Re-assessment.');
        
        PHOCSAsmntVioRelatedController.ViolationWrapper violation = result.violations[0];
        
        Assert.areNotEqual(null, violation.id, 'Violation Id should be populated.');
        Assert.areNotEqual(null, violation.violationName, 'Violation Name should be populated.');
        Assert.areEqual('Test Category', violation.category, 'Category should come from SelectedViolationsJSON__c.');
        Assert.areEqual('5(2)(a)', violation.regulatoryCode, 'Regulatory Code should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Question 1', violation.inspectionQuestion, 'Inspection Question should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Isolated', violation.scope, 'Scope should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Potential for significant harm', violation.severity, 'Severity should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Test Comment', violation.comment, 'Comment should come from SelectedViolationsJSON__c.');
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Verifies that all fields required by the related-list LWC are returned.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_ReturnsRequiredFields() {
        Assessment assessment = [SELECT Id FROM Assessment 
                                 WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND Type != 'Risk Re-assessment' LIMIT 1];
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areNotEqual(null, result.violations, 'Violations should not be null.');
        Assert.areEqual(1, result.violations.size(), 'Expected one selected violation.');
        
        PHOCSAsmntVioRelatedController.ViolationWrapper violation = result.violations[0];
        
        Assert.areNotEqual(null, violation.id, 'Violation Id should be populated.');
        Assert.areNotEqual(null, violation.violationName, 'Violation Name should be populated.');
        Assert.areNotEqual(null, violation.category, 'Category should be populated.');
        Assert.areNotEqual(null, violation.regulatoryCode, 'Regulatory Code should be populated.');
        Assert.areNotEqual(null, violation.inspectionQuestion, 'Inspection Question should be populated.');
        Assert.areNotEqual(null, violation.scope, 'Scope should be populated.');
        Assert.areNotEqual(null, violation.severity, 'Severity should be populated.');
        Assert.areNotEqual(null, violation.comment, 'Comment should be populated.');
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Verifies that Risk Re-assessment uses SelectedViolationsJSON__c as the historical snapshot.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_RiskReAssessment() {
        Assessment assessment = [SELECT Id, ResponseContextId, Type, SelectedViolationsJSON__c FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND Type = 'Risk Re-assessment' LIMIT 1];
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(true, result.isRiskReAssessment, 'Assessment should be identified as Risk Re-assessment.');
        Assert.areNotEqual(null, result.violations, 'Violations should not be null.');
        Assert.areEqual(1, result.violations.size(), 'Expected one selected violation from SelectedViolationsJSON__c.');
        
        PHOCSAsmntVioRelatedController.ViolationWrapper violation = result.violations[0];
        
        Assert.areNotEqual(null, violation.id, 'Violation Id should be populated.');
        Assert.areNotEqual(null, violation.violationName, 'Violation Name should be populated.');
        Assert.areEqual('Test Category', violation.category, 'Category should come from SelectedViolationsJSON__c.');
        Assert.areEqual('5(2)(a)', violation.regulatoryCode, 'Regulatory Code should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Question 1', violation.inspectionQuestion, 'Inspection Question should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Pattern', violation.scope, 'Scope should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Potential for significant harm', violation.severity, 'Severity should come from SelectedViolationsJSON__c.');
        Assert.areEqual('Risk re-assessment comment', violation.comment, 'Comment should come from SelectedViolationsJSON__c.');
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Verifies that the controller uses the JSON snapshot even when the current Regulatory Code Violation has different Scope, Severity and Comment values.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_UsesHistoricalSnapshotValues() {
        RegulatoryCodeViolation violationRecord = [SELECT Id, Scope__c, Severity__c, ResolutionNotes FROM RegulatoryCodeViolation LIMIT 1];
        
        Assessment assessment = [SELECT Id FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND Type = 'Risk Re-assessment' LIMIT 1];
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.violations.size(), 'Expected one selected violation.');
        Assert.areEqual('Pattern', result.violations[0].scope, 'Scope must come from the historical JSON snapshot.');
        Assert.areEqual('Potential for significant harm', result.violations[0].severity, 'Severity must come from the historical JSON snapshot.');
        Assert.areEqual('Risk re-assessment comment', result.violations[0].comment, 'Comment must come from the historical JSON snapshot.');
        Assert.areEqual(violationRecord.Id, result.violations[0].id, 'Returned violation must match the violationId from the JSON snapshot.');
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Verifies that an invalid violation Id in SelectedViolationsJSON__c is ignored.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_InvalidViolationId() {
        Assessment assessment = [SELECT Id FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND Type = 'Risk Re-assessment' LIMIT 1];
        
        assessment.SelectedViolationsJSON__c = '[{"comments":"Test Comment","severity":"Potential for significant harm","scope":"Isolated","inspectionQuestion":"Question 1","regulatoryCode":"5(2)(a)","category":"Test Category","violationId":"invalidId"}]';
        update assessment;
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(true, result.isRiskReAssessment, 'Assessment should be identified as Risk Re-assessment.');
        Assert.areEqual(0, result.violations.size(), 'Invalid violation Id should be ignored.');
    }
    
    /**
* @author: Deepak
* @date: 05 Sep 2026
* @description: Verifies that a selected violation with null Scope, Severity and Comment is still returned because values are sourced from JSON.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_NullSnapshotValues() {
        RegulatoryCodeViolation violation = [SELECT Id FROM RegulatoryCodeViolation LIMIT 1];
        Assessment assessment = [SELECT Id FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' AND Type != 'Risk Re-assessment' LIMIT 1];
        
        assessment.SelectedViolationsJSON__c = '[{"comments":null,"severity":null,"scope":null,"inspectionQuestion":"Question 1","regulatoryCode":"5(2)(a)","category":"Test Category","violationId":"' + violation.Id + '"}]';
        update assessment;
        
        Test.startTest();
        PHOCSAsmntVioRelatedController.RelatedViolationsResponse result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.violations.size(), 'Selected violation should still be returned.');
        Assert.areEqual(null, result.violations[0].scope, 'Scope should come from JSON.');
        Assert.areEqual(null, result.violations[0].severity, 'Severity should come from JSON.');
        Assert.areEqual(null, result.violations[0].comment, 'Comment should come from JSON.');
    }
}