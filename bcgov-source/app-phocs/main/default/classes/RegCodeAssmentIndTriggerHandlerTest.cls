/**********************************************************************************************
* @Author:      Accenture 
* @Date:        18 Feb 2026
* @Description: The purpose of this Trigger is to trigger on particular events
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                18 Feb -  PHOCS-3397         -  Accenture   -  Testcoverage of RegCodeAssessmentIndTriggerHandler.
***********************************************************************************************/
@isTest
public class RegCodeAssmentIndTriggerHandlerTest{
    
    //Test Data Setup
    private static void createTestData(){
        
        AssessmentIndicatorDefinition indDef = new AssessmentIndicatorDefinition(Name = 'Test Parent Assessment Definition', Category__c = 'Compliance', DataType = 'Boolean');
        insert indDef;
        
        RegulatoryAuthority regAuth = new RegulatoryAuthority(Name = 'Test Regulatory Authority');
        insert regAuth;
        
        List<RegulatoryCode> codes = new List<RegulatoryCode>();
        
        for(Integer i = 1; i <= 5; i++){
            codes.add(new RegulatoryCode(Name = 'Test Regulatory Code ' + i, RegulatoryAuthorityId = regAuth.Id,
                                         Subject = 'Test Regulatory Code ' + i, EffectiveFrom = Date.today().addDays(-30)));
        }
        insert codes;
        
        List<RegulatoryCodeAssessmentInd> mappings = new List<RegulatoryCodeAssessmentInd>();
        
        for(RegulatoryCode rc : codes){
            mappings.add(new RegulatoryCodeAssessmentInd(AssessmentIndDefinitionId = indDef.Id, RegulatoryCodeId = rc.Id));
        }        
        insert mappings;
    }    
    
/**
* @author: Deepak
* @date: 18 Feb 2026
* @description: The purpose of this method is to cover Testcoverage of updateRelatedRegulatoryCodes for Insert.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void updateRelatedRegulatoryCodes_InsertTest(){
        
        Test.startTest();
        createTestData();
        Test.stopTest();
        
        AssessmentIndicatorDefinition indDef = [SELECT Id, RelatedRegulatoryCodes__c FROM AssessmentIndicatorDefinition LIMIT 1];

        Assert.areNotEqual(null, indDef.RelatedRegulatoryCodes__c, 'RelatedRegulatoryCodes__c should be populated after insert.');
        Assert.isTrue(indDef.RelatedRegulatoryCodes__c.contains('Test Regulatory Code 1'),'Field should contain regulatory code names.');
        Assert.isTrue(indDef.RelatedRegulatoryCodes__c.length() <= 255, 'Field must not exceed 255 characters.');
    }
        
/**
* @author: Deepak
* @date: 18 Feb 2026
* @description: The purpose of this method is to cover Testcoverage of updateRelatedRegulatoryCodes for Delete.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void updateRelatedRegulatoryCodes_DeleteTest(){
        
        createTestData();
        AssessmentIndicatorDefinition indDef = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
        List<RegulatoryCodeAssessmentInd> mappings = [SELECT Id FROM RegulatoryCodeAssessmentInd WHERE AssessmentIndDefinitionId = :indDef.Id];

        Test.startTest();
        delete mappings;
        Test.stopTest();

        AssessmentIndicatorDefinition updatedDef = [SELECT RelatedRegulatoryCodes__c FROM AssessmentIndicatorDefinition WHERE Id = :indDef.Id];

        Assert.areEqual(null, updatedDef.RelatedRegulatoryCodes__c, 'Field should be cleared after all mappings are deleted.');
    }

/**
* @author: Deepak
* @date: 18 Feb 2026
* @description: The purpose of this method is to cover Testcoverage of updateRelatedRegulatoryCodes for BulkInsert.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testBulkInsertScenario() {
        
        createTestData();
        AssessmentIndicatorDefinition indDef = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];
        RegulatoryAuthority regAuth = [SELECT Id FROM RegulatoryAuthority LIMIT 1];

        List<RegulatoryCode> extraCodes = new List<RegulatoryCode>();

        for(Integer i = 6; i <= 20; i++){
            extraCodes.add(new RegulatoryCode(Name = 'BulkCode-' + i, RegulatoryAuthorityId = regAuth.Id,
                Subject = 'Bulk Code ' + i, EffectiveFrom = Date.today().addDays(-30)));
        }
        insert extraCodes;

        List<RegulatoryCodeAssessmentInd> newMappings = new List<RegulatoryCodeAssessmentInd>();

        for(RegulatoryCode rc : extraCodes){
            newMappings.add(new RegulatoryCodeAssessmentInd(AssessmentIndDefinitionId = indDef.Id, RegulatoryCodeId = rc.Id));
        }

        Test.startTest();
        insert newMappings;
        Test.stopTest();

        AssessmentIndicatorDefinition updatedDef = [SELECT RelatedRegulatoryCodes__c FROM AssessmentIndicatorDefinition WHERE Id = :indDef.Id];

        Assert.isTrue(updatedDef.RelatedRegulatoryCodes__c.length() <= 255, 'Even in bulk insert, field must respect 255 limit.');
    }
}