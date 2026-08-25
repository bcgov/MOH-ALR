/**********************************************************************************************
* @Author:      Accenture
* @Date:        25 Aug 2026
* @Description: Test class for PHOCSAsmntVioRelatedController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@isTest(SeeAllData=true)
public class PHOCSAsmntVioRelatedControllerTest {
    
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
        
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(), 'Null Assessment Id should return an empty list.');
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
        
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(), 'An Assessment Id that does not exist should return an empty list.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies the controller behavior when an Assessment exists without a ResponseContextId.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_AssessmentWithoutResponseContext() {
        List<Assessment> assessments = [SELECT Id, ResponseContextId FROM Assessment WHERE ResponseContextId = NULL LIMIT 1];
        
        if (assessments.isEmpty()) {
            return;
        }
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessments[0].Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assertEquals(0, result.size(), 'Assessment without ResponseContextId should return an empty list.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that qualifying Regulatory Code Violations are returned for the Inspection associated with the Assessment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_ReturnsQualifyingViolations() {
        List<Assessment> assessments = [SELECT Id, ResponseContextId FROM Assessment WHERE ResponseContextId != NULL LIMIT 20];
        
        if (assessments.isEmpty()) {
            return;
        }
        
        Set<Id> inspectionIds = new Set<Id>();
        
        for (Assessment assessment : assessments) {
            inspectionIds.add(assessment.ResponseContextId);
        }
        
        List<RegulatoryCodeViolation> violations = [SELECT Id, Name, InspectionId, Scope__c, Severity__c, IsChildViolation__c, RegulatoryCode.Name, RegulatoryCode.Subject, InspectionAssmntInd.AssessmentIndDefinition.Name FROM RegulatoryCodeViolation WHERE InspectionId IN :inspectionIds AND Scope__c != NULL AND Severity__c != NULL AND IsChildViolation__c = false LIMIT 20];
        
        if (violations.isEmpty()) {
            return;
        }
        
        Assessment selectedAssessment;
        
        for (Assessment assessment : assessments) {
            for (RegulatoryCodeViolation violation : violations) {
                if (violation.InspectionId == assessment.ResponseContextId) {
                    selectedAssessment = assessment;
                    break;
                }
            }
            
            if (selectedAssessment != null) {
                break;
            }
        }
        
        if (selectedAssessment == null) {
            return;
        }
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(selectedAssessment.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assert(result.size() > 0, 'Expected qualifying Regulatory Code Violations to be returned.');
        
        for (RegulatoryCodeViolation violation : result) {
            System.assertEquals(selectedAssessment.ResponseContextId, violation.InspectionId, 'Returned violation must belong to the Assessment ResponseContextId Inspection.');
            System.assertNotEquals(null, violation.Scope__c, 'Returned violation must have Scope.');
            System.assertNotEquals(null, violation.Severity__c, 'Returned violation must have Severity.');
            System.assertEquals(false, violation.IsChildViolation__c, 'Child violations must not be returned.');
        }
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies the returned relationship fields required by the related-list LWC.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_ReturnsRequiredFields() {
        List<Assessment> assessments = [SELECT Id, ResponseContextId FROM Assessment WHERE ResponseContextId != NULL LIMIT 20];
        
        if (assessments.isEmpty()) {
            return;
        }
        
        Set<Id> inspectionIds = new Set<Id>();
        
        for (Assessment assessment : assessments) {
            inspectionIds.add(assessment.ResponseContextId);
        }
        
        List<RegulatoryCodeViolation> expectedViolations = [SELECT Id, Name, InspectionId, Scope__c, Severity__c, IsChildViolation__c, RegulatoryCode.Name, RegulatoryCode.Subject, InspectionAssmntInd.AssessmentIndDefinition.Name FROM RegulatoryCodeViolation WHERE InspectionId IN :inspectionIds AND Scope__c != NULL AND Severity__c != NULL AND IsChildViolation__c = false LIMIT 20];
        
        if (expectedViolations.isEmpty()) {
            return;
        }
        
        Assessment selectedAssessment;
        
        for (Assessment assessment : assessments) {
            for (RegulatoryCodeViolation violation : expectedViolations) {
                if (violation.InspectionId == assessment.ResponseContextId) {
                    selectedAssessment = assessment;
                    break;
                }
            }
            
            if (selectedAssessment != null) {
                break;
            }
        }
        
        if (selectedAssessment == null) {
            return;
        }
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(selectedAssessment.Id);
        Test.stopTest();
        
        System.assert(result.size() > 0, 'Expected at least one violation.');
        
        RegulatoryCodeViolation firstViolation = result[0];
        
        System.assertNotEquals(null, firstViolation.Id, 'Violation Id should be populated.');
        System.assertNotEquals(null, firstViolation.Name, 'Violation Name should be populated.');
        System.assertNotEquals(null, firstViolation.InspectionId, 'Inspection Id should be populated.');
        System.assertNotEquals(null, firstViolation.Scope__c, 'Scope should be populated.');
        System.assertNotEquals(null, firstViolation.Severity__c, 'Severity should be populated.');
    }
    
    /**
* @author: Deepak
* @date: 25 Aug 2026
* @description: Verifies that only non-child violations with Scope and Severity are returned.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetRelatedViolations_OnlyQualifyingViolationsReturned() {
        List<Assessment> assessments = [SELECT Id, ResponseContextId FROM Assessment WHERE ResponseContextId != NULL LIMIT 20];
        
        if (assessments.isEmpty()) {
            return;
        }
        
        Test.startTest();
        List<RegulatoryCodeViolation> result = PHOCSAsmntVioRelatedController.getRelatedViolations(assessments[0].Id);
        Test.stopTest();
        
        for (RegulatoryCodeViolation violation : result) {
            System.assertEquals(assessments[0].ResponseContextId, violation.InspectionId, 'Violation must belong to the Assessment Inspection.');
            System.assertNotEquals(null, violation.Scope__c, 'Scope must be populated.');
            System.assertNotEquals(null, violation.Severity__c, 'Severity must be populated.');
            System.assertEquals(false, violation.IsChildViolation__c, 'Child violations must be excluded.');
        }
    }
}