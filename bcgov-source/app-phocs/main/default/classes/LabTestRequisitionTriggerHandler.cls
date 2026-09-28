/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
                15 Sep -  EHIS-5712         -  Deepak      -  added updateDairyRequisitionFlag, setting IsDairy__c from the related Account's RecordType for the dairy-related LabTestRequisition__c record types.
                28 Sep -  Orphan Lab Requisitions - Accenture - Restrict orphan field edits, stamp Health Authority/queue on Facility assignment, cascade Facility to Lab Test Required.
***********************************************************************************************/
public with sharing class LabTestRequisitionTriggerHandler {
    private static final String CLASS_NAME = 'LabTestRequisitionTriggerHandler';
    private static final String PHOCS_WATER_LAB_TEST_REQUISITION_RECORD_TYPE = 'PHOCSWaterLabTestRequisition';
    private static final String PHOCS_DAIRY_FACILITY_RECORD_TYPE = 'PHOCSDairyFacility';
    private static final Set<String> DAIRY_REQUISITION_RECORD_TYPE_DEVELOPER_NAMES = new Set<String>{'PHOCSDairyEnvironmentalSwabTesting',
        'PHOCSDairyProductTestRequisition',
        'PHOCSDyeTestRequisition',
        'PHOCSFoodLabTestRequisition',
        'PHOCSLeadWaterTestRequisition',
        'PHOCSRadonTestRequisition',
        'PHOCSWaterLabTestRequisition'
    };
    private static final String MANAGE_ORPHAN_LAB_REQUISITIONS_PERMISSION = 'PHOCSManageOrphanLabRequisitions';
    @TestVisible
    private static final String ORPHAN_FIELD_EDIT_ERROR = 'Only Facility Name, Drinking Water Component Name, Sampling Site, Sampler Name, Specimen Source or EHO Name can be updated on an orphan Lab Test Requisition.';
    
    private static final Set<String> ORPHAN_EDITABLE_FIELDS = new Set<String>{'facilityname__c',
        'drinking_water_component_name__c',
        'samplingsite__c',
        'samplername__c',
        'specimensource__c',
        'dwoehoname__c'
    };
    private static List<Schema.SObjectField> orphanRestrictedFields;
    // FeatureManagement.checkPermission cannot see a PermissionSetAssignment created by a test,
    // so tests set this to drive the orphan field restriction. Null in production.
    @TestVisible
    private static Boolean hasManageOrphanPermissionForTest = null;
    private static final Map<String, String> ADMIN_QUEUE_BY_HEALTH_AUTHORITY = new Map<String, String>{'Fraser Health - FH' => 'Fraser_Admin_Intake_Queue',
        'Interior Health - IH' => 'Interior_Admin_Intake_Queue',
        'Island Health - Island' => 'Island_Admin_Intake_Queue',
        'Northern Health - NH' => 'Northern_Admin_Intake_Queue',
        'Vancouver Coastal Health - VCH' => 'Vancouver_Coastal_Admin_Intake_Queue'
    };
    
    @TestVisible
    private static Boolean throwExceptionForTest = false;
    // ─── Inner class: elevates ONLY DML, not queries ─────────────────────────
    private without sharing class ElevatedDml {
        public void doUpdate(List<SObject> records) {
            update records;
        }
    }

    public static void assignWaterRequisitionsToHealthAuthorityQueue(List<LabTestRequisition__c> newRecords) {
        Id waterRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get(PHOCS_WATER_LAB_TEST_REQUISITION_RECORD_TYPE).getRecordTypeId();
        Id dairyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PHOCS_DAIRY_FACILITY_RECORD_TYPE).getRecordTypeId();
        Set<Id> facilityIds = new Set<Id>();
        for (LabTestRequisition__c requisition : newRecords) {          
            if (requisition.RecordTypeId == waterRecordTypeId && requisition.FacilityName__c != null ) {
                facilityIds.add(requisition.FacilityName__c);
            }
        }
        if (facilityIds.isEmpty()) {
            return;
        }
        
        Map<Id, Account> facilities = new Map<Id, Account>([SELECT Id, RecordTypeId, HealthAuthority__c
            FROM Account WHERE Id IN :facilityIds AND RecordTypeId != :dairyRecordTypeId]);
        
        if (facilities.isEmpty()) {
            return;
        }
        Map<String, Id> queueIdsByDeveloperName = new Map<String, Id>();
        for (Group queue : [SELECT Id, DeveloperName FROM Group
            WHERE Type = 'Queue' AND DeveloperName IN :ADMIN_QUEUE_BY_HEALTH_AUTHORITY.values()]) {
            queueIdsByDeveloperName.put(queue.DeveloperName, queue.Id);
        }
        
        for (LabTestRequisition__c requisition : newRecords) {
            Account facility = facilities.get(requisition.FacilityName__c);
            if (requisition.RecordTypeId != waterRecordTypeId || facility == null) {
                continue;
            }
            requisition.HealthAuthority__c = facility.HealthAuthority__c;
            String queueDeveloperName = ADMIN_QUEUE_BY_HEALTH_AUTHORITY.get(facility.HealthAuthority__c);
            if (queueIdsByDeveloperName.containsKey(queueDeveloperName)) {
                requisition.OwnerId = queueIdsByDeveloperName.get(queueDeveloperName);
            }
        }
    }

   
/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to Update the Lab Requisition Number.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    public static void populateLabTestRequisitionNumber(List<LabTestRequisition__c> newRecords){        
        try{
            if (Test.isRunningTest() && throwExceptionForTest) {
                throw new IllegalArgumentException('Test Exception');
            }
            Id waterLabTestRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get(PHOCS_WATER_LAB_TEST_REQUISITION_RECORD_TYPE).getRecordTypeId();
            
            List<LabTestRequisition__c> requisitionsToupdate = new List<LabTestRequisition__c>();
            Set<Id> requisitionIdsForBarcode = new Set<Id>();
            for (LabTestRequisition__c req : [SELECT Id, Name, FacilityName__r.AccountNumberRTPrefixed__c, LabTestRequisitionNumber__c, LabTestRequisition__c.RecordTypeId
                                              FROM LabTestRequisition__c WHERE Id IN :newRecords]) {
                
                if (String.isBlank(req.LabTestRequisitionNumber__c) && req.FacilityName__r != null
                    && !String.isBlank(req.FacilityName__r.AccountNumberRTPrefixed__c)) {
                    requisitionsToupdate.add(new LabTestRequisition__c(Id = req.Id, LabTestRequisitionNumber__c = generateRequisitionNumber(req)));
                }
                if (req.RecordTypeId == waterLabTestRequisitionRecordTypeId) {
                    requisitionIdsForBarcode.add(req.Id);
                }
            }
            
            if (!requisitionsToupdate.isEmpty()) {
                update requisitionsToupdate;
            }            
            if (!requisitionIdsForBarcode.isEmpty()) {
                System.enqueueJob(new LabTestRequisitionBarcodeQueueable(requisitionIdsForBarcode));
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'populateLabTestRequisitionNumber', null, ex);
            throw ex;
        }
    }    

/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to Set the Lab Requisition Number.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    private static String generateRequisitionNumber(LabTestRequisition__c req) {
        String requiredSequenceNumber = 'PHOCS-' + req.FacilityName__r.AccountNumberRTPrefixed__c + '-' + req.Name.replace('LTR-', '');
        return requiredSequenceNumber;
    }

/**
* @author: Deepak
* @date: 15 Sep 2026
* @description: Sets IsDairy__c on the dairy-related LabTestRequisition__c record types
* @return: void
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void updateDairyRequisitionFlag(List<LabTestRequisition__c> newRequisitions, Map<Id, LabTestRequisition__c> oldRequisitionsMap, Boolean isUpdate) {
        try {
            Set<Id> facilityIds = new Set<Id>();
            Set<Id> dairyRequisitionRecordTypeIds = new Set<Id>();
            Map<Id, LabTestRequisition__c> requisitionsToProcessMap = new Map<Id, LabTestRequisition__c>();
            Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName();

            for (String developerName : DAIRY_REQUISITION_RECORD_TYPE_DEVELOPER_NAMES) {
                if (recordTypeInfoMap.containsKey(developerName)) {
                    dairyRequisitionRecordTypeIds.add(recordTypeInfoMap.get(developerName).getRecordTypeId());
                }
            }

            for (LabTestRequisition__c newRequisition : newRequisitions) {
                if (!dairyRequisitionRecordTypeIds.contains(newRequisition.RecordTypeId)) {
                    continue;
                }
                if (!isUpdate) {
                    if (newRequisition.FacilityName__c != null) {
                        requisitionsToProcessMap.put(newRequisition.Id, newRequisition);
                        facilityIds.add(newRequisition.FacilityName__c);
                    }
                } else {
                    LabTestRequisition__c oldRequisition = oldRequisitionsMap.get(newRequisition.Id);
                    if (newRequisition.FacilityName__c != oldRequisition.FacilityName__c) {
                        requisitionsToProcessMap.put(newRequisition.Id, newRequisition);
                        if (newRequisition.FacilityName__c != null) {
                            facilityIds.add(newRequisition.FacilityName__c);
                        }
                    }
                }
            }

            if (requisitionsToProcessMap.isEmpty()) {
                return;
            }

            Map<Id, Account> facilityMap = new Map<Id, Account>([SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN :facilityIds WITH SECURITY_ENFORCED]);

            List<LabTestRequisition__c> requisitionsToUpdate = new List<LabTestRequisition__c>();
            for (LabTestRequisition__c newRequisition : requisitionsToProcessMap.values()) {
                Account facility = newRequisition.FacilityName__c != null ? facilityMap.get(newRequisition.FacilityName__c) : null;
                LabTestRequisition__c requisitionToUpdate = new LabTestRequisition__c(Id = newRequisition.Id);
                if (facility != null && facility.RecordType.DeveloperName == PHOCS_DAIRY_FACILITY_RECORD_TYPE) {
                    requisitionToUpdate.IsDairy__c = true;
                } else if (facility == null && newRequisition.IsDairy__c == true) {
                    requisitionToUpdate.IsDairy__c = true;
                } else {
                    requisitionToUpdate.IsDairy__c = false;
                }
                requisitionsToUpdate.add(requisitionToUpdate);
            }

            if (!requisitionsToUpdate.isEmpty()) {
                                new ElevatedDml().doUpdate(requisitionsToUpdate); // ← elevated
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'updateDairyRequisitionFlag', JSON.serialize(newRequisitions), ex);
            throw ex;
        }
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions AC#1 - An orphan is a Water Lab Test Requisition created by the lab integration
*               without a Facility. A user with the PHOCSManageOrphanLabRequisitions custom permission may only change
*               Facility Name and/or Drinking Water Component Name on an orphan; any other field change is rejected.
*/
    public static void restrictOrphanFieldEdits(List<LabTestRequisition__c> newRequisitions, Map<Id, LabTestRequisition__c> oldRequisitionsMap) {
        try {
            if (Test.isRunningTest() && throwExceptionForTest) {
                throw new IllegalArgumentException('Test Exception');
            }
            if (newRequisitions == null || newRequisitions.isEmpty() || oldRequisitionsMap == null
                || !hasManageOrphanLabRequisitionsPermission()) {
                return;
            }
            Id waterRecordTypeId = getWaterRecordTypeId();
            for (LabTestRequisition__c newRequisition : newRequisitions) {
                LabTestRequisition__c oldRequisition = oldRequisitionsMap.get(newRequisition.Id);
                if (!isOrphan(oldRequisition, waterRecordTypeId)) {
                    continue;
                }
                for (Schema.SObjectField field : getOrphanRestrictedFields()) {
                    if (isValueChanged(newRequisition.get(field), oldRequisition.get(field))) {
                        newRequisition.addError(ORPHAN_FIELD_EDIT_ERROR);
                        break;
                    }
                }
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'restrictOrphanFieldEdits', JSON.serialize(newRequisitions), ex);
            throw ex;
        }
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions AC#4 - When a Facility is assigned to an orphan Water Lab Test Requisition,
*               stamp the Health Authority from the Facility and move ownership to that Health Authority's Admin
*               Intake queue, the same as a Water requisition created with a Facility. Once Health Authority is
*               populated the orphan sharing rule stops matching and the Health Authority sharing rules apply.
*/
    public static void assignOrphanRequisitionsToFacility(List<LabTestRequisition__c> newRequisitions, Map<Id, LabTestRequisition__c> oldRequisitionsMap) {
        try {
            if (Test.isRunningTest() && throwExceptionForTest) {
                throw new IllegalArgumentException('Test Exception');
            }
            if (newRequisitions == null || newRequisitions.isEmpty() || oldRequisitionsMap == null) {
                return;
            }
            Id waterRecordTypeId = getWaterRecordTypeId();
            List<LabTestRequisition__c> assignedRequisitions = new List<LabTestRequisition__c>();
            for (LabTestRequisition__c newRequisition : newRequisitions) {
                if (isFacilityAssigned(newRequisition, oldRequisitionsMap.get(newRequisition.Id), waterRecordTypeId)) {
                    assignedRequisitions.add(newRequisition);
                }
            }
            if (!assignedRequisitions.isEmpty()) {
                assignWaterRequisitionsToHealthAuthorityQueue(assignedRequisitions);
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'assignOrphanRequisitionsToFacility', JSON.serialize(newRequisitions), ex);
            throw ex;
        }
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions AC#4 - When a Facility is assigned to an orphan Water Lab Test Requisition,
*               cascade the Facility and Health Authority to its Lab Test Required results that have no Facility,
*               so the results become visible to the same Health Authority as the requisition. The DML is elevated
*               because the authorized user only has Read access to those results.
*/
    public static void cascadeFacilityToLabTestsRequired(List<LabTestRequisition__c> newRequisitions, Map<Id, LabTestRequisition__c> oldRequisitionsMap) {
        try {
            if (Test.isRunningTest() && throwExceptionForTest) {
                throw new IllegalArgumentException('Test Exception');
            }
            if (newRequisitions == null || newRequisitions.isEmpty() || oldRequisitionsMap == null) {
                return;
            }
            Id waterRecordTypeId = getWaterRecordTypeId();
            Map<Id, LabTestRequisition__c> assignedRequisitionsById = new Map<Id, LabTestRequisition__c>();
            for (LabTestRequisition__c newRequisition : newRequisitions) {
                if (isFacilityAssigned(newRequisition, oldRequisitionsMap.get(newRequisition.Id), waterRecordTypeId)) {
                    assignedRequisitionsById.put(newRequisition.Id, newRequisition);
                }
            }
            if (assignedRequisitionsById.isEmpty()) {
                return;
            }

            List<LabTestRequired__c> labTestsToUpdate = new List<LabTestRequired__c>();
            for (LabTestRequired__c labTestRequired : [SELECT Id, LabTestRequisition__c FROM LabTestRequired__c
                                                       WHERE LabTestRequisition__c IN :assignedRequisitionsById.keySet()
                                                       AND FacilityName__c = null]) {
                LabTestRequisition__c requisition = assignedRequisitionsById.get(labTestRequired.LabTestRequisition__c);
                labTestsToUpdate.add(new LabTestRequired__c(Id = labTestRequired.Id,
                    FacilityName__c = requisition.FacilityName__c,
                    HealthAuthority__c = requisition.HealthAuthority__c));
            }

            if (!labTestsToUpdate.isEmpty()) {
                new ElevatedDml().doUpdate(labTestsToUpdate);
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'cascadeFacilityToLabTestsRequired', JSON.serialize(newRequisitions), ex);
            throw ex;
        }
    }

    private static Boolean hasManageOrphanLabRequisitionsPermission() {
        if (Test.isRunningTest() && hasManageOrphanPermissionForTest != null) {
            return hasManageOrphanPermissionForTest;
        }
        return FeatureManagement.checkPermission(MANAGE_ORPHAN_LAB_REQUISITIONS_PERMISSION);
    }

    private static Id getWaterRecordTypeId() {
        return Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName()
            .get(PHOCS_WATER_LAB_TEST_REQUISITION_RECORD_TYPE).getRecordTypeId();
    }

    private static Boolean isOrphan(LabTestRequisition__c requisition, Id waterRecordTypeId) {
        return requisition != null
            && requisition.RecordTypeId == waterRecordTypeId
            && requisition.FacilityName__c == null
            && requisition.Drinking_Water_Component_Name__c == null;
    }

    private static Boolean isFacilityAssigned(LabTestRequisition__c requisition, LabTestRequisition__c oldRequisition, Id waterRecordTypeId) {
        return oldRequisition != null
            && requisition.RecordTypeId == waterRecordTypeId
            && oldRequisition.FacilityName__c == null
            && requisition.FacilityName__c != null;
    }

    private static List<Schema.SObjectField> getOrphanRestrictedFields() {
        if (orphanRestrictedFields == null) {
            orphanRestrictedFields = new List<Schema.SObjectField>();
            for (Schema.SObjectField field : Schema.SObjectType.LabTestRequisition__c.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if (fieldDescribe.isUpdateable() && !ORPHAN_EDITABLE_FIELDS.contains(fieldDescribe.getName().toLowerCase())) {
                    orphanRestrictedFields.add(field);
                }
            }
        }
        return orphanRestrictedFields;
    }

    private static Boolean isValueChanged(Object newValue, Object oldValue) {
        if (newValue == null || oldValue == null) {
            return newValue != oldValue;
        }
        if (newValue instanceof String) {
            return !((String) newValue).equals((String) oldValue);
        }
        return newValue != oldValue;
    }
}