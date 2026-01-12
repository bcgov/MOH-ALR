/**********************************************************************************************
* @Author:      Accenture 
* @Date:        06 Jan 2026
* @Description: The purpose of this class is to cover Code coverage of InspectionAssessmentTaskCreationService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                06 Jan -  PHOCS-2681        -  Accenture   -  Display selected canned comments details on parent violation.
***********************************************************************************************/
@isTest
public class InspectionAssessmentTaskCrtnServiceTest{
    public static Id recordTypePHOCSDairyAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public static Id recordTypePHOCSDairyPlantRoomsandEquipment = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('PHOCSDairyPlantRoomsandEquipment').getRecordTypeId();
    public static Id recordTypePHOCSInspectionType = Schema.SObjectType.InspectionType.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionType').getRecordTypeId();
    
    //Test Data Setup
    private static void createTestData() {
        Id rtPHOCSInspectionAssessmentInd = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
        Id rtPHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
        
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
        
        Account dairyAccount = new Account(Name = 'Test Dairy Facility for TestClass', Type = 'Dairy', RecordTypeId = recordTypePHOCSDairyAccount);
        insert dairyAccount;
        
        List<Asset> facilityAssestToInsert = new List<Asset>();
        Asset dairyAssest1 = new Asset(Name = 'Test Equipment-1', RecordTypeId = recordTypePHOCSDairyPlantRoomsandEquipment, AccountId = dairyAccount.Id, Status = 'Active', Type__c = 'Plant equipment', PlantEquipment__c = 'Holder pasteurizer');
        facilityAssestToInsert.add(dairyAssest1);
        Asset dairyAssest2 = new Asset(Name = 'Test Equipment-2', RecordTypeId = recordTypePHOCSDairyPlantRoomsandEquipment, AccountId = dairyAccount.Id, Status = 'Active', Type__c = 'Plant equipment', PlantEquipment__c = 'HTST pasteurizer');
        facilityAssestToInsert.add(dairyAssest2);
        Asset dairyAssest3 = new Asset(Name = 'Test Equipment-3', RecordTypeId = recordTypePHOCSDairyPlantRoomsandEquipment, AccountId = dairyAccount.Id, Status = 'Active', Type__c = 'Plant equipment', PlantEquipment__c = 'UHT pasteurizer');
        facilityAssestToInsert.add(dairyAssest3);
        insert facilityAssestToInsert;
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'Test Location';
        loc.Longitude = 27.635308;
        loc.Latitude = 29.635308;
        insert loc;
        
        InspectionType inspectype = new InspectionType(
            Name = 'test isnpection type',
            InspectionTypes__c = 'Routine',
            Description = 'description test',
            RecordTypeId = recordTypePHOCSInspectionType
        );
        insert inspectype;
        
        Visit insp = new Visit(InspectionMethod__c = 'Scheduled on Site Inspection', AccountId = dairyAccount.Id, PlaceId = loc.Id, PlannedVisitStartTime = System.now(), RecordTypeId = recordTypePHOCSInspection, VisitTypeId = inspectype.Id);
        insert insp;   
    }
 
/**
* @author: Deepak
* @date: 07 Jan 2026
* @description: The purpose of this method is to cover Negative Testcoverage of executeInspectionQuestions.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    @isTest
    public static void testSignatureCoverageWithTest(){
        
        createTestData();        
        AssessmentTaskDefinition sigDef = new AssessmentTaskDefinition(Name = 'Test Signature Def', TaskType = 'InspectionChecklist');
        insert sigDef;
        
        ActionPlanTemplate apt = new ActionPlanTemplate(Name = 'Test Signature Template for testclass', TargetEntityType = 'Visit', ActionPlanType = 'Retail');
        insert apt;
        
        ActionPlanTemplateVersion aptv =[SELECT Id, Status FROM ActionPlanTemplateVersion WHERE ActionPlanTemplateId = :apt.Id AND Status = 'Draft' LIMIT 1];
        
        ActionPlanTemplateItem sigItem = new ActionPlanTemplateItem(Name = 'Test Signature Template Item', UniqueName = 'TEST_SIGNATURE_ITEM', ActionPlanTemplateVersionId = aptv.Id, ItemEntityType = 'SignatureTask', DisplayOrder = 1);
        insert sigItem;
        
        ActionPlanTemplateItemValue sigValue = new ActionPlanTemplateItemValue(ActionPlanTemplateItemId = sigItem.Id, ItemEntityFieldName = BCMOH_Constants.ItemEntityName, ValueLiteral = sigDef.Name);
        insert sigValue;
        
        ActionPlanTemplateVersion aptv1 = [select Id, Status, Version from ActionPlanTemplateVersion WHERE Status = 'Draft' AND ActionPlanTemplateId =: apt.Id LIMIT 1];
        aptv1.Status = 'Final';
        update aptv;
        
        InspectionAssessmentTaskCreationService.testSignatureItemIds.add(sigItem.Id);
        InspectionAssessmentTaskCreationService.addTestSignatureItemIds(new Set<Id>{ sigItem.Id });
        
        InspectionAssessmentTaskCreationService.FlowInputs input = new InspectionAssessmentTaskCreationService.FlowInputs();
        input.inspId = [SELECT Id FROM Visit LIMIT 1].Id;
        List<InspectionAssessmentTaskCreationService.FlowInputs> inputs = new List<InspectionAssessmentTaskCreationService.FlowInputs>{ input };        
            
        Test.startTest();        
        InspectionAssessmentTaskCreationService.executeInspectionQuestions(inputs);
        Test.stopTest();
        
        Assert.areEqual(false, [SELECT COUNT() FROM AssessmentTask WHERE ParentId =: input.inspId AND TaskType = 'SignatureTask'] > 0, 'Signature AssessmentTask should be not created in test');
    }
     
/**
* @author: Deepak
* @date: 06 Jan 2026
* @description: The purpose of this method is to cover Testcoverage of executeInspectionQuestions.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest(SeeAllData=true)
    public static void executeInspectionQuestionsTest(){        
        createTestData();
        
        InspectionAssessmentTaskCreationService.FlowInputs input = new InspectionAssessmentTaskCreationService.FlowInputs();
        input.inspId = [SELECT Id FROM Visit WHERE Account.Name = 'Test Dairy Facility for TestClass' AND RecordType.DeveloperName = 'PHOCSInspection' LIMIT 1].Id;
        List<InspectionAssessmentTaskCreationService.FlowInputs> inputs = new List<InspectionAssessmentTaskCreationService.FlowInputs>{ input };        
            
        Test.startTest();        
        InspectionAssessmentTaskCreationService.executeInspectionQuestions(inputs);
        Test.stopTest();
        
        List<AssessmentTask> tasks = [SELECT Id, SequenceNumber, AssessmentTaskDefinitionId FROM AssessmentTask WHERE ParentId =: input.inspId];        
        //Assert.areEqual(true, tasks.size() > 0, 'AssessmentTasks should be created');
        //Assert.areNotEqual(null, tasks.size(), 'Task Size cannot be null');
        
        List<InspectionAssessmentInd> inds = [SELECT Id, AssessmentTaskId, AssessmentIndDefinitionId FROM InspectionAssessmentInd WHERE AssessmentTaskId IN :tasks];        
        //Assert.areEqual(true, inds.size() > 0, 'InspectionAssessmentInd records should be created');
    }
    
/**
* @author: Deepak
* @date: 07 Jan 2026
* @description: The purpose of this method is to cover Negative Testcoverage of executeInspectionQuestions.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void executeInspectionQuestionsNegaviteTest(){        
        createTestData();
        
        InspectionAssessmentTaskCreationService.FlowInputs input = new InspectionAssessmentTaskCreationService.FlowInputs();
        input.inspId = 'a00000000000000AAA';
        List<InspectionAssessmentTaskCreationService.FlowInputs> inputs = new List<InspectionAssessmentTaskCreationService.FlowInputs>{ input };        
            
        Test.startTest();        
        InspectionAssessmentTaskCreationService.executeInspectionQuestions(inputs);
        Test.stopTest();
        
        Assert.areEqual(false, [SELECT COUNT() FROM AssessmentTask WHERE ParentId =: input.inspId] > 0, 'No AssessmentTask should be created for invalid inspection Id');
        
    }
}