/**********************************************************************************************
* @Author:      Accenture 
* @Date:        11 Dec 2025
* @Description: The purpose of this class is to cover Code coverage of RegulatoryCodeViolationRelatedController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                17 Dec -  PHOCS-2873        -  Accenture   -  Display selected canned comments details on parent violation.
***********************************************************************************************/
@isTest
public class RegulatoryCodeViolationRelControllerTest{
    
    //Test Data Setup
    private static void createTestData() {
        Id rtPHOCSInspectionAssessmentInd = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
        Id rtPHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
        Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
        
        AssessmentIndicatorDefinition indDef = new AssessmentIndicatorDefinition(Name = 'Test Parent Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean');
        insert indDef;
        
        AssessmentIndicatorDefinition indChildDef = new AssessmentIndicatorDefinition(Name = 'Test Child Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean', PHOCSParentId__c = indDef.Id);
        insert indChildDef;
        
        AssessmentTaskDefinition taskDef = new AssessmentTaskDefinition(Name = 'Test Task Definition', TaskType = 'InspectionChecklist');
        insert taskDef;
        
        AssessmentTaskIndDefinition taskIndDef = new AssessmentTaskIndDefinition(AssessmentTaskDefinitionId = taskDef.Id, AssessmentIndDefinitionId = indDef.Id, DisplayOrder = 1);
        insert taskIndDef;
        
        AssessmentTaskIndDefinition taskIndDefChild = new AssessmentTaskIndDefinition(AssessmentTaskDefinitionId = taskDef.Id, AssessmentIndDefinitionId = indChildDef.Id, DisplayOrder = 2);
        insert taskIndDefChild;
        
        RegulatoryAuthority regAuth = new RegulatoryAuthority(Name = 'Test Regulatory Authority');
        insert regAuth;
        
        RegulatoryCode regCode = new RegulatoryCode(Name = 'Test Regulatory Code', RegulatoryAuthorityId = regAuth.Id, Subject = 'Test Regulatory Code', EffectiveFrom = Date.today().addDays(-30));
        insert regCode;
        
        List<RegulatoryCodeAssessmentInd> rCAIndListToInsert = new List<RegulatoryCodeAssessmentInd>();
        RegulatoryCodeAssessmentInd regCodeParentMapping = new RegulatoryCodeAssessmentInd(AssessmentIndDefinitionId = indDef.Id, RegulatoryCodeId = regCode.Id);
        rCAIndListToInsert.add(regCodeParentMapping);
        RegulatoryCodeAssessmentInd regCodeChildMapping = new RegulatoryCodeAssessmentInd(AssessmentIndDefinitionId = indChildDef.Id, RegulatoryCodeId = regCode.Id);
        rCAIndListToInsert.add(regCodeChildMapping);
        insert rCAIndListToInsert;
        
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
        InspectionAssessmentInd iAParent = new InspectionAssessmentInd(RecordTypeId = rtPHOCSInspectionAssessmentInd, AssessmentIndDefinitionId = indDef.Id, AssessmentTaskId = task.Id, Result = InspAssessmentIndTriggerHandler.RESULT_NON_COMPLIANT);
        iAListToInsert.add(iAParent);
        InspectionAssessmentInd iAChild = new InspectionAssessmentInd(RecordTypeId = rtPHOCSInspectionAssessmentInd, AssessmentIndDefinitionId = indChildDef.Id, AssessmentTaskId = task.Id, Result = InspAssessmentIndTriggerHandler.RESULT_NON_COMPLIANT);        
        iAListToInsert.add(iAChild);
        insert iAListToInsert;  
        
        List<RegulatoryCodeAssessmentInd> mappings = [SELECT Id, RegulatoryCodeId, AssessmentIndDefinitionId FROM RegulatoryCodeAssessmentInd WHERE RegulatoryCodeId = :regCode.Id];
        
        Map<Id, InspectionAssessmentInd> indMap = new Map<Id, InspectionAssessmentInd>();
        
        for (InspectionAssessmentInd ia : [SELECT Id, AssessmentIndDefinitionId FROM InspectionAssessmentInd WHERE AssessmentTaskId = :task.Id]){
            indMap.put(ia.AssessmentIndDefinitionId, ia);
        }        
        
        List<RegulatoryCodeViolation> violationsToInsert = new List<RegulatoryCodeViolation>();
        
        for (RegulatoryCodeAssessmentInd mapItem : mappings) {
            InspectionAssessmentInd ind = indMap.get(mapItem.AssessmentIndDefinitionId);
            
            if (ind != null) {
                RegulatoryCodeViolation vio = new RegulatoryCodeViolation();
                vio.RecordTypeId = recordTypePHOCSRegulatoryCodeViolation;
                vio.InspectionAssmntIndId = ind.Id;
                vio.InspectionId = insp.Id;
                vio.DateCreated = Date.today();
                vio.RegulatoryCodeId = mapItem.RegulatoryCodeId;
                vio.Status = 'Open';
                
                violationsToInsert.add(vio);
            }
        }

        if(!violationsToInsert.isEmpty()){
            insert violationsToInsert;
        }
    }
     
/**
* @author: Deepak
* @date: 17 Dec 2025
* @description: The purpose of this method is to cover Testcoverage of getRelatedViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void getRelatedViolationsTest(){
        
        createTestData();
        RegulatoryCodeViolation getParentRCV = [SELECT Id FROM RegulatoryCodeViolation WHERE InspectionAssmntInd.AssessmentIndDefinition.PHOCSParentId__c = NULL LIMIT 1];
       
        Test.startTest();        
        List<RegulatoryCodeViolation> results = RegulatoryCodeViolationRelatedController.getRelatedViolations(getParentRCV.Id);
        Test.stopTest();
        
        Assert.areEqual(1, results.size(), 'Related violations should be returned');
        Assert.areNotEqual(null, results[0].RegulatoryCode.Name, 'Regulatory Code Name should be populated');
    }
    
/**
* @author: Deepak
* @date: 17 Dec 2025
* @description: The purpose of this method is to cover Testcoverage of getRelatedViolations-Negative Scenario.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void getRelatedViolationsTestNegative(){
        
        Test.startTest();        
        List<RegulatoryCodeViolation> results = RegulatoryCodeViolationRelatedController.getRelatedViolations(NULL);
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Related violations should not be returned');
    }
}