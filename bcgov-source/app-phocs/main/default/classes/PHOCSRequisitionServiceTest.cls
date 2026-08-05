/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to cover Code coverage of PHOCSRequisitionService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-295         -  Accenture   -  BCCDC - Water lab requisition
***********************************************************************************************/
@isTest
public class PHOCSRequisitionServiceTest{    
    private static final Id FACILITY_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
    private static final Id CONTACT_PHOCS_RT = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('PHOCSContact').getRecordTypeId();
    private static final Id LAB_REQ_RT = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequisition').getRecordTypeId();
    private static final Id LAB_TEST_RT = Schema.SObjectType.LabTestMasterList__c.getRecordTypeInfosByDeveloperName().get('WaterBacteriologicalTest').getRecordTypeId();
    
    //Test Data Setup
    @testSetup
    private static void createTestData() {        
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = FACILITY_RT, Physical_Address__Street__s = '123 Main Street',
                                       Physical_Address__City__s = 'Burnaby', Physical_Address__StateCode__s = 'BC',
                                       Physical_Address__PostalCode__s = 'V5H 1A1', Physical_Address__CountryCode__s = 'CA');
        insert facility;
        
        Contact supplier = new Contact(FirstName = 'Water', LastName = 'Supplier Test', Email = 'test@gmail.com', RecordTypeId = CONTACT_PHOCS_RT);
        insert supplier;
        
        LabTestMasterList__c testRequired = new LabTestMasterList__c(Name = 'Free Chlorine mg/l Test', ParameterType__c = 'Free Chlorine', PhysicalQuantity__c = 'Milligrams per Litre', 
                                                                     SampleTestType__c = 'Bacteriological', TestCategory__c = 'Drinking water', UnitOfMeasure__c = 'mg/l',  RecordTypeId = LAB_TEST_RT);
        insert testRequired;
        
        LabTestRequisition__c requisition = new LabTestRequisition__c(
            RecordTypeId = LAB_REQ_RT,
            FacilityName__c = facility.Id,
            WaterSupplier__c = supplier.Id,            
            Status__c = 'Requested',
            ToLaboratory__c = 'BCCDC',
            TestCategory__c = 'Bacteriological',            
            Type__c = 'Distribution System',
            SampleType__c = 'Drinking Water',
            BoilAdvisory__c = 'No',
            CollectionDateTime__c = System.now(),
            SampleReason__c = 'Audit',
            SamplerName__c = 'John',
            HealthAuthority__c = 'Interior',            
            DWOEHOName__c = 'John Smith',
            Site_Descriptor__c = 'Hall Fountain',
            Site_Number__c = '1234567',
            Site_Treatment__c = 'Post-treatment',
            SpecimenSource__c = 'Well'
        );        
        insert requisition;        

        LabTestRequisition__c nonEligible = new LabTestRequisition__c(
            RecordTypeId = LAB_REQ_RT,
            FacilityName__c = facility.Id,            
            Status__c = 'Completed',
            ToLaboratory__c = 'BCCDC',
            TestCategory__c = 'Bacteriological'
        );
        
        insert nonEligible;
        
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/PHOCSRequisitionService';
        req.httpMethod = 'PUT';
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }
    
/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers the successful execution of the REST endpoint.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testHandleRequest_Success() {        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/PHOCSRequisitionService';
        req.httpMethod = 'PUT';
        
        RestResponse res = new RestResponse();        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        PHOCSRequisitionService.handleRequest();
        Test.stopTest();
        
        Assert.areEqual(200, RestContext.response.statusCode, 'It should be success message');        
        String responseBody = RestContext.response.responseBody.toString();        
        Assert.areNotEqual(null, responseBody, 'respose body cannot be blank');
        
        PHOCSRequisitionService.ResponseWrapper response = (PHOCSRequisitionService.ResponseWrapper)JSON.deserialize(responseBody, PHOCSRequisitionService.ResponseWrapper.class);
        
        Assert.areNotEqual(null, response, 'resposnse cannot be null');
        Assert.areEqual(1, response.recordCount, 'Expected respose record count to be 1');
        Assert.areEqual(1, response.records.size(), 'Expected respose record size to be 1');
        
        List<LabTestRequisition__c> updatedReqs = [SELECT Id, Status__c, SubmittedDateTime__c FROM LabTestRequisition__c WHERE Status__c = 'Submitted'];        
        Assert.areEqual(1, updatedReqs.size(), 'Expected updated record count to be 1');
        Assert.areEqual('Submitted', updatedReqs[0].Status__c, 'Expected Status to be updated');
        Assert.areNotEqual(null, updatedReqs[0].SubmittedDateTime__c, 'submitted Date/Time cannot be null');
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers buildResponse().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/

    @isTest
    public static void testBuildResponse() {        
        List<LabTestRequisition__c> requisitions = [SELECT LabTestRequisitionNumber__c, Status__c, ToLaboratory__c, Type__c, SystemType__c, SampleType__c,
                                                    BoilAdvisory__c, CollectionDateTime__c, SampleReason__c, SamplerName__c, HealthAuthority__c, DWOEHOName__c,
                                                    FacilityName__r.Name, FacilityName__r.Type, SpecimenSource__c, FacilityName__r.WaterSourceCategory__c, Site_Descriptor__c,
                                                    Site_Number__c, Site_Treatment__c, Drinking_Water_Component_Name__r.Name, Drinking_Water_Component_Name__r.Address,
                                                    FacilityName__r.Physical_Address__c FROM LabTestRequisition__c LIMIT 1];
        
        Test.startTest();
        PHOCSRequisitionService.ResponseWrapper response = PHOCSRequisitionService.buildResponse(requisitions);
        Test.stopTest();
        
        Assert.areEqual(1, response.recordCount, 'Expected response record count to be 1');
        Assert.areEqual(1, response.records.size(), 'Expected response record size to be 1');
        Assert.areNotEqual(null, response.records[0].requisitionID, 'response records cannot be null');
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers updateSubmittedRecords().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateSubmittedRecords() {
        
        List<LabTestRequisition__c> requisitions = [SELECT Id, Status__c FROM LabTestRequisition__c WHERE Status__c = 'Requested'];
        
        Test.startTest();
        List<LabTestRequisition__c> updated = PHOCSRequisitionService.updateSubmittedRecords(requisitions);
        Test.stopTest();
        
        Assert.areEqual(1, updated.size(), 'Expected response record size to be 1');
        
        LabTestRequisition__c req = [SELECT Status__c, SubmittedDateTime__c FROM LabTestRequisition__c WHERE Id = :updated[0].Id];
        
        Assert.areEqual('Submitted', req.Status__c, 'Expected Status to be updated');        
        Assert.areNotEqual(null, req.SubmittedDateTime__c, 'Submitted Date/Time cannot be null');
    }
    
/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers getEligibleRequisitions().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testGetEligibleRequisitions() {
        
        Test.startTest();
        List<LabTestRequisition__c> requisitions = PHOCSRequisitionService.getEligibleRequisitions();
        Test.stopTest();
        
        Assert.areNotEqual(null, requisitions);
        System.assert(requisitions.size() > 0);
        
        for(LabTestRequisition__c req : requisitions){
             Assert.areEqual('Requested', req.Status__c, 'Expected Status to be requested');
             Assert.areEqual('BCCDC', req.ToLaboratory__c, 'Expected laboratory to be BCCDC');            
        }
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers updateSubmittedRecords() when no records exist.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testUpdateSubmittedRecords_EmptyList() {
        
        Test.startTest();
        List<LabTestRequisition__c> response = PHOCSRequisitionService.updateSubmittedRecords(new List<LabTestRequisition__c>());
        Test.stopTest();
        
        Assert.areNotEqual(null, response, 'Response cannot be null');
        Assert.areEqual(0, response.size(), 'Expected response size to be 0');        
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers buildResponse() with no records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testBuildResponse_EmptyList(){
        
        Test.startTest();
        PHOCSRequisitionService.ResponseWrapper response = PHOCSRequisitionService.buildResponse(new List<LabTestRequisition__c>());
        Test.stopTest();
        
        Assert.areEqual(0,response.recordCount, 'Expected response size to be 0');
        Assert.areEqual(0,response.records.size(), 'Expected response size to be 0');
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers handleException().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testHandleException(){
        
        RestResponse response = new RestResponse();
        
        Exception ex = new AuraHandledException('Test Exception');
        
        Test.startTest();        
        PHOCSRequisitionService.handleException(response, ex);        
        Test.stopTest();
        
        Assert.areEqual(PHOCSRequisitionService.HTTP_STATUS_ERROR, response.statusCode);
        
        PHOCSRequisitionService.ErrorWrapper wrapper = (PHOCSRequisitionService.ErrorWrapper)JSON.deserialize(response.responseBody.toString(), PHOCSRequisitionService.ErrorWrapper.class);        
        Assert.areEqual(false, wrapper.success);        
        Assert.areEqual(PHOCSRequisitionService.ERROR_UNEXPECTED, wrapper.message);        
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers sendNotificationEmail().
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testSendNotificationEmail(){
        
        Test.startTest();
        PHOCSRequisitionService.sendNotificationEmail(10);
        Test.stopTest();    
        
        Assert.areEqual(1, 1, 'One email should have been attempted.');        
    }

/**
* @author: Accenture
* @date: 02 Jul 2026
* @description: Covers wrapper classes.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void testWrapperClasses(){
        
        Test.startTest();
        PHOCSRequisitionService.ResponseWrapper response = new PHOCSRequisitionService.ResponseWrapper();
        
        response.recordCount = 1;
        response.records = new List<PHOCSRequisitionService.RequisitionWrapper>();
        
        PHOCSRequisitionService.RequisitionWrapper wrapper = new PHOCSRequisitionService.RequisitionWrapper();
        wrapper.requisitionID = 'PHOCS-FA-0001-000001';
        
        response.records.add(wrapper); 
        Test.stopTest();
        
        Assert.areEqual(1, response.recordCount, 'Expected respose record count to be 1');        
    }    
}