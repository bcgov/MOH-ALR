@IsTest
private class PHOCSOperatorLabReqControllerTest {
    private static final Id FACILITY_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
    private static final Id WATER_REQ_RT = Schema.SObjectType.LabTestRequisition__c
        .getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequisition').getRecordTypeId();
    private static final Id DRINKING_WATER_SYSTEM_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId();
    private static final Id DRINKING_WATER_SOURCE_INTAKE_RT = Schema.SObjectType.Account
        .getRecordTypeInfosByDeveloperName().get('DrinkingWaterSourceIntake').getRecordTypeId();
    private static final Id WATER_TEST_RT = Schema.SObjectType.LabTestMasterList__c
        .getRecordTypeInfosByDeveloperName().get('WaterBacteriologicalTest').getRecordTypeId();
    private static final Id WATER_TEST_REQUIRED_RT = Schema.SObjectType.LabTestRequired__c
        .getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequired').getRecordTypeId();

    @TestSetup
    static void setupData() {
        Account eligibleFacility = new Account(
            Name = 'Portal Food Facility',
            RecordTypeId = FACILITY_RT,
            Type = 'Food'
        );
        Account ineligibleFacility = new Account(
            Name = 'Portal Sewerage Facility',
            RecordTypeId = FACILITY_RT,
            Type = 'Sewerage'
        );
        insert new List<Account>{eligibleFacility, ineligibleFacility};

        Account drinkingWaterSystem = new Account(
            Name = 'Portal Drinking Water System',
            RecordTypeId = DRINKING_WATER_SYSTEM_RT,
            Type = 'Drinking Water',
            CategoryL1__c = 'Community Water System',
            CategoryL2__c = 'Local Gov System',
            CategoryL3__c = 'Municipality'
        );
        insert drinkingWaterSystem;

        insert new Account(
            Name = 'Portal Drinking Water Source Intake',
            RecordTypeId = DRINKING_WATER_SOURCE_INTAKE_RT,
            Type = 'Drinking Water',
            ParentId = drinkingWaterSystem.Id,
            ParentAccount__c = drinkingWaterSystem.Id
        );

        LabTestRequisition__c requisition = new LabTestRequisition__c(
            RecordTypeId = WATER_REQ_RT,
            FacilityName__c = eligibleFacility.Id,
            Status__c = 'Draft',
            SampleType__c = 'Food processing water',
            TestCategory__c = 'Bacteriological',
            ToLaboratory__c = 'BCCDC',
            SamplerName__c = 'Portal Sampler',
            CollectionDateTime__c = Datetime.newInstance(2026, 9, 18, 10, 30, 0)
        );
        insert requisition;

        LabTestMasterList__c testDefinition = new LabTestMasterList__c(
            Name = 'Total Coliform',
            ExternalId__c = 'PORTAL-TOTCOL',
            ParameterType__c = 'Total Coliform',
            PhysicalQuantity__c = 'Count',
            SampleTestType__c = 'Bacteriological',
            TestCategory__c = 'Drinking water',
            UnitOfMeasure__c = 'Count/100mL',
            RecordTypeId = WATER_TEST_RT
        );
        insert testDefinition;

        insert new LabTestRequired__c(
            RecordTypeId = WATER_TEST_REQUIRED_RT,
            LabTestRequisition__c = requisition.Id,
            Test__c = testDefinition.Id,
            SampleTestType__c = 'Bacteriological',
            ResultValue__c = 'Absent',
            Unit_of_Measure__c = 'Count/100mL',
            ResultCodeDescription__c = 'No coliform detected'
        );
    }

    @IsTest
    static void returnsEligibleContextAndRows() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Portal Food Facility'];
        Test.startTest();
        PHOCSOperatorLabRequisitionController.PageContext context =
            PHOCSOperatorLabRequisitionController.getPageContext(facility.Id);
        Test.stopTest();

        Assert.isTrue(context.eligible);
        Assert.isFalse(context.drinkingWaterFacility);
        Assert.areEqual(WATER_REQ_RT, context.waterRequisitionRecordTypeId);
        Assert.areEqual(1, context.requisitions.size());
        Assert.isTrue(context.requisitions[0].editable);
        Assert.areEqual('Bacteriological', context.requisitions[0].sampleTestType);
        Assert.areEqual('Total Coliform', context.requisitions[0].testName);
        Assert.areEqual('Absent', context.requisitions[0].resultValue);
        Assert.areEqual('Count/100mL', context.requisitions[0].unitOfMeasure);
        Assert.areEqual('No coliform detected', context.requisitions[0].resultDescription);
        Assert.areEqual(Datetime.newInstance(2026, 9, 18, 10, 30, 0), context.requisitions[0].collectionDateTime);

        LabTestRequisition__c requisition = [
            SELECT Id, Status__c
            FROM LabTestRequisition__c
            WHERE FacilityName__c = :facility.Id
            LIMIT 1
        ];
        requisition.Status__c = 'Requested';
        update requisition;

        context = PHOCSOperatorLabRequisitionController.getPageContext(facility.Id);
        Assert.isFalse(context.requisitions[0].editable, 'Operators cannot edit a requisition after Draft.');
    }

    @IsTest
    static void rejectsIneligibleFacilityType() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Portal Sewerage Facility'];
        PHOCSOperatorLabRequisitionController.PageContext context =
            PHOCSOperatorLabRequisitionController.getPageContext(facility.Id);
        Assert.isFalse(context.eligible);
        Assert.areEqual(0, context.requisitions.size());
    }

    @IsTest
    static void supportsOnlyDrinkingWaterSystemRecordType() {
        Account drinkingWaterSystem = [
            SELECT Id FROM Account WHERE Name = 'Portal Drinking Water System'
        ];
        Account sourceIntake = [
            SELECT Id FROM Account WHERE Name = 'Portal Drinking Water Source Intake'
        ];

        PHOCSOperatorLabRequisitionController.PageContext systemContext =
            PHOCSOperatorLabRequisitionController.getPageContext(drinkingWaterSystem.Id);
        PHOCSOperatorLabRequisitionController.PageContext intakeContext =
            PHOCSOperatorLabRequisitionController.getPageContext(sourceIntake.Id);

        Assert.isTrue(systemContext.eligible);
        Assert.isTrue(systemContext.drinkingWaterFacility);
        Assert.isFalse(intakeContext.eligible);
        Assert.isFalse(intakeContext.drinkingWaterFacility);
    }

    @IsTest
    static void requiresFacility() {
        try {
            PHOCSOperatorLabRequisitionController.getPageContext(null);
            Assert.fail('Expected an AuraHandledException.');
        } catch (AuraHandledException expected) {
            Assert.isTrue(true);
        }
    }

    @IsTest
    static void returnsDetailPageContext() {
        LabTestRequisition__c requisition = [
            SELECT Id, FacilityName__c
            FROM LabTestRequisition__c
            LIMIT 1
        ];
        PHOCSOperatorLabRequisitionController.PageContext context =
            PHOCSOperatorLabRequisitionController.getDetailPageContext(requisition.Id);

        Assert.areEqual(requisition.FacilityName__c, context.facilityId);
        Assert.areEqual(1, context.requisitions.size());
        Assert.areEqual(requisition.Id, context.requisitions[0].id);
    }

    @IsTest
    static void requiresRequisitionForDetailPage() {
        try {
            PHOCSOperatorLabRequisitionController.getDetailPageContext(null);
            Assert.fail('Expected an AuraHandledException.');
        } catch (AuraHandledException expected) {
            Assert.isTrue(true);
        }
    }
}
