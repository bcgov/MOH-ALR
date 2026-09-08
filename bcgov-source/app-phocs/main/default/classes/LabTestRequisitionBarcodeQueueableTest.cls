/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 Aug 2026
* @Description: The purpose of this class is to cover Code coverage of LabTestRequisitionBarcodeQueueable.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@isTest
public class LabTestRequisitionBarcodeQueueableTest {
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to cover successful execution of LabTestRequisitionBarcodeQueueable
*              and validate barcode Attachment generation.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void generateBarcodeQueueableTest(){
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = rtPHOCSFacilityRecordType);
        insert facility;
        
        LabTestRequisition__c reqObj = new LabTestRequisition__c(FacilityName__c = facility.Id, LabTestRequisitionNumber__c = 'PHOCS-TEST-000001');
        insert reqObj;
        
        Test.startTest();
        System.enqueueJob(new LabTestRequisitionBarcodeQueueable(new Set<Id>{reqObj.Id}));
        Test.stopTest();
        
        List<Attachment> barcodeAttachments = [SELECT Id, ParentId, Name, ContentType, Body FROM Attachment WHERE ParentId = :reqObj.Id AND Name = 'Barcode-PHOCS-TEST-000001.png'];
        
        Assert.areEqual(1, barcodeAttachments.size(), 'One barcode attachment should be created');
        Assert.areEqual(reqObj.Id, barcodeAttachments[0].ParentId, 'The barcode attachment should be linked to the requisition');
        Assert.areEqual('Barcode-PHOCS-TEST-000001.png', barcodeAttachments[0].Name, 'The barcode attachment name should match the requisition number');
        Assert.areEqual('image/png', barcodeAttachments[0].ContentType, 'The barcode attachment should have image/png content type');
        Assert.areNotEqual(null, barcodeAttachments[0].Body, 'The barcode attachment body should not be null');
        
        String pngHex = EncodingUtil.convertToHex(barcodeAttachments[0].Body).toUpperCase();
        
        Assert.isTrue(pngHex.startsWith('89504E470D0A1A0A'), 'The barcode attachment should contain a valid PNG signature');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that LabTestRequisitionBarcodeQueueable safely handles
*              an empty Lab Test Requisition record Id set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void emptyRequisitionIdsQueueableTest(){
        Test.startTest();
        System.enqueueJob(new LabTestRequisitionBarcodeQueueable(new Set<Id>()));
        Test.stopTest();
        
        Assert.isTrue(true, 'The Queueable should safely handle an empty record Id set');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that LabTestRequisitionBarcodeQueueable safely handles
*              a null Lab Test Requisition record Id set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void nullRequisitionIdsQueueableTest(){
        Test.startTest();
        System.enqueueJob(new LabTestRequisitionBarcodeQueueable(null));
        Test.stopTest();
        
        Assert.isTrue(true, 'The Queueable should safely handle a null record Id set');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that barcode generation does not occur when
*              LabTestRequisitionNumber__c is blank.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void requisitionWithoutNumberQueueableTest(){
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = rtPHOCSFacilityRecordType);
        insert facility;
        
        LabTestRequisition__c reqObj = new LabTestRequisition__c(FacilityName__c = facility.Id);
        insert reqObj;
        
        reqObj.LabTestRequisitionNumber__c = null;
        update reqObj;
        
        Test.startTest();
        System.enqueueJob(new LabTestRequisitionBarcodeQueueable(new Set<Id>{reqObj.Id}));
        Test.stopTest();
        
        List<Attachment> barcodeAttachments = [SELECT Id FROM Attachment WHERE ParentId = :reqObj.Id AND Name LIKE 'Barcode-%.png'];
        
        Assert.areEqual(0, barcodeAttachments.size(), 'No barcode attachment should be created when the requisition number is blank');
    }
}