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
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(InspectionId = testVisit.Id, InspectionAssmntIndId = inspAssmntInd.Id, 
                                                                        ComplianceDueDate = System.now().addDays(2), DateCreated = System.now(), Status = 'Open', Scope__c = 'Isolated',
                                                                        Severity__c = 'Potential for significant harm');
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
* @description: Verifies that an Assessment Id that does not exist returns an empty list.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_InvalidAssessmentId() {
        Id assessmentId = '001000000000001AAA';
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessmentId);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(0, result.size(), 'An Assessment Id that does not exist should return an empty list.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that qualifying Regulatory Code Violations are returned for the Inspection associated with the Assessment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_ReturnsQualifyingViolations() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' LIMIT 1];
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null.');
        Assert.areEqual(1, result.size(), 'Expected one qualifying Regulatory Code Violation.');
        Assert.areNotEqual(null, result[0].Scope__c, 'Returned violation must have Scope.');
        Assert.areNotEqual(null, result[0].Severity__c, 'Returned violation must have Severity.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies the returned relationship fields required by the related-list LWC.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_ReturnsRequiredFields() {
        Assessment assessment = [SELECT Id FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' LIMIT 1];
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.size(), 'Expected one violation.');
        
        RegulatoryCodeViolation violation = result[0];
        
        Assert.areNotEqual(null, violation.Id, 'Violation Id should be populated.');
        Assert.areNotEqual(null, violation.Name, 'Violation Name should be populated.');
        Assert.areNotEqual(null, violation.Scope__c, 'Scope should be populated.');
        Assert.areNotEqual(null, violation.Severity__c, 'Severity should be populated.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that only non-child violations with Scope and Severity are returned.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_OnlyQualifyingViolationsReturned() {
        Assessment assessment = [SELECT Id, ResponseContextId FROM Assessment WHERE RecordType.DeveloperName = 'PHOCSAssessment' LIMIT 1];
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessment.Id);
        Test.stopTest();
        
        Assert.areEqual(1, result.size(), 'Expected one qualifying violation.');
    }
}