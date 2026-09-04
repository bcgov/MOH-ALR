/**********************************************************************************************
* @Author:      Accenture
* @Date:        28 Aug 2026
* @Description: The purpose of this class is to asynchronously generate barcode PNG Attachments
*               for Lab Test Requisitions.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public with sharing class LabTestRequisitionBarcodeQueueable implements Queueable {    
    private Set<Id> requisitionIds;
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: Constructor to initialize Lab Test Requisition record Ids for barcode generation.
* @param requisitionIds Set of Lab Test Requisition record Ids.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public LabTestRequisitionBarcodeQueueable(Set<Id> requisitionIds) {
        this.requisitionIds = requisitionIds;
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to query Lab Test Requisitions and invoke the
*              barcode generation service asynchronously.
* @param context Queueable execution context.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public void execute(QueueableContext context) {
        if (requisitionIds == null || requisitionIds.isEmpty()) {
            return;
        }
        
        List<LabTestRequisition__c> requisitions = [SELECT Id, LabTestRequisitionNumber__c FROM LabTestRequisition__c
                                                    WHERE Id IN :requisitionIds AND LabTestRequisitionNumber__c != null];
        
        if (!requisitions.isEmpty()) {
            LabTestRequisitionBarcodeService.generateBarcodes(requisitions);
        }
    }
}