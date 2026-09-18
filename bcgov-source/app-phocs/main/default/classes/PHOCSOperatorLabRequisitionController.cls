public with sharing class PHOCSOperatorLabRequisitionController {
    private static final String WATER_REQUISITION_RECORD_TYPE = 'PHOCSWaterLabTestRequisition';
    private static final String FACILITY_RECORD_TYPE = 'Facility';
    private static final String DRINKING_WATER_SYSTEM_RECORD_TYPE = 'DrinkingWaterSystem';
    private static final Set<String> ELIGIBLE_FACILITY_TYPES = new Set<String>{
        'Food', 'Child Care', 'Recreational Water'
    };
    private static final Set<String> EDITABLE_STATUSES = new Set<String>{'Draft'};

    @AuraEnabled
    public static PageContext getPageContext(Id facilityId) {
        if (facilityId == null) {
            throw new AuraHandledException('A Facility is required.');
        }

        Account facility = [
            SELECT Id, Name, Type, RecordType.DeveloperName
            FROM Account
            WHERE Id = :facilityId
            WITH USER_MODE
            LIMIT 1
        ];

        PageContext result = new PageContext();
        result.facilityId = facility.Id;
        result.facilityName = facility.Name;
        result.facilityType = facility.Type;
        String facilityRecordType = facility.RecordType.DeveloperName;
        Boolean isDrinkingWaterRecord = facilityRecordType == DRINKING_WATER_SYSTEM_RECORD_TYPE
            && facility.Type == 'Drinking Water';
        result.eligible = (facilityRecordType == FACILITY_RECORD_TYPE
            && ELIGIBLE_FACILITY_TYPES.contains(facility.Type)) || isDrinkingWaterRecord;
        result.drinkingWaterFacility = isDrinkingWaterRecord;
        result.drinkingWaterComponents = isDrinkingWaterRecord
            ? getDrinkingWaterComponents(facilityId)
            : new List<ComponentOption>();
        result.waterRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c
            .getRecordTypeInfosByDeveloperName().get(WATER_REQUISITION_RECORD_TYPE).getRecordTypeId();
        result.requisitions = result.eligible ? getRequisitions(facilityId) : new List<RequisitionRow>();
        return result;
    }

    @AuraEnabled
    public static PageContext getDetailPageContext(Id requisitionId) {
        if (requisitionId == null) {
            throw new AuraHandledException('A requisition is required.');
        }
        LabTestRequisition__c requisition = [
            SELECT Id, FacilityName__c
            FROM LabTestRequisition__c
            WHERE Id = :requisitionId
              AND RecordType.DeveloperName = :WATER_REQUISITION_RECORD_TYPE
              AND CreatedById = :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        return getPageContext(requisition.FacilityName__c);
    }

    @AuraEnabled(cacheable=true)
    public static List<RequisitionRow> getRequisitions(Id facilityId) {
        List<RequisitionRow> rows = new List<RequisitionRow>();
        for (LabTestRequisition__c requisition : [
            SELECT Id, Name, LabTestRequisitionNumber__c, Status__c, SampleType__c,
                   TestCategory__c, ToLaboratory__c, SamplerName__c, CreatedDate,
                   Drinking_Water_Component_Name__c, Drinking_Water_Component_Name__r.Name,
                   Site_Treatment__c, Site_Descriptor__c, CollectionDateTime__c,
                   (SELECT Id, SampleTestType__c, Test__c, Test__r.Name,
                           Test__r.SampleTestType__c, ResultValue__c, Unit_of_Measure__c,
                           UnitOfMeasure__c, ResultCodeDescription__c
                    FROM LabTestsRequired__r
                    ORDER BY CreatedDate)
            FROM LabTestRequisition__c
            WHERE FacilityName__c = :facilityId
              AND RecordType.DeveloperName = :WATER_REQUISITION_RECORD_TYPE
              AND CreatedById = :UserInfo.getUserId()
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ]) {
            if (requisition.LabTestsRequired__r.isEmpty()) {
                rows.add(new RequisitionRow(requisition, null));
            } else {
                for (LabTestRequired__c testResult : requisition.LabTestsRequired__r) {
                    rows.add(new RequisitionRow(requisition, testResult));
                }
            }
        }
        return rows;
    }

    private static List<ComponentOption> getDrinkingWaterComponents(Id facilityId) {
        List<ComponentOption> options = new List<ComponentOption>();
        for (Asset component : [
            SELECT Id, Name
            FROM Asset
            WHERE AccountId = :facilityId
              AND RecordType.DeveloperName = 'PHOCSDrinkingWaterSystemComponent'
              AND Type__c IN ('Treatment', 'Storage', 'Distribution')
            WITH USER_MODE
            ORDER BY Name
        ]) {
            options.add(new ComponentOption(component.Id, component.Name));
        }
        return options;
    }

    public class PageContext {
        @AuraEnabled public Id facilityId;
        @AuraEnabled public String facilityName;
        @AuraEnabled public String facilityType;
        @AuraEnabled public Boolean eligible;
        @AuraEnabled public Boolean drinkingWaterFacility;
        @AuraEnabled public List<ComponentOption> drinkingWaterComponents;
        @AuraEnabled public Id waterRequisitionRecordTypeId;
        @AuraEnabled public List<RequisitionRow> requisitions;
    }

    public class ComponentOption {
        @AuraEnabled public Id value;
        @AuraEnabled public String label;

        public ComponentOption(Id value, String label) {
            this.value = value;
            this.label = label;
        }
    }

    public class RequisitionRow {
        @AuraEnabled public String rowKey;
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String requisitionNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String sampleType;
        @AuraEnabled public String sampleTestType;
        @AuraEnabled public String laboratory;
        @AuraEnabled public String samplerName;
        @AuraEnabled public String location;
        @AuraEnabled public Id drinkingWaterComponentId;
        @AuraEnabled public String siteTreatment;
        @AuraEnabled public String siteDescriptor;
        @AuraEnabled public String testName;
        @AuraEnabled public String resultValue;
        @AuraEnabled public String unitOfMeasure;
        @AuraEnabled public String resultDescription;
        @AuraEnabled public Datetime collectionDateTime;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Boolean editable;

        public RequisitionRow(LabTestRequisition__c requisition, LabTestRequired__c testResult) {
            id = requisition.Id;
            rowKey = testResult == null ? String.valueOf(requisition.Id) : requisition.Id + '-' + testResult.Id;
            name = requisition.Name;
            requisitionNumber = requisition.LabTestRequisitionNumber__c;
            status = requisition.Status__c;
            sampleType = requisition.SampleType__c;
            laboratory = requisition.ToLaboratory__c;
            samplerName = requisition.SamplerName__c;
            drinkingWaterComponentId = requisition.Drinking_Water_Component_Name__c;
            if (requisition.Drinking_Water_Component_Name__r != null) {
                location = requisition.Drinking_Water_Component_Name__r.Name;
            }
            siteTreatment = requisition.Site_Treatment__c;
            siteDescriptor = requisition.Site_Descriptor__c;
            if (testResult != null) {
                sampleTestType = testResult.SampleTestType__c;
                if (testResult.Test__r != null) {
                    testName = testResult.Test__r.Name;
                    if (String.isBlank(sampleTestType)) {
                        sampleTestType = testResult.Test__r.SampleTestType__c;
                    }
                }
                resultValue = testResult.ResultValue__c;
                unitOfMeasure = String.isNotBlank(testResult.Unit_of_Measure__c)
                    ? testResult.Unit_of_Measure__c
                    : testResult.UnitOfMeasure__c;
                resultDescription = testResult.ResultCodeDescription__c;
            }
            if (String.isBlank(sampleTestType)) {
                sampleTestType = requisition.TestCategory__c;
            }
            collectionDateTime = requisition.CollectionDateTime__c;
            createdDate = requisition.CreatedDate;
            editable = EDITABLE_STATUSES.contains(requisition.Status__c);
        }
    }
}
