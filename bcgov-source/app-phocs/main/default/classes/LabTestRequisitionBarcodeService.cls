/**********************************************************************************************
* @Author:      Accenture
* @Date:        27 Aug 2026
* @Description: The purpose of this class is to generate Code 128 barcode PNG images for
*               Lab Test Requisitions and store them as Salesforce Attachments.
*
*               The barcode generation is performed entirely server-side using PngRenderer.
*               Existing barcode attachments are identified by their expected file name to
*               ensure idempotent processing.
*
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public without sharing class LabTestRequisitionBarcodeService {
    
    private static final String CLASS_NAME = 'LabTestRequisitionBarcodeService';
    private static final String BARCODE_FILE_PREFIX = 'Barcode-';
    private static final String BARCODE_FILE_EXTENSION = '.png';
    private static final String BARCODE_CONTENT_TYPE = 'image/png';
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: Generates barcode PNG attachments for the provided Lab Test Requisitions.
*              Records without a requisition number are skipped. Records that already contain
*              the expected barcode attachment are also skipped.
* @param requisitions List of Lab Test Requisitions to process.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static void generateBarcodes(List<LabTestRequisition__c> requisitions) {
        try {
            if (requisitions == null || requisitions.isEmpty()) {
                return;
            }
            
            Map<Id, String> requisitionNumberById = new Map<Id, String>();
            
            for (LabTestRequisition__c requisition : requisitions) {
                if (requisition == null || requisition.Id == null || String.isBlank(requisition.LabTestRequisitionNumber__c)) {
                    continue;
                }
                
                requisitionNumberById.put(requisition.Id, requisition.LabTestRequisitionNumber__c.trim());
            }
            
            if (requisitionNumberById.isEmpty()) {
                return;
            }
            
            Map<Id, Set<String>> attachmentNamesByParentId = new Map<Id, Set<String>>();
            
            for (Attachment attachment : [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId IN :requisitionNumberById.keySet()]) {
                if (!attachmentNamesByParentId.containsKey(attachment.ParentId)) {
                    attachmentNamesByParentId.put(attachment.ParentId, new Set<String>());
                }
                
                attachmentNamesByParentId.get(attachment.ParentId).add(attachment.Name);
            }
            
            List<Attachment> attachmentsToInsert = new List<Attachment>();
            
            for (Id requisitionId : requisitionNumberById.keySet()) {
                String requisitionNumber = requisitionNumberById.get(requisitionId);
                String expectedFileName = getBarcodeFileName(requisitionNumber);
                
                if (attachmentNamesByParentId.containsKey(requisitionId) && attachmentNamesByParentId.get(requisitionId).contains(expectedFileName)) {
                    continue;
                }
                
                try {
                    Blob barcodeImage = PngRenderer.render(requisitionNumber);
                    
                    attachmentsToInsert.add(new Attachment(
                        ParentId = requisitionId,
                        Name = expectedFileName,
                        ContentType = BARCODE_CONTENT_TYPE,
                        Body = barcodeImage
                    ));
                } catch (Exception ex) {
                    System.debug(LoggingLevel.ERROR, 'Unable to generate barcode for Lab Test Requisition ' + requisitionId + '. Error: ' + ex.getMessage());
                    LogService.logAndPublish(CLASS_NAME, 'generateBarcodes', requisitionId, ex);
                }
            }
            
            if (attachmentsToInsert.isEmpty()) {
                return;
            }
            
            Database.SaveResult[] saveResults = Database.insert(attachmentsToInsert, false);
            
            for (Integer index = 0; index < saveResults.size(); index++) {
                if (!saveResults[index].isSuccess()) {
                    for (Database.Error error : saveResults[index].getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Unable to save barcode attachment for Lab Test Requisition ' + attachmentsToInsert[index].ParentId + '. Error: ' + error.getMessage());
                    }
                }
            }
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'generateBarcodes', null, ex);
            throw ex;
        }
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: Returns the expected barcode attachment file name for a requisition number.
* @param requisitionNumber Lab Test Requisition Number.
* @return Expected barcode attachment file name.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String getBarcodeFileName(String requisitionNumber) {
        return BARCODE_FILE_PREFIX + requisitionNumber + BARCODE_FILE_EXTENSION;
    }
}