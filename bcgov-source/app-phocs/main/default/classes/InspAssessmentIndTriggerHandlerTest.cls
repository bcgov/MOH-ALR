/**********************************************************************************************
* @Author:      Accenture 
* @Date:        11 Dec 2025
* @Description: The purpose of this class is to cover Code coverage of InspAssessmentIndTriggerHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
11 Dec -  PHOCS-2693         -  Accenture   -  Create Violations for PHOCS InspectionAssessmentInd records.
***********************************************************************************************/
@isTest
public class InspAssessmentIndTriggerHandlerTest {
    
    //Test Data Setup
    private static void createTestData() {
        Id rtPHOCSInspectionAssessmentInd = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
        Id rtPHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
        
        AssessmentIndicatorDefinition indDef = new AssessmentIndicatorDefinition(Name = 'Test Parent Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean');
        insert indDef;
        
        AssessmentTaskDefinition taskDef = new AssessmentTaskDefinition(Name = 'Test Task Definition', TaskType = 'InspectionChecklist');
        insert taskDef;
        
        AssessmentTaskIndDefinition taskIndDef = new AssessmentTaskIndDefinition(AssessmentTaskDefinitionId = taskDef.Id, AssessmentIndDefinitionId = indDef.Id, DisplayOrder = 1);
        insert taskIndDef;
        
        RegulatoryAuthority regAuth = new RegulatoryAuthority(Name = 'Test Regulatory Authority');
        insert regAuth;
        
        RegulatoryCode regCode = new RegulatoryCode(Name = 'Test Regulatory Code', RegulatoryAuthorityId = regAuth.Id, Subject = 'Test Regulatory Code', EffectiveFrom = Date.today().addDays(-30));
        insert regCode;
        
        RegulatoryCodeAssessmentInd regCodeMapping = new RegulatoryCodeAssessmentInd(AssessmentIndDefinitionId = indDef.Id, RegulatoryCodeId = regCode.Id);
        insert regCodeMapping;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.Longitude = 27.635308;
        loc.Latitude = 29.635308;
        insert loc;        
        
        Visit insp = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', PlaceId = loc.Id, PlannedVisitStartTime = System.now());
        insert insp;
        
        AssessmentTask task = new AssessmentTask(Name = 'Test Task', ParentId = insp.Id, AssessmentTaskDefinitionId = taskDef.Id);
        insert task;
        
        List<InspectionAssessmentInd> iAListToInsert = new List<InspectionAssessmentInd>();
        InspectionAssessmentInd iAParent = new InspectionAssessmentInd(RecordTypeId = rtPHOCSInspectionAssessmentInd, AssessmentIndDefinitionId = indDef.Id, AssessmentTaskId = task.Id,
                                                                       Result = InspAssessmentIndTriggerHandler.RESULT_NON_COMPLIANT);
        iAListToInsert.add(iAParent);
        insert iAListToInsert;        
    }
    
    
/**
* @author: Deepak
* @date: 11 Dec 2025
* @description: The purpose of this method is to cover Testcoverage of createRegulatoryCodeViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void createRegulatoryCodeViolationsTest(){
        
        Test.startTest();
        createTestData();
        Test.stopTest();
        
        List<RegulatoryCodeViolation> vioList = [SELECT Id, InspectionId, InspectionAssmntIndId, RegulatoryCodeId, Status FROM RegulatoryCodeViolation];
        RegulatoryCodeViolation vio = vioList[0];
        
        Assert.isTrue(!vioList.isEmpty(), 'A regulatory code violation should have been created.');
        Assert.areEqual(1, vioList.size(), 'Exactly one violation should be created.');
        Assert.areEqual('Open', vio.Status, 'Violation Status should be Open.');
        Assert.areNotEqual(null, vio.InspectionId, 'Violation must reference an Inspection (Visit).');
        Assert.areNotEqual(null, vio.InspectionAssmntIndId, 'Violation must reference the AssessmentIndDefinition.');
        Assert.areNotEqual(null, vio.RegulatoryCodeId, 'Violation must reference a Regulatory Code.');
    }
    
}