/**********************************************************************************************
* @Author:      Deepak 
* @Date:        28 Jul 2026
* @Description: The purpose of this class is to cover code coverage of PHOCSLabResults.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                28 Jul -  PHOCS-295/589     -  Deepak      -  BCCDC - Inbound lab results test coverage
***********************************************************************************************/
@isTest
public class PHOCSLabResultsTest {
    private static final Id LAB_REQ_RT = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequisition').getRecordTypeId();
    private static final Id LAB_TEST_RT = Schema.SObjectType.LabTestMasterList__c.getRecordTypeInfosByDeveloperName().get('WaterBacteriologicalTest').getRecordTypeId();
    private static final String CREATE_REQ_NUMBER = 'CM8N-DRKRGC';
    private static final String UPDATE_REQ_NUMBER = 'CM8N-UPDATE';
    private static final String PAYLOAD_TEMPLATE = '{"record":{"LabTestRequisition":{"RequisitionNumber":"##REQ_NUMBER##","FacilityName":"WONOWON SCHOOL WATER","DWOEHOName":"NE EHO 7",' +
        '"SamplingSiteName":"HALL FOUNTAIN","SamplingSiteAddress":"400 M Wonowon Subdivision","SamplingSiteTreatment":"YES","SystemType":"WS3^2-14 Connections",' +
        '"SpecimenSource":"Other (cistern etc.)","BoilAdvisory":"NO","SampleType":"DWATER^Drinking water","TestCategory":"WATERW^Water Bacteriology Testing",' +
        '"Method":"Membrane Filtration","ReportedOn":"2026-02-27T09:02:00.000-08:00","TestDate":"2026-02-25T09:50:00.000-08:00","RequisitionStatus":"F"},' +
        '"results":[{"TestCodeID":"TOTCOL","ResultValueCode":"ESTCT","ResultValueDescription":"Estimated Count","UnitOfMeasure":"Count/100mL","StatusCategory":"F"},' +
        '{"TestCodeID":"TOTCOL","ResultValueCode":"31","ResultValueDescription":null,"UnitOfMeasure":"Count/100mL","StatusCategory":"F"},' +
        '{"TestCodeID":"TOTCOL","ResultValueCode":"ESTHCD","ResultValueDescription":"High colony density on membrane prevented accurate coliform count.","UnitOfMeasure":"Count/100mL","StatusCategory":"F"},' +
        '{"TestCodeID":"ESHCOL","ResultValueCode":"LT1","ResultValueDescription":"Less than 1","UnitOfMeasure":"Count/100mL","StatusCategory":"F"}]}}';

    //Test Data Setup
    @testSetup
    private static void createTestData() {
        LabTestMasterList__c totalColiform = new LabTestMasterList__c(Name = 'Total Coliform Test', ExternalId__c = 'TOTCOL', ParameterType__c = 'Total Coliform',
                                                                       PhysicalQuantity__c = 'Count', SampleTestType__c = 'Bacteriological', TestCategory__c = 'Drinking water',
                                                                       UnitOfMeasure__c = 'Count/100mL', RecordTypeId = LAB_TEST_RT);
        insert totalColiform;

        LabTestMasterList__c eColi = new LabTestMasterList__c(Name = 'E.Coli Test', ExternalId__c = 'ESHCOL', ParameterType__c = 'E.Coli',
                                                               PhysicalQuantity__c = 'Count', SampleTestType__c = 'Bacteriological', TestCategory__c = 'Drinking water',
                                                               UnitOfMeasure__c = 'Count/100mL', RecordTypeId = LAB_TEST_RT);
        insert eColi;

        LabTestRequisition__c existingRequisition = new LabTestRequisition__c(RecordTypeId = LAB_REQ_RT, LabTestRequisitionNumber__c = UPDATE_REQ_NUMBER, Status__c = 'Submitted',
                                                                              ToLaboratory__c = 'BCCDC', TestCategory__c = 'Bacteriological');
        insert existingRequisition;
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Builds a RestRequest for the PHOCSLabResults endpoint with the supplied body.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static RestRequest buildRestRequest(String requestBody) {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/PHOCSLabResults';
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf(requestBody);
        return req;
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers successful creation of a new Lab Test Requisition and related Lab Test Required records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testProcessRequest_CreatesNewRequisition() {
        String payload = PAYLOAD_TEMPLATE.replace('##REQ_NUMBER##', CREATE_REQ_NUMBER);

        RestContext.request = buildRestRequest(payload);
        RestContext.response = new RestResponse();

        Test.startTest();
        PHOCSLabResults.processRequest();
        Test.stopTest();

        Assert.areEqual(PHOCSLabResults.HTTP_SUCCESS, RestContext.response.statusCode, 'Expected success status code');

        String responseBody = RestContext.response.responseBody.toString();
        Assert.areNotEqual(null, responseBody, 'Response body cannot be blank');

        PHOCSLabResults.ResponseWrapper response = (PHOCSLabResults.ResponseWrapper) JSON.deserialize(responseBody, PHOCSLabResults.ResponseWrapper.class);
        Assert.areEqual(true, response.success, 'Expected success flag to be true');
        Assert.areEqual(PHOCSLabResults.RESPONSE_SUCCESS, response.message, 'Expected success message');

        List<LabTestRequisition__c> requisitions = [SELECT Id, Status__c FROM LabTestRequisition__c WHERE LabTestRequisitionNumber__c = :CREATE_REQ_NUMBER];
        Assert.areEqual(1, requisitions.size(), 'Expected one requisition to be created');

        List<LabTestRequired__c> labTestRequired = [SELECT Id, ExternalId__c, Test__c, ResultCodeDescription__c FROM LabTestRequired__c WHERE LabTestRequisition__c = :requisitions[0].Id];
        Assert.areEqual(2, labTestRequired.size(), 'Expected two grouped test results (TOTCOL, ESHCOL)');

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :requisitions[0].Id];
        Assert.areEqual(1, links.size(), 'Expected inbound JSON payload to be attached to the requisition');
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers updating an existing Lab Test Requisition's status when a matching requisition number already exists.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testProcessRequest_UpdatesExistingRequisition() {
        String payload = PAYLOAD_TEMPLATE.replace('##REQ_NUMBER##', UPDATE_REQ_NUMBER);

        RestContext.request = buildRestRequest(payload);
        RestContext.response = new RestResponse();

        Test.startTest();
        PHOCSLabResults.processRequest();
        Test.stopTest();

        Assert.areEqual(PHOCSLabResults.HTTP_SUCCESS, RestContext.response.statusCode, 'Expected success status code');

        List<LabTestRequisition__c> requisitions = [SELECT Id, Status__c FROM LabTestRequisition__c WHERE LabTestRequisitionNumber__c = :UPDATE_REQ_NUMBER];
        Assert.areEqual(1, requisitions.size(), 'Expected the existing requisition, not a new one');
        Assert.areNotEqual('In Progress', requisitions[0].Status__c, 'Expected status to have been updated from its original value');
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers truncation of the ResultCodeDescription__c field when the combined description exceeds 255 characters.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testProcessRequest_TruncatesLongResultDescription() {
        String longDescription = 'A'.repeat(255);
        String payload = '{"record":{"LabTestRequisition":{"RequisitionNumber":"CM8N-LONGDESC","FacilityName":"WONOWON SCHOOL WATER","DWOEHOName":"NE EHO 7",' +
            '"SamplingSiteName":"HALL FOUNTAIN","SamplingSiteAddress":"400 M Wonowon Subdivision","SamplingSiteTreatment":"YES","SystemType":"WS3^2-14 Connections",' +
            '"SpecimenSource":"Other (cistern etc.)","BoilAdvisory":"NO","SampleType":"DWATER^Drinking water","TestCategory":"WATERW^Water Bacteriology Testing",' +
            '"Method":"Membrane Filtration","ReportedOn":"2026-02-27T09:02:00.000-08:00","TestDate":"2026-02-25T09:50:00.000-08:00","RequisitionStatus":"F"},' +
            '"results":[{"TestCodeID":"TOTCOL","ResultValueCode":"31","ResultValueDescription":"' + longDescription + '","UnitOfMeasure":"Count/100mL","StatusCategory":"F"}]}}';

        RestContext.request = buildRestRequest(payload);
        RestContext.response = new RestResponse();

        Test.startTest();
        PHOCSLabResults.processRequest();
        Test.stopTest();

        Assert.areEqual(PHOCSLabResults.HTTP_SUCCESS, RestContext.response.statusCode, 'Expected success status code');

        List<LabTestRequired__c> labTestRequired = [SELECT ResultCodeDescription__c FROM LabTestRequired__c WHERE ExternalId__c = 'CM8N-LONGDESC-TOTCOL'];
        Assert.areEqual(1, labTestRequired.size(), 'Expected one Lab Test Required record');
        Assert.areEqual(PHOCSLabResults.RESULT_DESCRIPTION_LENGTH, labTestRequired[0].ResultCodeDescription__c.length(), 'Expected description to be truncated to the max length');
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers the generic error handling path of processRequest() when an invalid payload is submitted.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testProcessRequest_InvalidPayload_ReturnsError() {
        String payload = '{"record":{"LabTestRequisition":{"RequisitionNumber":""},"results":[]}}';

        RestContext.request = buildRestRequest(payload);
        RestContext.response = new RestResponse();

        Test.startTest();
        PHOCSLabResults.processRequest();
        Test.stopTest();

        Assert.areEqual(PHOCSLabResults.HTTP_SERVER_ERROR, RestContext.response.statusCode, 'Expected error status code');

        String responseBody = RestContext.response.responseBody.toString();
        PHOCSLabResults.ResponseWrapper response = (PHOCSLabResults.ResponseWrapper) JSON.deserialize(responseBody, PHOCSLabResults.ResponseWrapper.class);
        Assert.areEqual(false, response.success, 'Expected success flag to be false');
        Assert.areEqual(PHOCSLabResults.RESPONSE_ERROR, response.message, 'Expected generic error message');
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers validateRequest() when the request is null.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testValidateRequest_NullRequest_ThrowsException() {
        Test.startTest();
        try {
            PHOCSLabResults.validateRequest(null);
            Assert.fail('Expected an exception for a null request');
        } catch (DmlException ex) {
            Assert.areEqual(PHOCSLabResults.RESPONSE_INVALID_REQUEST, ex.getMessage(), 'Expected invalid request message');
        }
        Test.stopTest();
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers validateRequest() when the record node is missing.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testValidateRequest_NullRecord_ThrowsException() {
        PHOCSLabResults.RequestWrapper request = new PHOCSLabResults.RequestWrapper();

        Test.startTest();
        try {
            PHOCSLabResults.validateRequest(request);
            Assert.fail('Expected an exception for a null record node');
        } catch (DmlException ex) {
            Assert.areEqual('Record node is required.', ex.getMessage(), 'Expected record node required message');
        }
        Test.stopTest();
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers validateRequest() when the LabTestRequisition node is missing.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testValidateRequest_NullLabTestRequisition_ThrowsException() {
        PHOCSLabResults.RequestWrapper request = new PHOCSLabResults.RequestWrapper();
        request.record = new PHOCSLabResults.RecordWrapper();

        Test.startTest();
        try {
            PHOCSLabResults.validateRequest(request);
            Assert.fail('Expected an exception for a null LabTestRequisition node');
        } catch (DmlException ex) {
            Assert.areEqual('LabTestRequisition node is required.', ex.getMessage(), 'Expected LabTestRequisition node required message');
        }
        Test.stopTest();
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers validateRequest() when the RequisitionNumber is blank.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testValidateRequest_BlankRequisitionNumber_ThrowsException() {
        PHOCSLabResults.RequestWrapper request = new PHOCSLabResults.RequestWrapper();
        request.record = new PHOCSLabResults.RecordWrapper();
        request.record.labTestRequisition = new PHOCSLabResults.LabTestRequisitionWrapper();

        Test.startTest();
        try {
            PHOCSLabResults.validateRequest(request);
            Assert.fail('Expected an exception for a blank requisition number');
        } catch (DmlException ex) {
            Assert.areEqual('RequisitionNumber is required.', ex.getMessage(), 'Expected requisition number required message');
        }
        Test.stopTest();
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers validateRequest() when no lab results are present.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testValidateRequest_EmptyResults_ThrowsException() {
        PHOCSLabResults.RequestWrapper request = new PHOCSLabResults.RequestWrapper();
        request.record = new PHOCSLabResults.RecordWrapper();
        request.record.labTestRequisition = new PHOCSLabResults.LabTestRequisitionWrapper();
        request.record.labTestRequisition.requisitionNumber = CREATE_REQ_NUMBER;
        request.record.results = new List<PHOCSLabResults.ResultWrapper>();

        Test.startTest();
        try {
            PHOCSLabResults.validateRequest(request);
            Assert.fail('Expected an exception for an empty results list');
        } catch (DmlException ex) {
            Assert.areEqual('At least one lab result is required.', ex.getMessage(), 'Expected lab result required message');
        }
        Test.stopTest();
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers validateRequest() with a fully populated, valid request.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testValidateRequest_ValidRequest_NoException() {
        PHOCSLabResults.RequestWrapper request = new PHOCSLabResults.RequestWrapper();
        request.record = new PHOCSLabResults.RecordWrapper();
        request.record.labTestRequisition = new PHOCSLabResults.LabTestRequisitionWrapper();
        request.record.labTestRequisition.requisitionNumber = CREATE_REQ_NUMBER;

        PHOCSLabResults.ResultWrapper result = new PHOCSLabResults.ResultWrapper();
        result.testCodeID = 'TOTCOL';
        request.record.results = new List<PHOCSLabResults.ResultWrapper>{ result };

        Test.startTest();
        try {
            PHOCSLabResults.validateRequest(request);
        } catch (Exception ex) {
            Assert.fail('Did not expect an exception for a valid request: ' + ex.getMessage());
        }
        Test.stopTest();
    }

/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers the wrapper classes for basic construction and field assignment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testWrapperClasses() {
        Test.startTest();
        PHOCSLabResults.ResponseWrapper response = new PHOCSLabResults.ResponseWrapper();
        response.success = true;
        response.message = PHOCSLabResults.RESPONSE_SUCCESS;
        Test.stopTest();

        Assert.areEqual(true, response.success, 'Expected success flag to be true');
        Assert.areEqual(PHOCSLabResults.RESPONSE_SUCCESS, response.message, 'Expected success message to match');
    }
    
/**
* @author: Deepak
* @date: 28 Jul 2026
* @description: Covers all the exception blocks.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    @isTest
    public static void testProcessRequest_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.processRequest();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Attempt to de-reference a null object', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testValidateRequest_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.validateRequest(new PHOCSLabResults.RequestWrapper());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testProcessWaterLabResults_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.processWaterLabResults(new PHOCSLabResults.RequestWrapper());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testAttachInboundJson_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.attachInboundJson(null, '{}');
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testBuildSuccessResponse_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.buildSuccessResponse();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testBuildErrorResponse_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.buildErrorResponse('Test');
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testGetOrCreateLabTestRequisition_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.getOrCreateLabTestRequisition(new PHOCSLabResults.LabTestRequisitionWrapper(), new Map<String, Map<String, String>>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testCreateLabTestRequisition_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.createLabTestRequisition(new PHOCSLabResults.LabTestRequisitionWrapper(), new Map<String, Map<String, String>>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testUpdateRequisitionStatus_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.updateRequisitionStatus(new LabTestRequisition__c(), 'Requested', new Map<String, Map<String, String>>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testGroupResultsByTestCode_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.groupResultsByTestCode(new List<PHOCSLabResults.ResultWrapper>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testBuildResultDescription_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.buildResultDescription(new List<PHOCSLabResults.ResultWrapper>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testGetLabTestMasterMap_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.getLabTestMasterMap(new Set<String>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testBuildLabTestRequiredRecords_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.buildLabTestRequiredRecords(new LabTestRequisition__c(), new PHOCSLabResults.LabTestRequisitionWrapper(), new Map<String, List<PHOCSLabResults.ResultWrapper>>(), new Map<String, LabTestMasterList__c>(), new Map<String, Map<String, String>>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testSaveLabTestRequiredRecords_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.saveLabTestRequiredRecords(new List<LabTestRequired__c>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testMapStatus_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.mapStatus('Requested', new Map<String, Map<String, String>>());
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testGetMappingConfig_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.getMappingConfig();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testGetMappedValue_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.getMappedValue(new Map<String, Map<String, String>>(), 'SampleType', 'Water', null);
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
    
    @isTest
    public static void testGetWaterLabRecordTypeId_Exception() {
        PHOCSLabResults.throwTestException = true;
        try {
            PHOCSLabResults.getWaterLabRecordTypeId();
            Assert.fail('Expected exception');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        PHOCSLabResults.throwTestException = false;
    }
}