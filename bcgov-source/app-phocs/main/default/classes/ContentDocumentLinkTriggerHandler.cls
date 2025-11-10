/**********************************************************************************************
* @Author:Accenture_PHOCS Dev Team   
* @Date:       
* @Description: Method to update DocumentChecklistItem after a file is uploaded EHIS-1657
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                  
***********************************************************************************************/

public with sharing class ContentDocumentLinkTriggerHandler {
    
    public static void afterInsertHandler(List<ContentDocumentLink> CDLs, Map<Id, ContentDocumentLink> oldMap) {

    }

    public static void beforeInsertHandler(List<ContentDocumentLink> CDLs) {
        updatePhocsDocumentsVisibility(CDLs);
    }

    public static void updatePhocsDocumentsVisibility(List<ContentDocumentLink> CDLs) {
        set<string> sobjectsToProcess = new set<string>{
            'BusinessLicense',
            'BusinessLicenseApplication',
            'RegulatoryTrxnFee',
            'DocumentChecklistItem'
        };
        Set<Id> recordTypeIdsToProcess = getRecordTypeIdsToSetAllUserVisibility();
        Map<Id, SObject> parentSobjectMap = getDocumentParentRecordDetails(CDLs, sobjectsToProcess);
       
        for (ContentDocumentLink cdl : CDLs){
            Id recTypeId;
            if( parentSobjectMap.containsKey(cdl.LinkedEntityId)){
                recTypeId = (Id) parentSobjectMap.get(cdl.LinkedEntityId).get('RecordTypeId');
            }
            if(cdl.LinkedEntityId != null && 
               recordTypeIdsToProcess.contains(recTypeId)){
                cdl.Visibility = 'AllUsers';
            }
        } 
    }

    private static set<Id> getRecordTypeIdsToSetAllUserVisibility() {
        return new Set<Id>{
            //BusinessLicense
            Schema.SObjectType.BusinessLicense.getRecordTypeInfosByDeveloperName().get('PHOCSPermitLicense').getRecordTypeId(),
            //BusinessLicenseApplication
            Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('ConstructionPermitApplication').getRecordTypeId(),
            Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('Evaluation').getRecordTypeId(),
            Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('PHOCSExemptions').getRecordTypeId(),
            Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('OperatingPermitApplication').getRecordTypeId(),
            //RegulatoryTrxnFee
            Schema.SObjectType.RegulatoryTrxnFee.getRecordTypeInfosByDeveloperName().get('PHOCSTransactionFee').getRecordTypeId(),
            //DocumentChecklistItem
            Schema.SObjectType.DocumentChecklistItem.getRecordTypeInfosByDeveloperName().get('PHOCSDocumentChecklist').getRecordTypeId(),
            Schema.SObjectType.DocumentChecklistItem.getRecordTypeInfosByDeveloperName().get('PHOCSDrawingPlanDocumentChecklist').getRecordTypeId(),     
            Schema.SObjectType.DocumentChecklistItem.getRecordTypeInfosByDeveloperName().get('PHOCSERCPDocumentChecklist').getRecordTypeId()               
        };
    }

    private static Map<Id,SObject> getDocumentParentRecordDetails(ContentDocumentLink[] CDLs, set<string> sobjectsToProcess) {
        Map<Id, SObject> parentSobjectMap = new Map<Id, SObject>();
        Map<string, set<Id>> sobjectNameRecordIds = new Map<string, set<Id>>();
        for (ContentDocumentLink cdl : CDLs) {
            if (cdl.LinkedEntityId != null) {
                string sObjectName = cdl.LinkedEntityId.getSObjectType().getDescribe().getName();
                if(sobjectsToProcess.contains(sObjectName)){
                    if(!sobjectNameRecordIds.containsKey(sObjectName)){
                        sobjectNameRecordIds.put(sObjectName, new set<Id>());
                    } 
                    sobjectNameRecordIds.get(sObjectName).add(cdl.LinkedEntityId);
                }
            }       
        }
        for(string sobjName : sobjectNameRecordIds.keySet()){
            set<Id> recordIds = sobjectNameRecordIds.get(sobjName);      
             //soql inside loop. max 4-5 times soql query called inside loop.
            SObject[] records = Database.query('Select Id, RecordTypeId from ' + sobjName + ' where Id in :recordIds'); // NOPMD 
            parentSobjectMap.putAll(records);
        }
        return parentSobjectMap;
    }
    
    public static void updateDocumentChecklistItemAfterUploadFile(List<ContentDocumentLink> CDLs) {
        
        String devNamePrefixPHOCS = 'PHOCS%';
        String statusReceived = 'Received';
        String dclIdPrefix = '0dd';
        
        try {
            Set<Id> LinkedEntityIds = new Set<Id>();
            
            for (ContentDocumentLink CDL : CDLs) {              
                String idPrefix = String.valueOf(CDL.LinkedEntityId).substring(0,3);               
                if (idPrefix == dclIdPrefix) {
                   LinkedEntityIds.add(CDL.LinkedEntityId);
                }
            }
            
            List<DocumentChecklistItem> relatedDCItems = [SELECT Id, Status 
                                                   			FROM DocumentChecklistItem
                                                   			WHERE Id IN :LinkedEntityIds
                                                         	AND RecordType.DeveloperName LIKE :devNamePrefixPHOCS];
            
            List<DocumentChecklistItem> dciToUpdate = new List<DocumentChecklistItem>();
            
            for (DocumentChecklistItem dci : relatedDCItems) {
                if (dci.Status != statusReceived) {
                    dciToUpdate.add(dci);
                }
            }
            
            if (!dciToUpdate.isEmpty()) {
                for (DocumentChecklistItem dci : dciToUpdate) {
                    dci.Status = statusReceived;
                }
                update dciToUpdate;
            }
           
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
    }
    
}