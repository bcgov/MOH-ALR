/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 May 2026
* @Description: The purpose of this class is to cover Code coverage of PHOCSInspectionOpenViolationController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                28 May -  PHOCS-2668         -  Accenture  -  Close subsequent child records..
***********************************************************************************************/
@isTest
public class PHOCSInspectionOpenViolationTest {
    public Static Id visitRTId = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public Static Id facilityRTId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
    public Static Id recAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('PHOCSRecreationalWater').getRecordTypeId();
    public Static Id inspAmntRTId = Schema.SObjectType.InspectionAssessmentInd.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionAssessmentInd').getRecordTypeId();
    
    @TestSetup
    public static void setupTestData() {        
        RegulatoryAuthorizationType reg = new RegulatoryAuthorizationType(Name = 'test reg type');
        insert reg;
        
        Account testAccount = new Account(Name = 'Test Facility', LicenseType__c = reg.Id, recordtypeId = facilityRTId);
        insert testAccount;
        
        ContactPointAddress cpa = new ContactPointAddress(Name = 'Test Address', Street = '123 Test Lane',
                                                          City = 'Alberta', State = 'AL', Country = 'Canada', PostalCode = 'M2H2E4');
        insert cpa;
        
        Visit testVisit = new Visit(AccountId = testAccount.Id, PlaceId = cpa.Id, recordTypeId = visitRTId,
                                    PlannedVisitStartTime = DateTime.now(), PlannedVisitEndTime = DateTime.now().addHours(2));
        insert testVisit;
        
        Visit secondVisit = new Visit(AccountId = testAccount.Id, PlaceId = cpa.Id, recordTypeId = visitRTId,
                                      PlannedVisitStartTime = DateTime.now().addDays(1), PlannedVisitEndTime = DateTime.now().addDays(1).addHours(2));
        insert secondVisit;
        
        AssessmentTaskDefinition testTaskDef = new AssessmentTaskDefinition(Name = 'Test Category', TaskType = 'InspectionChecklist');
        insert testTaskDef;
        
        AssessmentTask testTask = new AssessmentTask(Name = 'Test Task', TaskType = 'SignatureTask', ParentId = testVisit.Id, AssessmentTaskDefinitionId = testTaskDef.Id);
        insert testTask;
        
        AssessmentIndicatorDefinition indicators = new AssessmentIndicatorDefinition(Name = 'Question 1', DataType = 'String',
                                                                                     Category__c = 'test Category', Criticality__c = 'Critical', PHOCSParentId__c = Null);        
        insert indicators;
        
        InspectionAssessmentInd inspaind = new InspectionAssessmentInd(AssessmentIndDefinitionId = indicators.Id, AssessmentTaskId = testTask.Id, RecordTypeId = inspAmntRTId);
        insert inspaind;
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(InspectionId = testVisit.Id, InspectionAssmntIndId = inspaind.Id,
                                                                        ComplianceDueDate = System.Now().addDays(2), DateCreated = System.Now(), Status = 'Open');
        insert violation;
        
        RegulatoryCodeViolation violation2 = new RegulatoryCodeViolation(InspectionId = secondVisit.Id, InspectionAssmntIndId = inspaind.Id,
                                                                         ComplianceDueDate = System.Now().addDays(2), DateCreated = System.Now(), Status = 'Open');
        insert violation2;
        
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1];
        
        User adminUser = new User(
            Alias = 'adm',
            Email = 'admin' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AdminTestXYZ',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            Username = 'admin' + System.currentTimeMillis() + '@test.com'
        );
        insert adminUser;
        
    }

/**
* @author: Accenture
* @date: 28 May 2026
* @description: The purpose of this method is to cover Testcoverage of getParentQuestionsWithOpenViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetParentQuestionsWithOpenViolations() {
        Visit v = [SELECT Id, AccountId FROM Visit LIMIT 1];
        AssessmentIndicatorDefinition aid = [SELECT Id FROM AssessmentIndicatorDefinition LIMIT 1];        
        List<Id> aidIds = new List<Id>{ aid.Id };
            
        Test.startTest();        
        Map<Id, PHOCSInspectionOpenViolationController.OpenViolationWrapper> result = PHOCSInspectionOpenViolationController.getParentQuestionsWithOpenViolations(v.Id, aidIds);
        Test.stopTest();
        
        Assert.areEqual(1, result.size());
        Assert.areEqual(true, result.containsKey(aid.Id));
        
        PHOCSInspectionOpenViolationController.OpenViolationWrapper wrapper = result.get(aid.Id);        
        Assert.areEqual(true, wrapper.hasOpenViolation);
        Assert.areNotEqual(null, wrapper.parentViolationId);
    }

/**
* @author: Deepak
* @date: 28 May 2026
* @description: The purpose of this method is to cover Testcoverage of getParentQuestionsWithOpenViolations.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    @isTest
    static void testGetParentQuestionsWithOpenViolations_ContextId() {
        Account recAccount = new Account(Name = 'Rec Water Facility', Type = 'Recreational Water', recordtypeId = facilityRTId);
        insert recAccount;
        
        Asset poolAsset = new Asset(Name = 'Pool 1', AccountId = recAccount.Id, recordtypeId = recAssetRTId);
        insert poolAsset;
        
        ContactPointAddress cpa = [SELECT Id FROM ContactPointAddress LIMIT 1];
        
        Visit recVisit = new Visit(AccountId = recAccount.Id, PlaceId = cpa.Id, ContextId = poolAsset.Id, PlannedVisitStartTime = Datetime.now(),
                                   PlannedVisitEndTime = Datetime.now().addHours(2), recordTypeId = visitRTId);
        insert recVisit;
        
        AssessmentTaskDefinition taskDef = [SELECT Id FROM AssessmentTaskDefinition LIMIT 1];
        
        AssessmentTask task = new AssessmentTask(Name = 'Rec Task', TaskType = 'SignatureTask', ParentId = recVisit.Id,
                                                 AssessmentTaskDefinitionId = taskDef.Id);
        insert task;
        
        AssessmentIndicatorDefinition indicator = new AssessmentIndicatorDefinition(Name = 'Pool Question', DataType = 'String',
                                                                                    Category__c = 'test Category', Criticality__c = 'Critical');
        insert indicator;
        
        InspectionAssessmentInd ind = new InspectionAssessmentInd(AssessmentIndDefinitionId = indicator.Id, AssessmentTaskId = task.Id, RecordTypeId = inspAmntRTId);
        insert ind;
        
        RegulatoryCodeViolation violation = new RegulatoryCodeViolation(InspectionId = recVisit.Id, InspectionAssmntIndId = ind.Id,
                                                                        Asset__c = poolAsset.Id, Status = 'Open', DateCreated = System.Now());
        insert violation;
        
        Test.startTest();        
        Map<Id, PHOCSInspectionOpenViolationController.OpenViolationWrapper> result = PHOCSInspectionOpenViolationController.getParentQuestionsWithOpenViolations(recVisit.Id, new List<Id>{ indicator.Id });
        Test.stopTest();
        
        Assert.areEqual(1, result.size());
        Assert.areEqual(true, result.containsKey(indicator.Id));
        
        PHOCSInspectionOpenViolationController.OpenViolationWrapper wrapper = result.get(indicator.Id);
        
        Assert.isTrue(wrapper.hasOpenViolation);
        Assert.areEqual(violation.Id, wrapper.parentViolationId);
    }
}