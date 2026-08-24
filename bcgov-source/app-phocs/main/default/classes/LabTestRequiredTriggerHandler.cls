/**********************************************************************************************
* @Author:      Accenture 
* @Date:        26 Jun 2026
* @Description: The purpose of this class is to Trigger on different trigger handler context.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                26 Jun -  PHOCS-295         -  Accenture   -  BCCDC - Water lab requisition
***********************************************************************************************/
public with sharing class LabTestRequiredTriggerHandler {
    private static final String CLASS_NAME = 'LabTestRequiredTriggerHandler';

    private static final Set<String> SUPPORTED_RECORD_TYPES = new Set<String>{
        'PHOCSDairyProductTestRequired',
        'PHOCSDairyEnvironmentalSwabTestRequired',
        'PHOCSDyeTest',
        'PHOCSFoodLabTestRequired',
        'PHOCSLeadWaterTest',
        'PHOCSWaterLabTestRequired'
    };

/**
* @author: Deepak
* @date: 14 Aug 2026
* @description: The purpose of this method is to populate Facility and Health Authority on Lab Test Required records from the related Lab Test Requisition or Facility. On insert, Facility is populated from the requisition only when Facility is blank. On update, Facility is populated when it is blank or when the Lab Test Requisition changes. Health Authority is populated from the applicable Facility.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void populateFacilityFromRequisition(List<LabTestRequired__c> newRecords, Map<Id, LabTestRequired__c> oldMap) {
        try {
            if (newRecords == null || newRecords.isEmpty()) {
                return;
            }

            Map<Id, Schema.RecordTypeInfo> recordTypeInfoById = Schema.SObjectType.LabTestRequired__c.getRecordTypeInfosById();
            Set<Id> requisitionIds = new Set<Id>();
            Set<Id> facilityIds = new Set<Id>();

            for (LabTestRequired__c labTestRequired : newRecords) {
                if (!isSupportedRecordType(labTestRequired, recordTypeInfoById)) {
                    continue;
                }

                LabTestRequired__c oldLabTestRequired = oldMap == null ? null : oldMap.get(labTestRequired.Id);

                Boolean isInsert = oldLabTestRequired == null;
                Boolean requisitionChanged = !isInsert && labTestRequired.LabTestRequisition__c != oldLabTestRequired.LabTestRequisition__c;
                Boolean facilityChanged = isInsert || labTestRequired.FacilityName__c != oldLabTestRequired.FacilityName__c;

                if (labTestRequired.LabTestRequisition__c != null && (labTestRequired.FacilityName__c == null || requisitionChanged)) {
                    requisitionIds.add(labTestRequired.LabTestRequisition__c);
                }

                if (labTestRequired.FacilityName__c != null && facilityChanged) {
                    facilityIds.add(labTestRequired.FacilityName__c);
                }
            }

            Map<Id, LabTestRequisition__c> requisitionsById = new Map<Id, LabTestRequisition__c>();

            if (!requisitionIds.isEmpty()) {
                requisitionsById = new Map<Id, LabTestRequisition__c>([
                    SELECT Id, FacilityName__c
                    FROM LabTestRequisition__c
                    WHERE Id IN :requisitionIds
                ]);
            }

            for (LabTestRequisition__c requisition : requisitionsById.values()) {
                if (requisition.FacilityName__c != null) {
                    facilityIds.add(requisition.FacilityName__c);
                }
            }

            Map<Id, Account> facilitiesById = new Map<Id, Account>();

            if (!facilityIds.isEmpty()) {
                facilitiesById = new Map<Id, Account>([SELECT Id, HealthAuthority__c FROM Account WHERE Id IN :facilityIds]);
            }

            for (LabTestRequired__c labTestRequired : newRecords) {
                if (!isSupportedRecordType(labTestRequired, recordTypeInfoById)) {
                    continue;
                }

                LabTestRequired__c oldLabTestRequired = oldMap == null ? null : oldMap.get(labTestRequired.Id);

                Boolean isInsert = oldLabTestRequired == null;
                Boolean requisitionChanged = !isInsert && labTestRequired.LabTestRequisition__c != oldLabTestRequired.LabTestRequisition__c;
                Boolean facilityChanged = isInsert || labTestRequired.FacilityName__c != oldLabTestRequired.FacilityName__c;

                if (labTestRequired.LabTestRequisition__c != null && (labTestRequired.FacilityName__c == null || requisitionChanged)) {
                    LabTestRequisition__c requisition = requisitionsById.get(labTestRequired.LabTestRequisition__c);

                    if (requisition != null && requisition.FacilityName__c != null) {
                        labTestRequired.FacilityName__c = requisition.FacilityName__c;

                        Account facility = facilitiesById.get(requisition.FacilityName__c);

                        if (facility != null) {
                            labTestRequired.HealthAuthority__c = facility.HealthAuthority__c;
                        }
                    }
                } else if (facilityChanged && labTestRequired.FacilityName__c != null) {
                    Account facility = facilitiesById.get(labTestRequired.FacilityName__c);

                    if (facility != null) {
                        labTestRequired.HealthAuthority__c = facility.HealthAuthority__c;
                    }
                }
            }
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'populateFacilityFromRequisition', JSON.serialize(newRecords), ex);
            throw ex;
        }
    }

/**
* @author: Deepak
* @date: 14 Aug 2026
* @description: The purpose of this method is to determine whether the Lab Test Required record belongs to one of the supported Lab Test Required record types.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Boolean isSupportedRecordType(LabTestRequired__c labTestRequired, Map<Id, Schema.RecordTypeInfo> recordTypeInfoById) {
        if (labTestRequired == null || labTestRequired.RecordTypeId == null) {
            return false;
        }

        Schema.RecordTypeInfo recordTypeInfo = recordTypeInfoById.get(labTestRequired.RecordTypeId);

        return recordTypeInfo != null && SUPPORTED_RECORD_TYPES.contains(recordTypeInfo.getDeveloperName());
    }
}