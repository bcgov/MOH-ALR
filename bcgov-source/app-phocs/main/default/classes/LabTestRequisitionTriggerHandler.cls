/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
                15 Sep -  EHIS-5712         -  Deepak      -  added updateDairyRequisitionFlag, setting IsDairy__c from the related Account's RecordType for the dairy-related LabTestRequisition__c record types.
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
    private static final Map<String, String> ADMIN_QUEUE_BY_HEALTH_AUTHORITY = new Map<String, String>{'Fraser Health - FH' => 'Fraser_Admin_Intake_Queue',
        'Interior Health - IH' => 'Interior_Admin_Intake_Queue',
        'Island Health - Island' => 'Island_Admin_Intake_Queue',
        'Northern Health - NH' => 'Northern_Admin_Intake_Queue',
        'Vancouver Coastal Health - VCH' => 'Vancouver_Coastal_Admin_Intake_Queue'
    };
    
    @TestVisible
    private static Boolean throwExceptionForTest = false;

    public static void assignWaterRequisitionsToHealthAuthorityQueue(List<LabTestRequisition__c> newRecords) {
        Id waterRecordTypeId = Schema.SObjectType.LabTestRequisition__c
            .getRecordTypeInfosByDeveloperName().get(PHOCS_WATER_LAB_TEST_REQUISITION_RECORD_TYPE).getRecordTypeId();
        Set<Id> facilityIds = new Set<Id>();
        for (LabTestRequisition__c requisition : newRecords) {
            if (requisition.RecordTypeId == waterRecordTypeId && requisition.FacilityName__c != null) {
                facilityIds.add(requisition.FacilityName__c);
            }
        }
        if (facilityIds.isEmpty()) {
            return;
        }

        Map<Id, Account> facilities = new Map<Id, Account>([
            SELECT Id, HealthAuthority__c
            FROM Account
            WHERE Id IN :facilityIds
        ]);
        Map<String, Id> queueIdsByDeveloperName = new Map<String, Id>();
        for (Group queue : [
            SELECT Id, DeveloperName
            FROM Group
            WHERE Type = 'Queue' AND DeveloperName IN :ADMIN_QUEUE_BY_HEALTH_AUTHORITY.values()
        ]) {
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

    public static void shareQueueOwnedRequisitionsWithCreator(List<LabTestRequisition__c> newRecords) {
        List<LabTestRequisition__Share> shares = new List<LabTestRequisition__Share>();
        for (LabTestRequisition__c requisition : newRecords) {
            if (requisition.OwnerId != null && String.valueOf(requisition.OwnerId).startsWith('00G')
                && requisition.CreatedById != null) {
                shares.add(new LabTestRequisition__Share(
                    ParentId = requisition.Id,
                    UserOrGroupId = requisition.CreatedById,
                    AccessLevel = 'Edit',
                    RowCause = Schema.LabTestRequisition__Share.RowCause.Manual
                ));
            }
        }
        if (!shares.isEmpty()) {
            Database.insert(shares, false);
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
                update requisitionsToUpdate;
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'updateDairyRequisitionFlag', JSON.serialize(newRequisitions), ex);
            throw ex;
        }
    }
}