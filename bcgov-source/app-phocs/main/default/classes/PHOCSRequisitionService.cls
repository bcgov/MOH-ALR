/**********************************************************************************************
* @Author:      Accenture 
* @Date:        26 Jun 2026
* @Description: The purpose of this class is to REST service that retrieves eligible PHOCS Water Lab Test Requisitions for BizTalk integration, marks them as Submitted, and sends a notification email.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                26 Jun -  PHOCS-295         -  Accenture   -  BCCDC - Water lab requisition
***********************************************************************************************/
@RestResource(urlMapping='/PHOCSRequisitionService/*')
global with sharing class PHOCSRequisitionService {
    public static final String CLASS_NAME = 'PHOCSRequisitionService';
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String ERROR_UNEXPECTED = 'Unexpected error occurred.';
    public static final Integer HTTP_STATUS_ERROR = 500;
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: The purpose of this method is to Main REST handler. Orchestrates retrieval, response building, DML update, and email notification.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @HttpPut
    global static void handleRequest() {
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        
        try {
            List<LabTestRequisition__c> requisitions = getEligibleRequisitions();
            
            List<LabTestRequisition__c> successfulRequisitions = updateSubmittedRecords(requisitions);
            
            ResponseWrapper responsePayload = buildResponse(successfulRequisitions);            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(buildResponseJson(responsePayload));
            
            //sendNotificationEmail(successfulRequisitions.size());
            
        } catch (Exception ex) {
            handleException(res, ex);
        }
    }
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: The purpose of this method is to Queries eligible PHOCS Water Lab Test Requisitions and strips fields the running user cannot read (FLS compliance).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    public static List<LabTestRequisition__c> getEligibleRequisitions() {
        try{
            if (!Schema.sObjectType.LabTestRequisition__c.isAccessible()) {
                throw new System.NoAccessException();
            }
            
            PHOCSLabIntegrationQueryMapping__mdt queryConfig = [SELECT SObjectQuery__c FROM PHOCSLabIntegrationQueryMapping__mdt WHERE DeveloperName = 'WaterBCCDCLabRequistions'
                                                                AND AttributeType__c = 'SOQL' LIMIT 1];
            
            if (queryConfig == null || String.isBlank(queryConfig.SObjectQuery__c)) {
                throw new QueryException('No SOQL query found for DeveloperName: WaterBCCDCLabRequistions');
            }
            
            List<SObject> rawResults = Database.query(queryConfig.SObjectQuery__c);
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, rawResults);
            
            return (List<LabTestRequisition__c>)decision.getRecords();
        } catch(Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getEligibleRequisitions', null, ex);
            throw ex;
        }
    }    
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: Maps a list of requisition records into strongly typed wrapper objects.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    public static ResponseWrapper buildResponse(List<LabTestRequisition__c> requisitions) {        
        List<RequisitionWrapper> requisitionWrappers = new List<RequisitionWrapper>();
        try{
            for (LabTestRequisition__c req : requisitions) {
                RequisitionWrapper rw = new RequisitionWrapper();            
                rw.requisitionID = req.LabTestRequisitionNumber__c;
                rw.healthAuthority = req.HealthAuthority__c;            
                rw.facilityName = req.Drinking_Water_Component_Name__r != null ? req.Drinking_Water_Component_Name__r.Name : (req.FacilityName__r != null ? req.FacilityName__r.Name : null);
                rw.facilityType = req.SystemType__c;
                rw.siteSource = req.SpecimenSource__c;
                rw.eHO = req.DWOEHOName__c;
                rw.samplerName = req.SamplerName__c;
                rw.facilityBoilAdvisory = req.BoilAdvisory__c;
                rw.siteName = req.Site_Descriptor__c;
                rw.siteAddress = req.Drinking_Water_Component_Name__r != null && req.Drinking_Water_Component_Name__r.Address != null
                                 ? formatAddress(req.Drinking_Water_Component_Name__r.Address) : (req.FacilityName__r != null && req.FacilityName__r.Physical_Address__c != null
                                 ? formatAddress(req.FacilityName__r.Physical_Address__c) : req.Site_Descriptor__c);
                rw.siteTreated = req.Site_Treatment__c != null ? (req.Site_Treatment__c == 'Post-treatment' ? 'True' : 'False') : null;
                rw.siteID = req.Site_Number__c;
                requisitionWrappers.add(rw);
            }
            
            ResponseWrapper response = new ResponseWrapper();
            response.recordCount = requisitionWrappers.size();
            response.records = requisitionWrappers;
            return response;
            
        }catch(Exception ex){
            LogService.logAndPublish(CLASS_NAME, 'buildResponse', JSON.serialize(requisitions), ex);            
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: The purpose of this method is to Updates every returned requisition to Status = Submitted and sets SubmittedDateTime__c to today. Single DML statement.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static List<LabTestRequisition__c> updateSubmittedRecords(List<LabTestRequisition__c> requisitions) {
        try{
            if (requisitions.isEmpty()) {
                return new List<LabTestRequisition__c>();
            }
            
            if (!Schema.sObjectType.LabTestRequisition__c.isUpdateable()) {
                throw new System.NoAccessException();
            }
            
            List<LabTestRequisition__c> recordsToUpdate = new List<LabTestRequisition__c>();
            for (LabTestRequisition__c req : requisitions) {
                recordsToUpdate.add(new LabTestRequisition__c(Id = req.Id, Status__c = STATUS_SUBMITTED, SubmittedDateTime__c = System.now()));
            }
            
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, recordsToUpdate);
            
            recordsToUpdate = (List<LabTestRequisition__c>)decision.getRecords();
            
            Database.SaveResult[] results = Database.update(recordsToUpdate, false);
            
            Set<Id> successfulIds = new Set<Id>();            
            for(Integer i=0; i<results.size(); i++){                
                if(results[i].isSuccess()){                    
                    successfulIds.add(recordsToUpdate[i].Id);                    
                }
                else{
                    for(Database.Error err : results[i].getErrors()){                    
                        LogService.logAndPublish(CLASS_NAME, 'updateSubmittedRecords', JSON.serialize(recordsToUpdate[i]), new DmlException(err.getMessage()));                    
                    }                
                }                
            }
            List<LabTestRequisition__c> successfulRequisitions = new List<LabTestRequisition__c>();            
            for(LabTestRequisition__c req : requisitions){                
                if(successfulIds.contains(req.Id)){                    
                    successfulRequisitions.add(req);                    
                }
                
            }            
            return successfulRequisitions;
            
        }catch(Exception ex){
            LogService.logAndPublish(CLASS_NAME, 'updateSubmittedRecords', JSON.serialize(requisitions), ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: The purpose of this method is to Sends a notification email using a Salesforce Email Template. 
Recipients are read from the Custom Label LBL_PHOCS_BCCDC_Requisition_Email_To. 
Any exception is logged but does not fail the REST transaction.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void sendNotificationEmail(Integer recordCount) {
        try {
            List<String> toAddresses = new List<String>();
            String recipientLabel = System.Label.PHOCS_LBL_BCCDC_Requisition_Email_To;
            
            if (String.isBlank(recipientLabel)) {
                System.debug(LoggingLevel.WARN, 'Recipient email label is blank. Email notification skipped.');
                return;
            }        
            
            for (String address : recipientLabel.split(',')) {
                if (String.isNotBlank(address)) {
                    toAddresses.add(address.trim());
                }
            }
            
            if (toAddresses.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'No valid recipient email addresses configured.');
                return;
            }
            
            String subject = System.Label.PHOCS_LBL_BCCDC_Requisition_Email_Subject;
            String body = System.Label.PHOCS_LBL_BCCDC_Requisition_Email_Body;            
            String processingMessage = recordCount > 0 ? System.Label.PHOCS_LBL_BCCDC_Requisition_Email_Success_Message : System.Label.PHOCS_LBL_BCCDC_Requisition_Email_No_Records_Message;
            
            body = body.replace('{0}', String.valueOf(recordCount));
            body = body.replace('{1}', System.now().format());
            body = body.replace('{2}', getEnvironmentName());
            body = body.replace('{3}', processingMessage);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setToAddresses(toAddresses);
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSaveAsActivity(false);
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
            System.debug(LoggingLevel.INFO, 'Notification email sent successfully.');
            
        }catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'sendNotificationEmail', String.valueOf(recordCount), ex);
        }
    }
    
/**
* @author: Deepak
* @date: 17 Jul 2026
* @description: Returns the PHOCS environment name (e.g. PHOCS - Dev2 or PHOCS - Prod).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String getEnvironmentName() {
        try {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            if (baseUrl.contains('.sandbox.')) {
                String sandboxName = baseUrl.substringBetween('--', '.sandbox.');
                
                if (String.isNotBlank(sandboxName)) {
                     return 'PHOCS-' + sandboxName.toUpperCase();
                }
            }            
            return 'PHOCS-Prod';
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getEnvironmentName', null, ex);
            return 'PHOCS';
        }
    }
    
/**
* @author: Deepak
* @date: 16 Jun 2026
* @description: The purpose of this method is to Formats a Salesforce Address compound field into a single string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String formatAddress(Address address) {
        
        if (address == null) {
            return null;
        }
        
        List<String> addressParts = new List<String>();
        
        if (String.isNotBlank(address.getStreet())) {
            addressParts.add(address.getStreet());
        }
        
        if (String.isNotBlank(address.getCity())) {
            addressParts.add(address.getCity());
        }
        
        if (String.isNotBlank(address.getState())) {
            addressParts.add(address.getState());
        }
        
        if (String.isNotBlank(address.getPostalCode())) {
            addressParts.add(address.getPostalCode());
        }
        
        if (String.isNotBlank(address.getCountry())) {
            addressParts.add(address.getCountry());
        }
        
        return String.join(addressParts, ', ');
    }

/**
* @author: Deepak
* @date: 16 Jun 2026
* @description: The purpose of this method is to generate JSON in required format.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    private static String buildResponseJson(ResponseWrapper response){
        JSONGenerator gen = JSON.createGenerator(true);
        
        gen.writeStartObject();        
        gen.writeFieldName('records');
        gen.writeStartArray();
        if (response.records != null) {
            for (RequisitionWrapper rw : response.records) {
                gen.writeStartObject();                
                writeStringField(gen, 'requisitionID', rw.requisitionID);
                writeStringField(gen, 'healthAuthority', rw.healthAuthority);
                writeStringField(gen, 'facilityName', rw.facilityName);
                writeStringField(gen, 'facilityType', rw.facilityType);
                writeStringField(gen, 'siteName', rw.siteName);
                writeStringField(gen, 'siteAddress', rw.siteAddress);
                writeStringField(gen, 'siteTreated', rw.siteTreated);
                writeStringField(gen, 'siteSource', rw.siteSource);
                writeStringField(gen, 'eHO', rw.eHO);
                writeStringField(gen, 'samplerName', rw.samplerName);
                writeStringField(gen, 'facilityBoilAdvisory', rw.facilityBoilAdvisory);
                writeStringField(gen, 'siteID', rw.siteID);                
                gen.writeEndObject();
            }
        }
        
        gen.writeEndArray();
        
        gen.writeNumberField('recordCount', response.recordCount);        
        gen.writeEndObject();
        
        return gen.getAsString();
    }
    
    private static void writeStringField(JSONGenerator gen, String fieldName, String value) {
        gen.writeFieldName(fieldName);
        
        if (value == null) {
            gen.writeNull();
        } else {
            gen.writeString(value);
        }
    }
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: The purpose of this method is to Writes the error response and logs the exception. HTTP 500 is returned with a structured JSON error body.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 
    public static void handleException(RestResponse res, Exception ex) {
        LogService.logAndPublish(CLASS_NAME, 'handleException', null, ex);
        System.enqueueJob(
        new PHOCSLabIntExceptionEmailQueueable(CLASS_NAME, ex.getMessage(), ex.getTypeName()));
        res.statusCode = HTTP_STATUS_ERROR;
        ErrorWrapper error = new ErrorWrapper();
        error.success = false;
        error.message = ERROR_UNEXPECTED;
        res.responseBody = Blob.valueOf(JSON.serialize(error));
    }
    
/**
* @author: Deepak
* @date: 26 Jun 2026
* @description: Wrapper Classes
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/ 

/**
* @description Top-level response envelope.
*/
    public class ResponseWrapper {
        public Integer recordCount;
        public List<RequisitionWrapper> records;
    }
    
/**
* @description Serialisable representation of a single LabTestRequisition__c record.
*/
    public class RequisitionWrapper {
        public String requisitionID;        
        public String healthAuthority;
        public String facilityName;
        public String facilityType;
        public String siteName;        
        public String siteAddress;
        public String siteTreated;
        public String siteSource;
        public String eHO;
        public String samplerName;
        public String facilityBoilAdvisory;
        public String siteID;
    }
    
/**
* @description Error response envelope returned on HTTP 500.
*/
    public class ErrorWrapper {
        public Boolean success;
        public String  message;
    }
}