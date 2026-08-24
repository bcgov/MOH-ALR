/**********************************************************************************************
* @Author:      Accenture 
* @Date:        14 Jul 2026
* @Description: The purpose of this class is to REST service that receives inbound PHOCS Lab Results from BCCDC. Currently supports Water Lab Results and is designed for future expansion to additional laboratory integrations.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                21 Jul -  PHOCS-4529        -  Accenture   -  REST service that receives inbound PHOCS Lab Results from BCCDC.
***********************************************************************************************/
@RestResource(urlMapping='/PHOCSLabResults/*')
global with sharing class PHOCSLabResults {
    public static final String CLASS_NAME = 'PHOCSLabResults';
    public static final Integer HTTP_SUCCESS = 200;
    public static final Integer HTTP_BAD_REQUEST = 400;
    public static final Integer HTTP_SERVER_ERROR = 500;
    public static final String STATUS_REQUESTED = 'Requested';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_CANCELLED = 'Cancelled';
    public static final String RECORDTYPE_WATER = 'PHOCSWaterLabTestRequired';
    public static final Integer RESULT_DESCRIPTION_LENGTH = 255;
    public static final String RESPONSE_SUCCESS = 'Lab Results processed successfully.';
    public static final String RESPONSE_INVALID_REQUEST = 'Invalid request payload.';
    public static final String RESPONSE_ERROR = 'Unexpected error occurred.';
    public static final String ATTR_TYPE_SAMPLE_TYPE = 'SampleType';
    public static final String ATTR_TYPE_SPECIMEN_SOURCE = 'SpecimenSource';
    public static final String ATTR_TYPE_TEST_CATEGORY = 'TestCategory';
    public static final String ATTR_TYPE_METHOD = 'Method';
    public static final String ATTR_TYPE_REQUISITION_STATUS = 'RequisitionStatus';
    public static final String DEFAULT_SPECIMEN_SOURCE = 'Other';
    public static final Id LAB_REQUISITION_RTID = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequisition').getRecordTypeId();
    public static Boolean throwTestException = false;
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: REST endpoint for inbound PHOCS laboratory results.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    @HttpPatch
    global static void processRequest() {
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            String requestBody = RestContext.request.requestBody.toString();
            System.debug(LoggingLevel.INFO, 'Incoming Payload: ' + requestBody);
            RequestWrapper request = (RequestWrapper)JSON.deserialize(requestBody, RequestWrapper.class);            
            validateRequest(request);            
            processWaterLabResults(request);            
            response.statusCode = HTTP_SUCCESS;
            response.responseBody = Blob.valueOf(JSON.serializePretty(buildSuccessResponse()));            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'processRequest', RestContext.request.requestBody.toString(), ex);
            System.enqueueJob(new PHOCSLabIntExceptionEmailQueueable(CLASS_NAME, ex.getMessage(), ex.getTypeName()));
            RestContext.response.statusCode = HTTP_SERVER_ERROR;
            RestContext.response.responseBody = Blob.valueOf(JSON.serializePretty(buildErrorResponse(RESPONSE_ERROR)));
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Validates inbound request.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void validateRequest(RequestWrapper request) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            if (request == null) {
                throw new DmlException(RESPONSE_INVALID_REQUEST);
            }
            
            if (request.record == null) {
                throw new DmlException('Record node is required.');
            }
            
            if (request.record.labTestRequisition == null) {
                throw new DmlException('LabTestRequisition node is required.');
            }
            
            if (String.isBlank(request.record.labTestRequisition.requisitionNumber)) {
                throw new DmlException('RequisitionNumber is required.');
            }
            
            if (request.record.results == null || request.record.results.isEmpty()) {
                throw new DmlException('At least one lab result is required.');
            }
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'validateRequest', JSON.serialize(request), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Main orchestration method.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static void processWaterLabResults(RequestWrapper request) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            Map<String, Map<String, String>> mappingConfig = getMappingConfig();
            LabTestRequisition__c requisition = getOrCreateLabTestRequisition(request.record.labTestRequisition, mappingConfig);
            attachInboundJson(requisition.Id, request.record.labTestRequisition.requisitionNumber, JSON.serializePretty(request));
            Map<String, List<ResultWrapper>> groupedResults = groupResultsByTestCode(request.record.results);            
            Map<String, LabTestMasterList__c> labTestMasterMap = getLabTestMasterMap(groupedResults.keySet());
            
            List<LabTestRequired__c> labTestRequiredRecords = buildLabTestRequiredRecords(requisition, request.record.labTestRequisition, groupedResults, labTestMasterMap, mappingConfig);
            
            saveLabTestRequiredRecords(labTestRequiredRecords);
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'processWaterLabResults', JSON.serialize(request), ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Attaches inbound JSON payload to the Lab Test Requisition for audit purposes.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void attachInboundJson(Id requisitionId, String requisitionNumber, String jsonPayload){
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            if (requisitionId == null || String.isBlank(jsonPayload)) {
                return;
            }
            
            if (!Schema.sObjectType.ContentVersion.isCreateable()) {
                throw new NoAccessException();
            }
            
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'BCCDC Lab Results - ' + requisitionNumber + ' - ' + System.now().format('yyyyMMdd');
            contentVersion.PathOnClient = 'BCCDC_LabResults.txt';
            contentVersion.VersionData = Blob.valueOf(jsonPayload);
            contentVersion.FirstPublishLocationId = requisitionId;
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ contentVersion });
            
            insert decision.getRecords();
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'attachInboundJson', String.valueOf(requisitionId), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: 
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static ResponseWrapper buildSuccessResponse() {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            ResponseWrapper response = new ResponseWrapper();
            response.success = true;
            response.message = RESPONSE_SUCCESS;
            
            return response;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'buildSuccessResponse', null, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Builds error response.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static ResponseWrapper buildErrorResponse(String message) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            ResponseWrapper response = new ResponseWrapper();
            response.success = false;
            response.message = message;
            
            return response;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'buildErrorResponse', message, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Returns an existing requisition or creates a new one.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static LabTestRequisition__c getOrCreateLabTestRequisition(LabTestRequisitionWrapper wrapper, Map<String, Map<String, String>> mappingConfig) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            List<LabTestRequisition__c> requisitions = [SELECT Id, Status__c, LabTestRequisitionNumber__c, CollectionDateTime__c FROM LabTestRequisition__c 
                                                        WHERE LabTestRequisitionNumber__c =: wrapper.requisitionNumber AND RecordTypeId =: LAB_REQUISITION_RTID LIMIT 1];
            
            if (!requisitions.isEmpty()) {
                LabTestRequisition__c requisition = requisitions[0];
                updateRequisitionStatus(requisition, wrapper, mappingConfig);
                return requisition;
            }            
            return createLabTestRequisition(wrapper, mappingConfig);
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getOrCreateLabTestRequisition', JSON.serialize(wrapper), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Creates a new Lab Test Requisition.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static LabTestRequisition__c createLabTestRequisition(LabTestRequisitionWrapper wrapper, Map<String, Map<String, String>> mappingConfig) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            if (!Schema.sObjectType.LabTestRequisition__c.isCreateable()) {
                throw new NoAccessException();
            }
            
            LabTestRequisition__c requisition = new LabTestRequisition__c();
            requisition.LabTestRequisitionNumber__c = wrapper.requisitionNumber;
            requisition.DWOEHOName__c = wrapper.dWOEHOName;
            requisition.SpecimenSource__c = getMappedValue(mappingConfig, ATTR_TYPE_SPECIMEN_SOURCE, wrapper.specimenSource, DEFAULT_SPECIMEN_SOURCE);
            requisition.BoilAdvisory__c = wrapper.boilAdvisory;
            requisition.SampleType__c = getMappedValue(mappingConfig, ATTR_TYPE_SAMPLE_TYPE, wrapper.sampleType, null);
            requisition.CollectionDateTime__c = wrapper.reportedOn;
            requisition.RecordTypeId = LAB_REQUISITION_RTID;
            requisition.TestCategory__c = getMappedValue(mappingConfig, ATTR_TYPE_TEST_CATEGORY, wrapper.testCategory, null);
            requisition.Site_Descriptor__c = wrapper.samplingSiteName;
            requisition.Site_Number__c = wrapper.samplingSiteID;
            String jsonValue = wrapper.samplingSiteTreatment == null ? null : wrapper.samplingSiteTreatment.toUpperCase();
            requisition.Site_Treatment__c = mappingConfig.get('SamplingSiteTreatment').get(jsonValue);
            requisition.Status__c = wrapper.requisitionStatus == 'F' ? STATUS_COMPLETED : STATUS_SUBMITTED;
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<SObject>{ requisition });
            
            LabTestRequisition__c safeRecord = (LabTestRequisition__c)decision.getRecords()[0];
            
            insert safeRecord;
            
            return safeRecord;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'createLabTestRequisition', JSON.serialize(wrapper), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Updates requisition status.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void updateRequisitionStatus(LabTestRequisition__c requisition, LabTestRequisitionWrapper wrapper, Map<String, Map<String, String>> mappingConfig) {
        try {
            if (Test.isRunningTest() && throwTestException) {
                throw new DmlException('Test Exception');
            }
            
            if (!Schema.sObjectType.LabTestRequisition__c.isUpdateable()) {
                throw new NoAccessException();
            }
            
            requisition.Status__c = wrapper.requisitionStatus == 'F' ? STATUS_COMPLETED : STATUS_SUBMITTED;
            requisition.CollectionDateTime__c = wrapper.reportedOn;
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, new List<SObject>{ requisition });
            
            update decision.getRecords();
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'updateRequisitionStatus', JSON.serialize(wrapper), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Groups results by Test Code.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, List<ResultWrapper>> groupResultsByTestCode(List<ResultWrapper> results) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            Map<String, List<ResultWrapper>> groupedResults = new Map<String, List<ResultWrapper>>();
            
            for (ResultWrapper result : results) {
                if (String.isBlank(result.testCodeID)) {
                    continue;
                }
                
                if (!groupedResults.containsKey(result.testCodeID)) {
                    groupedResults.put(result.testCodeID, new List<ResultWrapper>());
                }
                
                groupedResults.get(result.testCodeID).add(result);
            }
            
            return groupedResults;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'groupResultsByTestCode', JSON.serialize(results), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Builds the ResultCodeDescription.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String buildResultDescription(List<ResultWrapper> results) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            List<String> descriptions = new List<String>();
            
            for (ResultWrapper result : results) {
                if (String.isNotBlank(result.resultValueDescription)) {
                    descriptions.add(result.resultValueDescription.trim());
                } else if (String.isNotBlank(result.resultValueCode)) {
                    descriptions.add(result.resultValueCode.trim());
                }
            }
            
            String finalDescription = String.join(descriptions, ' - ');
            
            if (finalDescription.length() > RESULT_DESCRIPTION_LENGTH) {
                finalDescription = finalDescription.substring(0, RESULT_DESCRIPTION_LENGTH);
            }
            
            return finalDescription;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'buildResultDescription', JSON.serialize(results), ex);
            throw ex;
        }
    }
    
    /**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Returns Lab Test Master records keyed by Test Code.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static Map<String, LabTestMasterList__c> getLabTestMasterMap(Set<String> testCodes) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            Map<String, LabTestMasterList__c> masterMap = new Map<String, LabTestMasterList__c>();
            
            if (testCodes.isEmpty()) {
                return masterMap;
            }
            
            for (LabTestMasterList__c record : [SELECT Id, ExternalId__c FROM LabTestMasterList__c WHERE ExternalId__c IN :testCodes]) {
                masterMap.put(record.ExternalId__c, record);
            }
            
            return masterMap;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getLabTestMasterMap', JSON.serialize(testCodes), ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Builds Lab Test Required records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static List<LabTestRequired__c> buildLabTestRequiredRecords(LabTestRequisition__c requisition, LabTestRequisitionWrapper wrapper, Map<String, List<ResultWrapper>> groupedResults, Map<String, LabTestMasterList__c> masterMap, Map<String, Map<String, String>> mappingConfig) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            List<LabTestRequired__c> records = new List<LabTestRequired__c>();
            
            Id recordTypeId = getWaterLabRecordTypeId();
            
            for (String testCode : groupedResults.keySet()) {
                List<ResultWrapper> resultGroup = groupedResults.get(testCode);
                ResultWrapper firstResult = resultGroup[0];
                
                LabTestRequired__c record = new LabTestRequired__c();
                record.RecordTypeId = recordTypeId;
                record.ExternalId__c = wrapper.requisitionNumber + '-' + testCode;
                record.LabTestRequisition__c = requisition.Id;
                record.TestCategory__c = getWaterTestCategory(wrapper.sampleType);
                record.Method__c = getMappedValue(mappingConfig, ATTR_TYPE_METHOD, wrapper.method, wrapper.method);
                record.TestDate__c = wrapper.testDate;
                record.ReportedOn__c = wrapper.reportedOn;
                record.StatusCode__c = firstResult.statusCategory;
                record.Status__c = mapStatus(firstResult.statusCategory, mappingConfig);
                record.ResultValue__c = populateResultValue(resultGroup);
                record.ResultCodeDescription__c = buildResultDescription(resultGroup);
                record.Unit_of_Measure__c = firstResult.unitOfMeasure;
                record.SampleTestType__c = getMappedValue(mappingConfig, ATTR_TYPE_TEST_CATEGORY, wrapper.testCategory, null);
                
                
                if (masterMap.containsKey(testCode)) {
                    record.Test__c = masterMap.get(testCode).Id;
                }
                
                records.add(record);
            }
            
            return records;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'buildLabTestRequiredRecords', JSON.serialize(groupedResults), ex);
            throw ex;
        }
    }

/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Builds the ResultCodeValue.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    public static String populateResultValue(List<ResultWrapper> resultGroup) {
        try {
            if (Test.isRunningTest() && throwTestException) {
                throw new DmlException('Test Exception');
            }
            
            if (resultGroup == null || resultGroup.isEmpty()) {
                return null;
            }
            
            if (resultGroup.size() == 1) {
                ResultWrapper result = resultGroup[0];
                return String.isNotBlank(result.resultValueDescription) ? result.resultValueDescription : result.resultValueCode;
            }
            
            for (ResultWrapper result : resultGroup) {
                if (String.isBlank(result.resultValueDescription)) {
                    return result.resultValueCode;
                }
            }
            return null;
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'populateResultValue', JSON.serialize(resultGroup), ex);
            throw ex;
        }
    }    

/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Builds the WaterTestCategory on lab test required.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    public static String getWaterTestCategory(String sampleType) {
        try {
            if (Test.isRunningTest() && throwTestException) {
                throw new DmlException('Test Exception');
            }
            
            if (String.isBlank(sampleType)) {
                return 'Other water';
            }
            
            String value = String.isBlank(sampleType) ? '' : sampleType.toLowerCase();
            return value.contains('drinking') ? 'Drinking water' : value.contains('pool') ? 'Recreational water' : 'Other water';
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getWaterTestCategory', sampleType, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Upserts Lab Test Required records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void saveLabTestRequiredRecords(List<LabTestRequired__c> records) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            if (records.isEmpty()) {
                return;
            }
            
            if (!Schema.sObjectType.LabTestRequired__c.isCreateable() && !Schema.sObjectType.LabTestRequired__c.isUpdateable()) {
                throw new NoAccessException();
            }
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPSERTABLE, records);
            
            List<LabTestRequired__c> safeRecords = (List<LabTestRequired__c>)decision.getRecords();
            
            Database.UpsertResult[] results = Database.upsert(safeRecords, LabTestRequired__c.ExternalId__c, false);
            
            for (Database.UpsertResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error err : result.getErrors()) {
                        LogService.logAndPublish(CLASS_NAME, 'saveLabTestRequiredRecords', err.getMessage(), new DmlException(err.getMessage()));
                    }
                }
            }
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'saveLabTestRequiredRecords', JSON.serialize(records), ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Maps BCCDC status to Salesforce status using custom metadata configuration.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String mapStatus(String statusCode, Map<String, Map<String, String>> mappingConfig) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            return getMappedValue(mappingConfig, ATTR_TYPE_REQUISITION_STATUS, statusCode, STATUS_REQUESTED);
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'mapStatus', statusCode, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 27 Jul 2026
* @description: Loads all PHOCS Lab Integration Query & Mapping custom metadata records into a nested map keyed by AttributeType and uppercased JSON Value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Map<String, Map<String, String>> getMappingConfig() {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            Map<String, Map<String, String>> mappingConfig = new Map<String, Map<String, String>>();
            
            for (PHOCSLabIntegrationQueryMapping__mdt mapping : [SELECT AttributeType__c, JSON_Value__c, Salesforce_Value__c FROM PHOCSLabIntegrationQueryMapping__mdt WHERE AttributeType__c != null AND JSON_Value__c != null]) {
                if (!mappingConfig.containsKey(mapping.AttributeType__c)) {
                    mappingConfig.put(mapping.AttributeType__c, new Map<String, String>());
                }
                
                mappingConfig.get(mapping.AttributeType__c).put(mapping.JSON_Value__c.toUpperCase(), mapping.Salesforce_Value__c);
            }
            
            return mappingConfig;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getMappingConfig', null, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 27 Jul 2026
* @description: Resolves the Salesforce value for a given AttributeType and incoming JSON value, comparing case-insensitively. Returns the supplied default when no configuration match is found.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String getMappedValue(Map<String, Map<String, String>> mappingConfig, String attributeType, String jsonValue, String defaultValue) {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            if (String.isBlank(jsonValue)) {
                return defaultValue;
            }
            
            Map<String, String> valuesByJson = mappingConfig.get(attributeType);
            
            if (valuesByJson == null) {
                return defaultValue;
            }
            
            String mappedValue = valuesByJson.get(jsonValue.toUpperCase());
            
            if (String.isBlank(mappedValue)) {
                return defaultValue;
            }
            
            return mappedValue;
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getMappedValue', attributeType + ':' + jsonValue, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Returns Water Lab Test Required Record Type Id.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Id getWaterLabRecordTypeId() {
        try {
            if (Test.isRunningTest() && throwTestException){
                throw new DmlException('Test Exception');
            }
            Schema.RecordTypeInfo rtInfo = Schema.SObjectType.LabTestRequired__c.getRecordTypeInfosByDeveloperName().get(RECORDTYPE_WATER);
            
            if (rtInfo == null) {
                throw new DmlException('Record Type not found : ' + RECORDTYPE_WATER);
            }
            
            return rtInfo.getRecordTypeId();
            
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getWaterLabRecordTypeId', RECORDTYPE_WATER, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Response Wrapper
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public class ResponseWrapper {
        public Boolean success;
        public String message;
    }
    
/**
* @author: Deepak
* @date: 21 Jul 2026
* @description: Request Wrapper
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public class RequestWrapper {
        public RecordWrapper record;
    }
    
    public class RecordWrapper {
        public LabTestRequisitionWrapper labTestRequisition;
        public List<ResultWrapper> results;
    }
    
    public class LabTestRequisitionWrapper {
        public String requisitionNumber;
        public String facilityName;
        public String dWOEHOName;
        public String samplingSiteName;
        public String samplingSiteAddress;
        public String samplingSiteID;
        public String samplingSiteTreatment;
        public String systemType;
        public String specimenSource;
        public String boilAdvisory;
        public String sampleType;
        public String testCategory;
        public String method;
        public Datetime reportedOn;
        public Datetime testDate;
        public String requisitionStatus;
    }
    
    public class ResultWrapper {
        public String testCodeID;
        public String resultValueCode;
        public String resultValueDescription;
        public String unitOfMeasure;
        public String statusCategory;
    }
    
}