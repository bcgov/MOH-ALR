/**********************************************************************************************
* @Author:      Deepak
* @Date:        14 Aug 2026
* @Description: The purpose of this class is to cover code coverage of LabTestRequiredTriggerHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                14 Aug -  PHOCS-295/589     -  Deepak      -  Lab Test Required trigger handler test coverage
***********************************************************************************************/
@isTest
public class LabTestRequiredTriggerHandlerTest {
    private static final Id LAB_REQ_RT = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequisition').getRecordTypeId();
    private static final Id LAB_TEST_RT = Schema.SObjectType.LabTestMasterList__c.getRecordTypeInfosByDeveloperName().get('WaterBacteriologicalTest').getRecordTypeId();
    private static final Id LAB_REQUIRED_RT = Schema.SObjectType.LabTestRequired__c.getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequired').getRecordTypeId();
    private static final Id FACILITY_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Creates the test data required for Lab Test Required trigger handler tests.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @testSetup
    public static void setupTestData() {
        Account facilityWithAuthority = new Account(Name = 'PHOCS Test Facility - WithAuthority', RecordTypeId = FACILITY_RT);
        Account facilityTwo = new Account(Name = 'PHOCS Test Facility - Two', RecordTypeId = FACILITY_RT);
        insert new List<Account>{ facilityWithAuthority, facilityTwo };

        LabTestMasterList__c totalColiform = new LabTestMasterList__c(Name = 'Total Coliform Test', ExternalId__c = 'TOTCOL', ParameterType__c = 'Total Coliform',
                                                                       PhysicalQuantity__c = 'Count', SampleTestType__c = 'Bacteriological', TestCategory__c = 'Drinking water',
                                                                       UnitOfMeasure__c = 'Count/100mL', RecordTypeId = LAB_TEST_RT);
        insert totalColiform;

        LabTestRequisition__c requisitionWithFacility = new LabTestRequisition__c(RecordTypeId = LAB_REQ_RT, FacilityName__c = facilityWithAuthority.Id);
        LabTestRequisition__c requisitionWithoutFacility = new LabTestRequisition__c(RecordTypeId = LAB_REQ_RT);
        LabTestRequisition__c requisitionTwo = new LabTestRequisition__c(RecordTypeId = LAB_REQ_RT, FacilityName__c = facilityTwo.Id);
        insert new List<LabTestRequisition__c>{ requisitionWithFacility, requisitionWithoutFacility, requisitionTwo };
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Returns a Lab Test Required record type that is not supported by the trigger handler.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    private static Id getUnsupportedRecordTypeId() {
        Set<String> supportedRecordTypes = new Set<String>{
            'PHOCSDairyProductTestRequired',
            'PHOCSDairyEnvironmentalSwabTestRequired',
            'PHOCSDyeTest',
            'PHOCSFoodLabTestRequired',
            'PHOCSLeadWaterTest',
            'PHOCSWaterLabTestRequired'
        };

        for (Schema.RecordTypeInfo recordTypeInfo : Schema.SObjectType.LabTestRequired__c.getRecordTypeInfos()) {
            if (!recordTypeInfo.isMaster() && !supportedRecordTypes.contains(recordTypeInfo.getDeveloperName())) {
                return recordTypeInfo.getRecordTypeId();
            }
        }

        return null;
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers bulk insert of Lab Test Required records when the requisition contains a Facility.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_BulkInsert() {
        LabTestRequisition__c requisition = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c != null LIMIT 1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        List<LabTestRequired__c> labTestRequiredRecords = new List<LabTestRequired__c>();
        for (Integer i = 0; i < 2; i++) {
            labTestRequiredRecords.add(new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, LabTestRequisition__c = requisition.Id, Test__c = labTest.Id));
        }

        Test.startTest();
        insert labTestRequiredRecords;
        Test.stopTest();

        List<LabTestRequired__c> insertedRecords = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id IN :labTestRequiredRecords];

        Assert.areEqual(2, insertedRecords.size(), 'Expected two Lab Test Required records');

        for (LabTestRequired__c labTestRequired : insertedRecords) {
            Assert.areEqual(requisition.FacilityName__c, labTestRequired.FacilityName__c, 'Expected Facility to be copied from the requisition');
            Assert.areEqual(requisition.Id, labTestRequired.LabTestRequisition__c, 'Expected requisition to be populated');
            Assert.areEqual(labTest.Id, labTestRequired.Test__c, 'Expected Test to reference the Lab Test Master List');
        }
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers insert when FacilityName__c is already populated and confirms that it is not overridden.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_FacilityAlreadyPopulated_NotOverridden() {
        List<LabTestRequisition__c> requisitions = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c != null LIMIT 2];
        LabTestRequisition__c requisition = requisitions[0];
        Account existingFacility = [SELECT Id FROM Account WHERE Name = 'PHOCS Test Facility - Two' LIMIT 1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, LabTestRequisition__c = requisition.Id, FacilityName__c = existingFacility.Id, Test__c = labTest.Id);

        Test.startTest();
        insert labTestRequired;
        Test.stopTest();

        LabTestRequired__c insertedRecord = [SELECT Id, FacilityName__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(existingFacility.Id, insertedRecord.FacilityName__c, 'Existing Facility should not be overridden');
        Assert.areEqual(requisition.Id, insertedRecord.LabTestRequisition__c, 'Expected requisition to remain populated');
        Assert.areEqual(labTest.Id, insertedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers insert when no Lab Test Requisition is provided.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_NoRequisition_FacilityNotPopulated() {
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, Test__c = labTest.Id);

        Test.startTest();
        insert labTestRequired;
        Test.stopTest();

        LabTestRequired__c insertedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(null, insertedRecord.FacilityName__c, 'Facility should remain blank when no requisition is provided');
        Assert.areEqual(null, insertedRecord.HealthAuthority__c, 'Health Authority should remain blank when no requisition is provided');
        Assert.areEqual(null, insertedRecord.LabTestRequisition__c, 'Requisition should remain blank');
        Assert.areEqual(labTest.Id, insertedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers insert when the requisition exists but does not contain a Facility.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_RequisitionWithoutFacility_FacilityNotPopulated() {
        LabTestRequisition__c requisition = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c = null LIMIT 1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, LabTestRequisition__c = requisition.Id, Test__c = labTest.Id);

        Test.startTest();
        insert labTestRequired;
        Test.stopTest();

        LabTestRequired__c insertedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(null, insertedRecord.FacilityName__c, 'Facility should remain blank when requisition has no Facility');
        Assert.areEqual(null, insertedRecord.HealthAuthority__c, 'Health Authority should remain blank when requisition has no Facility');
        Assert.areEqual(requisition.Id, insertedRecord.LabTestRequisition__c, 'Expected requisition to remain populated');
        Assert.areEqual(labTest.Id, insertedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers insert when no requisition is supplied and confirms that Facility is not populated.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_RequisitionNotFound() {
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, Test__c = labTest.Id);

        Test.startTest();
        insert labTestRequired;
        Test.stopTest();

        LabTestRequired__c insertedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(null, insertedRecord.FacilityName__c, 'Facility should remain blank');
        Assert.areEqual(null, insertedRecord.HealthAuthority__c, 'Health Authority should remain blank');
        Assert.areEqual(null, insertedRecord.LabTestRequisition__c, 'Requisition should remain blank');
        Assert.areEqual(labTest.Id, insertedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers insert for an unsupported Lab Test Required record type.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_UnsupportedRecordType() {
        Id unsupportedRecordTypeId = getUnsupportedRecordTypeId();
        Assert.areNotEqual(null, unsupportedRecordTypeId, 'Expected an unsupported Lab Test Required record type to be available');

        LabTestRequisition__c requisition = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c != null LIMIT 1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = unsupportedRecordTypeId, LabTestRequisition__c = requisition.Id, Test__c = labTest.Id);

        Test.startTest();
        insert labTestRequired;
        Test.stopTest();

        LabTestRequired__c insertedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c, RecordTypeId FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(null, insertedRecord.FacilityName__c, 'Facility should not be populated for an unsupported record type');
        Assert.areEqual(null, insertedRecord.HealthAuthority__c, 'Health Authority should not be populated for an unsupported record type');
        Assert.areEqual(requisition.Id, insertedRecord.LabTestRequisition__c, 'Requisition should remain populated');
        Assert.areEqual(labTest.Id, insertedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
        Assert.areEqual(unsupportedRecordTypeId, insertedRecord.RecordTypeId, 'Expected the unsupported record type to remain populated');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers update when FacilityName__c was blank and the requisition contains a Facility.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_Update_FacilityWasBlank_PopulatesFacility() {
        LabTestRequisition__c requisition = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c != null LIMIT 1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, LabTestRequisition__c = requisition.Id, Test__c = labTest.Id);
        insert labTestRequired;

        labTestRequired = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];
        labTestRequired.FacilityName__c = null;

        Test.startTest();
        update labTestRequired;
        Test.stopTest();

        LabTestRequired__c updatedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(requisition.FacilityName__c, updatedRecord.FacilityName__c, 'Facility should be populated from the requisition');
        Assert.areEqual(requisition.Id, updatedRecord.LabTestRequisition__c, 'Requisition should remain populated');
        Assert.areEqual(labTest.Id, updatedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers update when the Lab Test Requisition is changed to a requisition with a different Facility.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_Update_RequisitionChanged_PopulatesFacility() {
        List<LabTestRequisition__c> requisitions = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c != null ORDER BY CreatedDate ASC];
        LabTestRequisition__c requisitionOne = requisitions[0];
        LabTestRequisition__c requisitionTwo = requisitions[1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, LabTestRequisition__c = requisitionOne.Id, Test__c = labTest.Id);
        insert labTestRequired;

        labTestRequired.LabTestRequisition__c = requisitionTwo.Id;

        Test.startTest();
        update labTestRequired;
        Test.stopTest();

        LabTestRequired__c updatedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(requisitionTwo.Id, updatedRecord.LabTestRequisition__c, 'Expected requisition to be changed');
        Assert.areEqual(requisitionTwo.FacilityName__c, updatedRecord.FacilityName__c, 'Expected Facility to be copied from the new requisition');
        Assert.areEqual(labTest.Id, updatedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }

    /**
    * @author: Deepak
    * @date: 14 Aug 2026
    * @description: Covers update when the Facility is changed directly on Lab Test Required.
    * @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
    */
    @isTest
    public static void testPopulateFacilityFromRequisition_Update_FacilityChanged() {
        List<LabTestRequisition__c> requisitions = [SELECT Id, FacilityName__c FROM LabTestRequisition__c WHERE FacilityName__c != null ORDER BY CreatedDate ASC];
        LabTestRequisition__c requisition = requisitions[0];
        Account facilityTwo = [SELECT Id, HealthAuthority__c FROM Account WHERE Name = 'PHOCS Test Facility - Two' LIMIT 1];
        LabTestMasterList__c labTest = [SELECT Id FROM LabTestMasterList__c WHERE ExternalId__c = 'TOTCOL' LIMIT 1];

        LabTestRequired__c labTestRequired = new LabTestRequired__c(RecordTypeId = LAB_REQUIRED_RT, LabTestRequisition__c = requisition.Id, FacilityName__c = requisition.FacilityName__c, Test__c = labTest.Id);
        insert labTestRequired;

        labTestRequired.FacilityName__c = facilityTwo.Id;

        Test.startTest();
        update labTestRequired;
        Test.stopTest();

        LabTestRequired__c updatedRecord = [SELECT Id, FacilityName__c, HealthAuthority__c, LabTestRequisition__c, Test__c FROM LabTestRequired__c WHERE Id = :labTestRequired.Id];

        Assert.areEqual(facilityTwo.Id, updatedRecord.FacilityName__c, 'Expected the changed Facility to remain populated');
        Assert.areEqual(facilityTwo.HealthAuthority__c, updatedRecord.HealthAuthority__c, 'Expected Health Authority to be copied from the changed Facility');
        Assert.areEqual(requisition.Id, updatedRecord.LabTestRequisition__c, 'Expected requisition to remain populated');
        Assert.areEqual(labTest.Id, updatedRecord.Test__c, 'Expected Test to reference the Lab Test Master List');
    }
}