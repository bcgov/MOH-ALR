/**********************************************************************************************
* @Author:      Accenture
* @Date:        24 Aug 2026
* @Description: The purpose of this class is to cover code coverage of PHOCSCCFLViolationAssessmentController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               24 Aug -  PHOCS-4817        -  Deepak      -  Initial test class for getViolations.
***********************************************************************************************/
@isTest
public class PHOCSCCFLViolationAsmntControllerTest {
    public static Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public static Id recordTypePHOCSInspectionType = Schema.SObjectType.InspectionType.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionType').getRecordTypeId();
    public static Id recordTypePHOCSDairyAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();

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

        RegulatoryCode regCode = new RegulatoryCode(Name = 'Test Regulatory Code', Subject = 'Test Subject', Description = 'Test Description',
                                                    RegulatoryAuthorityId = regAuth.Id, EffectiveFrom = System.today());
        insert regCode;

        Map<String, Id> dataMap = new Map<String, Id>();
        dataMap.put('inspId', insp.Id);
        dataMap.put('inspAsmIndId', inspAsmInd.Id);
        dataMap.put('regCodeId', regCode.Id);
        dataMap.put('indDefId', indDef.Id);
        dataMap.put('assessmentTaskId', assessmentTask.Id);
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
*                when their related Assessment Indicator Definition has a parent definition set
*                (i.e. IsChildViolation__c evaluates to true).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetViolations_ExcludesChildViolations() {
        Map<String, Id> dataMap = createTestData();

        // Top-level violation, using the parent Assessment Indicator Definition from createTestData
        RegulatoryCodeViolation parentViolation = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                               InspectionAssmntIndId = dataMap.get('inspAsmIndId'), RegulatoryCodeId = dataMap.get('regCodeId'),
                                                                               ComplianceDueDate = System.now().addDays(5), DateCreated = System.now(), Status = 'Open');
        insert parentViolation;

        // Child Assessment Indicator Definition pointing to the parent definition drives IsChildViolation__c = true
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
}