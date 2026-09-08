/**********************************************************************************************
* @Author:      Accenture
* @Date:        27 Aug 2026
* @Description: The purpose of this class is to cover Code coverage of LabTestRequisitionBarcodeService
*               and validate barcode PNG Attachment generation for Lab Test Requisitions.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@isTest
private class LabTestRequisitionBarcodeServiceTest {
    
    private static final String BARCODE_FILE_PREFIX = 'Barcode-';
    private static final String BARCODE_FILE_EXTENSION = '.png';
    private static final String BARCODE_CONTENT_TYPE = 'image/png';
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to verify that a barcode Attachment is generated
*              successfully for a Lab Test Requisition with a valid requisition number.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    static void testGenerateBarcodesSingleRecord() {
        LabTestRequisition__c requisition = createRequisition('PHOCS-TEST-000001');
        
        Test.startTest();
        LabTestRequisitionBarcodeService.generateBarcodes(new List<LabTestRequisition__c>{requisition});
        Test.stopTest();
        
        List<Attachment> attachments = [SELECT Id, ParentId, Name, ContentType, Body FROM Attachment WHERE ParentId = :requisition.Id];
        
        Assert.areEqual(1, attachments.size(), 'One barcode attachment should be created.');
        
        Attachment barcodeAttachment = attachments[0];
        
        Assert.areEqual(requisition.Id, barcodeAttachment.ParentId, 'The barcode attachment should be linked to the requisition.');
        Assert.areEqual(BARCODE_FILE_PREFIX + requisition.LabTestRequisitionNumber__c + BARCODE_FILE_EXTENSION, barcodeAttachment.Name, 'The barcode attachment name should match the expected format.');
        Assert.areEqual(BARCODE_CONTENT_TYPE, barcodeAttachment.ContentType, 'The barcode attachment should have image/png as the content type.');
        Assert.areNotEqual(null, barcodeAttachment.Body, 'The barcode attachment body should not be null.');
        
        String pngHex = EncodingUtil.convertToHex(barcodeAttachment.Body).toUpperCase();
        
        Assert.isTrue(pngHex.startsWith('89504E470D0A1A0A'), 'The generated attachment should contain a valid PNG signature.');
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to verify that records without a Lab Test
*              Requisition Number are skipped and do not receive a barcode Attachment.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    static void testGenerateBarcodesBlankRequisitionNumber() {
        LabTestRequisition__c requisition = new LabTestRequisition__c();
        insert requisition;
        
        Test.startTest();
        LabTestRequisitionBarcodeService.generateBarcodes(new List<LabTestRequisition__c>{requisition});
        Test.stopTest();
        
        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :requisition.Id];
        
        Assert.areEqual(0, attachments.size(), 'No barcode attachment should be created when the requisition number is blank.');
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to verify that an existing barcode Attachment
*              with the expected file name is not duplicated.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    static void testGenerateBarcodesExistingBarcodeSkipped() {
        LabTestRequisition__c requisition = createRequisition('PHOCS-TEST-000002');
        
        Attachment existingAttachment = new Attachment(ParentId = requisition.Id, Name = BARCODE_FILE_PREFIX + requisition.LabTestRequisitionNumber__c + BARCODE_FILE_EXTENSION, ContentType = BARCODE_CONTENT_TYPE, Body = Blob.valueOf('Existing Barcode'));
        insert existingAttachment;
        
        Test.startTest();
        LabTestRequisitionBarcodeService.generateBarcodes(new List<LabTestRequisition__c>{requisition});
        Test.stopTest();
        
        List<Attachment> attachments = [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId = :requisition.Id AND Name = :existingAttachment.Name];
        
        Assert.areEqual(1, attachments.size(), 'An existing matching barcode attachment should not be duplicated.');
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to verify bulk barcode processing for multiple
*              Lab Test Requisitions while ensuring existing barcode Attachments are skipped.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    static void testGenerateBarcodesBulkRecords() {
        List<LabTestRequisition__c> requisitions = new List<LabTestRequisition__c>();
        
        for (Integer index = 1; index <= 10; index++) {
            requisitions.add(new LabTestRequisition__c(LabTestRequisitionNumber__c = 'PHOCS-BULK-' + String.valueOf(index).leftPad(6, '0')));
        }
        
        insert requisitions;
        
        List<Attachment> existingAttachments = new List<Attachment>();
        
        for (Integer index = 0; index < requisitions.size() - 1; index++) {
            LabTestRequisition__c requisition = requisitions[index];
            existingAttachments.add(new Attachment(ParentId = requisition.Id, Name = BARCODE_FILE_PREFIX + requisition.LabTestRequisitionNumber__c + BARCODE_FILE_EXTENSION, ContentType = BARCODE_CONTENT_TYPE, Body = Blob.valueOf('Existing Barcode')));
        }
        
        insert existingAttachments;
        
        Test.startTest();
        LabTestRequisitionBarcodeService.generateBarcodes(requisitions);
        Test.stopTest();
        
        List<Attachment> attachments = [SELECT Id, ParentId, Name, ContentType, Body FROM Attachment WHERE ParentId IN :requisitions];
        
        Assert.areEqual(10, attachments.size(), 'Each requisition should have one barcode attachment.');
        
        Map<Id, Attachment> attachmentByParentId = new Map<Id, Attachment>();
        
        for (Attachment attachment : attachments) {
            attachmentByParentId.put(attachment.ParentId, attachment);
        }
        
        for (LabTestRequisition__c requisition : requisitions) {
            Assert.isTrue(attachmentByParentId.containsKey(requisition.Id), 'Each requisition should have a barcode attachment.');
            
            Attachment barcodeAttachment = attachmentByParentId.get(requisition.Id);
            
            Assert.areEqual(BARCODE_FILE_PREFIX + requisition.LabTestRequisitionNumber__c + BARCODE_FILE_EXTENSION, barcodeAttachment.Name, 'The barcode attachment name should match the requisition number.');
            Assert.areEqual(BARCODE_CONTENT_TYPE, barcodeAttachment.ContentType, 'Each barcode attachment should have image/png as the content type.');
        }
        
        LabTestRequisition__c generatedRequisition = requisitions[requisitions.size() - 1];
        Attachment generatedAttachment = attachmentByParentId.get(generatedRequisition.Id);
        
        Assert.areNotEqual(null, generatedAttachment.Body, 'The newly generated barcode attachment should contain a body.');
        
        String pngHex = EncodingUtil.convertToHex(generatedAttachment.Body).toUpperCase();
        
        Assert.isTrue(pngHex.startsWith('89504E470D0A1A0A'), 'The newly generated attachment should contain a valid PNG signature.');
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to verify that null input is safely handled
*              without generating an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    static void testGenerateBarcodesNullInput() {
        Test.startTest();
        LabTestRequisitionBarcodeService.generateBarcodes(null);
        Test.stopTest();
        
        Assert.isTrue(true, 'Null input should be handled without an exception.');
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to verify that an empty requisition list is
*              safely handled without generating an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    static void testGenerateBarcodesEmptyInput() {
        Test.startTest();
        LabTestRequisitionBarcodeService.generateBarcodes(new List<LabTestRequisition__c>());
        Test.stopTest();
        
        Assert.isTrue(true, 'An empty input list should be handled without an exception.');
    }
    
/**
* @author: Deepak
* @date: 27 Aug 2026
* @description: The purpose of this method is to create a Lab Test Requisition with the
*              specified Lab Test Requisition Number for barcode generation testing.
* @param requisitionNumber Lab Test Requisition Number.
* @return Inserted Lab Test Requisition.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    private static LabTestRequisition__c createRequisition(String requisitionNumber) {
        LabTestRequisition__c requisition = new LabTestRequisition__c(LabTestRequisitionNumber__c = requisitionNumber);
        insert requisition;
        return requisition;
    }
}