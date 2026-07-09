/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to create methods which can be used by different trigger events.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
***********************************************************************************************/
public with sharing class LabTestRequisitionTriggerHandler {
    private static final String CLASS_NAME = 'LabTestRequisitionTriggerHandler';
    
    @TestVisible
    private static Boolean throwExceptionForTest = false;

/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to Update the Lab Requisition Number.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    public static void populateLabTestRequisitionNumber(List<LabTestRequisition__c> newRecords){        
        try{
            if (Test.isRunningTest() && throwExceptionForTest) {
                throw new IllegalArgumentException('Test Exception');
            }
            
            List<LabTestRequisition__c> requisitionsToupdate = new List<LabTestRequisition__c>();
            for (LabTestRequisition__c req : [SELECT Id, Name, FacilityName__r.AccountNumberRTPrefixed__c, LabTestRequisitionNumber__c FROM LabTestRequisition__c WHERE Id IN :newRecords]) {
                
                if (String.isBlank(req.LabTestRequisitionNumber__c) && !String.isBlank(req.FacilityName__r.AccountNumberRTPrefixed__c)) {
                    requisitionsToupdate.add(new LabTestRequisition__c(Id = req.Id, LabTestRequisitionNumber__c = generateRequisitionNumber(req)));
                }
            }
            
            if (!requisitionsToupdate.isEmpty()) {
                update requisitionsToupdate;
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
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/  
    private static String generateRequisitionNumber(LabTestRequisition__c req) {
        String requiredSequenceNumber = 'PHOCS-' + req.FacilityName__r.AccountNumberRTPrefixed__c + '-' + req.Name.replace('LTR-', '');
        return requiredSequenceNumber;
    }
}