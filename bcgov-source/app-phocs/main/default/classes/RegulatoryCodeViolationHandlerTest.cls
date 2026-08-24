/**********************************************************************************************
* @Author:      Accenture
* @Date:        03 Jun 2026
* @Description: The purpose of this class is to cover Code coverage of RegulatoryCodeViolationHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               03 Jun -  EHIS-2668         -  Accenture   -  Close subsequent child records.
***********************************************************************************************/
@isTest
public class RegulatoryCodeViolationHandlerTest {
    public static Id recordTypePHOCSRegulatoryCodeViolation = Schema.SObjectType.RegulatoryCodeViolation.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCodeViolation').getRecordTypeId();
    public static Id recordTypePHOCSInspection = Schema.SObjectType.Visit.getRecordTypeInfosByDeveloperName().get('PHOCSInspection').getRecordTypeId();
    public static Id recordTypePHOCSInspectionType = Schema.SObjectType.InspectionType.getRecordTypeInfosByDeveloperName().get('PHOCSInspectionType').getRecordTypeId();
    public static Id recordTypePHOCSDairyAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to create common test data and return a map of key record Ids for use across all test methods.
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
        
        Map<String, Id> dataMap = new Map<String, Id>();
        dataMap.put('inspId',      insp.Id);
        dataMap.put('inspAsmIndId', inspAsmInd.Id);
        return dataMap;
    }
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to cover positive test coverage of syncChildViolationStatus.
*               Children are inserted as Open and resolved via the parent cascade only.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testSyncChildViolationStatus_ResolvesChildren() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation parent = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                     InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                                     DateCreated = System.now(), Status = 'Open');
        insert parent;
        
        List<RegulatoryCodeViolation> childViolationsToInsert = new List<RegulatoryCodeViolation>();
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                                DateCreated= System.now(), Status = 'Open', PHOCSParentId__c= parent.Id));
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(10), 
                                                                DateCreated= System.now(), Status = 'Open', PHOCSParentId__c= parent.Id));
        insert childViolationsToInsert;
        
        Test.startTest();
        parent.Status = 'Resolved';
        update parent;
        Test.stopTest();
        
        List<RegulatoryCodeViolation> updatedChildren = [SELECT Id, Status, DateResolved FROM RegulatoryCodeViolation WHERE PHOCSParentId__c = :parent.Id];
        for (RegulatoryCodeViolation child : updatedChildren) {
            Assert.areEqual('Resolved', child.Status, 'Child status should be updated to Resolved when parent is resolved.');
            Assert.areNotEqual(null, child.DateResolved, 'DateResolved should be populated when child is resolved.');
        }
    }
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to cover negative test coverage of syncChildViolationStatus when status is unchanged.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testSyncChildViolationStatus_NoStatusChange() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation parent = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation,
                                                                     InspectionId = dataMap.get('inspId'), InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                                     DateCreated= System.now(), Status = 'Open');
        insert parent;
        
        List<RegulatoryCodeViolation> childViolationsToInsert = new List<RegulatoryCodeViolation>();
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(3), DateCreated= System.now(),
                                                                Status = 'Open', PHOCSParentId__c= parent.Id));
        insert childViolationsToInsert;
        
        Test.startTest();
        parent.ComplianceDueDate = System.now().addDays(20);
        update parent;
        Test.stopTest();
        
        RegulatoryCodeViolation updatedChild = [SELECT Status, DateResolved FROM RegulatoryCodeViolation WHERE Id = :childViolationsToInsert[0].Id];
        Assert.areEqual('Open', updatedChild.Status, 'Child status should remain Open when parent status has not changed.');
        Assert.areEqual(null, updatedChild.DateResolved, 'DateResolved should remain null when child status is not changed.');
    }
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to cover negative test coverage of syncChildViolationStatus when no children exist.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testSyncChildViolationStatus_NoChildren() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation parent = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                     InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                                     DateCreated= System.now(), Status = 'Open');
        insert parent;
        
        Test.startTest();
        parent.Status = 'Resolved';
        update parent;
        Test.stopTest();
        
        RegulatoryCodeViolation updatedParent = [SELECT Status FROM RegulatoryCodeViolation WHERE Id = :parent.Id];
        Assert.areEqual('Resolved', updatedParent.Status, 'Parent status should be Resolved even when no children exist.');
    }
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to cover positive test coverage of updateRecurrenceCount.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRecurrenceCount_CountAndDateUpdated() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation parent = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                     InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(1),
                                                                     DateCreated= System.now(), Status = 'Open');
        insert parent;
        
        DateTime due1 = System.now().addDays(5);
        DateTime due2 = System.now().addDays(15);
        
        List<RegulatoryCodeViolation> childViolationsToInsert = new List<RegulatoryCodeViolation>();
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = due1, DateCreated = System.now(),
                                                                Status = 'Open', PHOCSParentId__c = parent.Id));
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = due2, DateCreated = System.now(),
                                                                Status = 'Open', PHOCSParentId__c = parent.Id));
        
        Test.startTest();
        insert childViolationsToInsert;
        Test.stopTest();
        
        RegulatoryCodeViolation updatedParent = [SELECT RecurrenceCount, ComplianceDueDate FROM RegulatoryCodeViolation WHERE Id =: parent.Id];
        Assert.areEqual(2, updatedParent.RecurrenceCount, 'RecurrenceCount should equal the number of Open child violations.');
        Assert.areEqual(due2.date(), updatedParent.ComplianceDueDate.date(), 'ComplianceDueDate on parent should reflect the latest child ComplianceDueDate.');
    }
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to cover negative test coverage of updateRecurrenceCount when record has no parent.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateRecurrenceCount_NullParent_NoError() {
        Map<String, Id> dataMap = createTestData();
        
        List<RegulatoryCodeViolation> violationsToInsert = new List<RegulatoryCodeViolation>();
        violationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                           InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                           DateCreated= System.now(), Status = 'Open'));
        
        Test.startTest();
        insert violationsToInsert;
        Test.stopTest();
        
        RegulatoryCodeViolation inserted = [SELECT Id, Status FROM RegulatoryCodeViolation WHERE Id = :violationsToInsert[0].Id];
        Assert.areEqual('Open', inserted.Status, 'Orphan record should be inserted without errors.');
    }
    
/**
* @author: Deepak
* @date: 03 Jun 2026
* @description: The purpose of this method is to cover bulk test coverage of syncChildViolationStatus.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testSyncChildViolationStatus_BulkRecords() {
        Map<String, Id> dataMap = createTestData();
        
        RegulatoryCodeViolation parent = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                     InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(1),
                                                                     DateCreated= System.now(), Status = 'Open');
        insert parent;
        
        List<RegulatoryCodeViolation> childViolationsToInsert = new List<RegulatoryCodeViolation>();
        for (Integer i = 0; i < 10; i++) {
            childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                    InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(i + 1),
                                                                    DateCreated= System.now(), Status = 'Open', PHOCSParentId__c = parent.Id));
        }
        insert childViolationsToInsert;
        
        Test.startTest();
        parent.Status = 'Resolved';
        update parent;
        Test.stopTest();
        
        Integer resolvedCount = [SELECT COUNT() FROM RegulatoryCodeViolation WHERE PHOCSParentId__c = :parent.Id AND Status = 'Resolved'];
        Assert.areEqual(10, resolvedCount, 'All 10 child violations should be resolved when parent is resolved.');
    }
    
/**
* @description: To verify child violations inherit the ResolvedIn value of their parent.
*/    
    @isTest
    public static void testSyncChildViolationStatus_ChildrenInheritResolvedIn() {
        Map<String, Id> dataMap = createTestData();

        RegulatoryCodeViolation parent = new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                     InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                                     DateCreated = System.now(), Status = 'Open');
        insert parent;

        List<RegulatoryCodeViolation> childViolationsToInsert = new List<RegulatoryCodeViolation>();
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(5),
                                                                DateCreated = System.now(), Status = 'Open', PHOCSParentId__c = parent.Id));
        childViolationsToInsert.add(new RegulatoryCodeViolation(RecordTypeId = recordTypePHOCSRegulatoryCodeViolation, InspectionId = dataMap.get('inspId'),
                                                                InspectionAssmntIndId = dataMap.get('inspAsmIndId'), ComplianceDueDate = System.now().addDays(10),
                                                                DateCreated = System.now(), Status = 'Open', PHOCSParentId__c = parent.Id));
        insert childViolationsToInsert;

        Test.startTest();
        parent.Status = 'Resolved';
        parent.ResolvedIn__c = dataMap.get('inspId');
        update parent;
        Test.stopTest();

        List<RegulatoryCodeViolation> updatedChildren = [SELECT Id, Status, ResolvedIn__c FROM RegulatoryCodeViolation WHERE PHOCSParentId__c = :parent.Id];
        Assert.areEqual(2, updatedChildren.size(), 'Both child violations should be returned.');
        for (RegulatoryCodeViolation child : updatedChildren) {
            Assert.areEqual('Resolved', child.Status, 'Child status should be updated to Resolved when parent is resolved.');
            Assert.areEqual(dataMap.get('inspId'), child.ResolvedIn__c, 'Child should inherit the ResolvedIn value of its parent violation.');
        }
    }
}