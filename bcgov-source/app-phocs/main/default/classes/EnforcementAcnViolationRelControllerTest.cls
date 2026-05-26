/**********************************************************************************************
* @Author:      Accenture 
* @Date:        26 May 2026
* @Description: The purpose of this class is to cover Code coverage of EnforcementActionViolationHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
26 May -  EHIS-3688         -  Accenture   -  Prevents duplicate records records.
***********************************************************************************************/
@isTest
public class EnforcementAcnViolationRelControllerTest {
    
    //Test Data Setup
    public static void createTestData() {
        Id rtPHOCSInspectionAssessmentInd = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
        Id rtPHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
        Id recordTypePHOCSInspectionType = Schema.SObjectType.InspectionType.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionType').getRecordTypeId();
        Id recordTypePHOCSDairyAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();
        Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
        
        // Assessment Indicator Definitions
        AssessmentIndicatorDefinition indDef1 = new AssessmentIndicatorDefinition(Name = 'Test Parent Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean');
        insert indDef1;        
        AssessmentIndicatorDefinition indDef2 = new AssessmentIndicatorDefinition(Name = 'Test Child Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean');
        insert indDef2;
        
        // Regulatory Authority
        RegulatoryAuthority regAuth = new RegulatoryAuthority(Name = 'Test Regulatory Authority');
        insert regAuth;
        
        // Regulatory Code
        RegulatoryCode regCode = new RegulatoryCode(Name = 'Test Regulatory Code', RegulatoryAuthorityId = regAuth.Id, Subject = 'Test Regulatory Code', EffectiveFrom = Date.today().addDays(-30));
        insert regCode;
        
        // Account
        Account acc = new Account(Name = 'Test Facility', Type = 'Dairy', RecordTypeId = recordTypePHOCSDairyAccount);
        insert acc;
        
        // Location
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.Longitude = 27.635308;
        loc.Latitude = 29.635308;
        insert loc;
        
        // Inspection Type
        InspectionType inspectype = new InspectionType(Name = 'test isnpection type', InspectionTypes__c = 'Routine', Description = 'description test', RecordTypeId = recordTypePHOCSInspectionType);
        insert inspectype;     
        
        // Visit / Inspection
        Visit inspection = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = acc.Id, PlaceId = loc.Id, PlannedVisitStartTime = System.now(), 
                                     VisitTypeId = inspectype.Id, recordtypeId = recordTypePHOCSInspection);
        insert inspection;
        
        // Assessment Task Definition
        AssessmentTaskDefinition taskDef = new AssessmentTaskDefinition(Name = 'Test Task Definition', TaskType = 'InspectionChecklist');
        insert taskDef;
        
        // Assessment Task
        AssessmentTask assessmentTask = new AssessmentTask(ParentId = inspection.Id, AssessmentTaskDefinitionId = taskDef.Id, Name = 'Test Assessment Task');
        insert assessmentTask;
        
        // Inspection Assessment Indicators
        List<InspectionAssessmentInd> assessmentInds = new List<InspectionAssessmentInd>();
        InspectionAssessmentInd ind1 = new InspectionAssessmentInd(AssessmentTaskId = assessmentTask.Id, AssessmentIndDefinitionId = indDef1.Id, RecordTypeId = rtPHOCSInspectionAssessmentInd);
        InspectionAssessmentInd ind2 = new InspectionAssessmentInd(AssessmentTaskId = assessmentTask.Id, AssessmentIndDefinitionId = indDef2.Id, RecordTypeId = rtPHOCSInspectionAssessmentInd);
        assessmentInds.add(ind1);
        assessmentInds.add(ind2);        
        insert assessmentInds;
        
        // Regulatory Code Violations
        List<RegulatoryCodeViolation> violations = new List<RegulatoryCodeViolation>();        
        RegulatoryCodeViolation violation1 = new RegulatoryCodeViolation(InspectionId = inspection.Id, InspectionAssmntIndId = assessmentInds[0].Id, RegulatoryCodeId = regCode.Id,
                                                                         DateCreated = System.Today(), RecordTypeId = rtPHOCSRegulatoryCodeViolation);
        RegulatoryCodeViolation violation2 = new RegulatoryCodeViolation(InspectionId = inspection.Id, InspectionAssmntIndId = assessmentInds[1].Id, RegulatoryCodeId = regCode.Id,
                                                                         DateCreated = System.Today(), RecordTypeId = rtPHOCSRegulatoryCodeViolation);
        violations.add(violation1);
        violations.add(violation2);
        insert violations;
        
        // Violation Enforcement Actions
        List<ViolationEnforcementAction> enforcementActions = new List<ViolationEnforcementAction>();        
        ViolationEnforcementAction action1 = new ViolationEnforcementAction(ViolationId = violation1.id, Type = 'Notice of Violation', DateCreated = System.Today());        
        ViolationEnforcementAction action2 = new ViolationEnforcementAction(ViolationId = violation2.id, Type = 'Notice of Violation', DateCreated = System.Today());        
        enforcementActions.add(action1);
        enforcementActions.add(action2);        
        insert enforcementActions;
        
        // Create EnforcementActionViolation records
        List<ViolationEnforcementAction> actions = [SELECT Id, ViolationId FROM ViolationEnforcementAction LIMIT 2];        
        List<EnforcementActionViolation__c> actionViolations = new List<EnforcementActionViolation__c>();
        
        for (ViolationEnforcementAction action : actions) {
            actionViolations.add(new EnforcementActionViolation__c(ViolationEnforcementAction__c = action.Id, RegulatoryCodeViolation__c = action.ViolationId));
        }
        
        insert actionViolations;
    }
    
/**
* @author: Deepak
* @date: 26 May 2026
* @description: The purpose of this method is to cover Testcoverage of getRelatedViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void testGetRelatedViolations_ValidRecordId() {
        createTestData();
        ViolationEnforcementAction action = [SELECT Id FROM ViolationEnforcementAction LIMIT 1];

        Test.startTest();
        List<EnforcementActionViolation__c> results = EnforcementActionViolationRelController.getRelatedViolations(action.Id);
        Test.stopTest();

        Assert.isTrue(results.size() > 0, 'Should return related violations');
        Assert.areNotEqual(null, results[0].RegulatoryCodeViolation__c, 'Regulatory code violation should exist');
        Assert.areNotEqual(null, results[0].RegulatoryCodeViolation__r.InspectionId, 'Inspection should exist');
    }
    
/**
* @author: Deepak
* @date: 26 May 2026
* @description: The purpose of this method is to cover Testcoverage of getRelatedViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void testGetRelatedViolations_InalidRecordId() {
       
        Test.startTest();
        List<EnforcementActionViolation__c> results = EnforcementActionViolationRelController.getRelatedViolations(null);
        Test.stopTest();

        Assert.isTrue(results.size() == 0, 'Should not return related violations');
    }
}