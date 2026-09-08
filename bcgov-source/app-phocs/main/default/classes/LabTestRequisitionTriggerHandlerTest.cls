/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to cover Code coverage of LabTestRequisitionTriggerHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
                28 Aug -  Barcode Generation - Accenture - Validate asynchronous barcode generation.
***********************************************************************************************/
@isTest
public class LabTestRequisitionTriggerHandlerTest {
    
    @testSetup
    private static void createTestData() {
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = rtPHOCSFacilityRecordType);
        insert facility;           
    }
    
/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to cover Testcoverage of populateLabTestRequisitionNumber
*              and asynchronous barcode generation for PHOCSWaterLabTestRequisition.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void createRegulatoryCodeViolationsTest(){
        Account facility = [SELECT Id, AccountNumberRTPrefixed__c FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        
        Id waterLabTestRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSWaterLabTestRequisition').getRecordTypeId();

        LabTestRequisition__c reqObj = new LabTestRequisition__c(FacilityName__c = facility.Id, RecordTypeId = waterLabTestRequisitionRecordTypeId);

        Test.startTest();
        insert reqObj;
        Test.stopTest();
        
        List<LabTestRequisition__c> reqRec = [SELECT Id, Name, LabTestRequisitionNumber__c, FacilityName__r.AccountNumberRTPrefixed__c
                                              FROM LabTestRequisition__c WHERE Id = :reqObj.Id LIMIT 1];
        
        String expected = 'PHOCS-' + reqRec[0].FacilityName__r.AccountNumberRTPrefixed__c + '-' + reqRec[0].Name.replace('LTR-', '');

        Assert.areEqual(expected, reqRec[0].LabTestRequisitionNumber__c, 'The Both Strings should be identical');
        Assert.areNotEqual(null, reqRec[0].LabTestRequisitionNumber__c, 'The requisition number cannot be blank');
        
        List<Attachment> barcodeAttachments = [SELECT Id, ParentId, Name, ContentType, Body FROM Attachment 
                                               WHERE ParentId = :reqRec[0].Id AND Name = :('Barcode-' + reqRec[0].LabTestRequisitionNumber__c + '.png')];
        
        Assert.areEqual(1, barcodeAttachments.size(), 'One barcode attachment should be created');
        Assert.areEqual(reqRec[0].Id, barcodeAttachments[0].ParentId, 'The barcode attachment should be linked to the requisition');
        Assert.areEqual('Barcode-' + reqRec[0].LabTestRequisitionNumber__c + '.png', barcodeAttachments[0].Name, 'The barcode attachment name should match the requisition number');
        Assert.areEqual('image/png', barcodeAttachments[0].ContentType, 'The barcode attachment should have image/png content type');
        Assert.areNotEqual(null, barcodeAttachments[0].Body, 'The barcode attachment body should not be null');
        
        String pngHex = EncodingUtil.convertToHex(barcodeAttachments[0].Body).toUpperCase();        
        Assert.isTrue(pngHex.startsWith('89504E470D0A1A0A'), 'The barcode attachment should contain a valid PNG signature');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that barcode generation is not triggered
*              for Lab Test Requisition record types other than PHOCSWaterLabTestRequisition.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void verifyBarcodeNotGeneratedForOtherRecordTypeTest(){
        Account facility = [SELECT Id, AccountNumberRTPrefixed__c FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        
        Map<String, Schema.RecordTypeInfo> recordTypeInfos = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName();        
        Id otherRecordTypeId;
        
        for (String developerName : recordTypeInfos.keySet()) {
            if (developerName != 'PHOCSWaterLabTestRequisition' && recordTypeInfos.get(developerName).isAvailable()) {
                otherRecordTypeId = recordTypeInfos.get(developerName).getRecordTypeId();
                break;
            }
        }
        
        Assert.areNotEqual(null, otherRecordTypeId, 'Another Lab Test Requisition Record Type should be available for this test');
        
        LabTestRequisition__c reqObj = new LabTestRequisition__c(FacilityName__c = facility.Id, RecordTypeId = otherRecordTypeId);

        Test.startTest();
        insert reqObj;
        Test.stopTest();
        
        LabTestRequisition__c reqRec = [SELECT Id, LabTestRequisition__c.RecordTypeId, Name, LabTestRequisitionNumber__c,
                                        FacilityName__r.AccountNumberRTPrefixed__c FROM LabTestRequisition__c
                                        WHERE Id = :reqObj.Id LIMIT 1];
        
        String expected = 'PHOCS-' + reqRec.FacilityName__r.AccountNumberRTPrefixed__c + '-' + reqRec.Name.replace('LTR-', '');        
        Assert.areEqual(expected, reqRec.LabTestRequisitionNumber__c, 'The requisition number should be generated');
        
        List<Attachment> barcodeAttachments = [SELECT Id FROM Attachment WHERE ParentId = :reqRec.Id AND Name LIKE 'Barcode-%.png'];        
        Assert.areEqual(0, barcodeAttachments.size(), 'No barcode attachment should be created for other record types');
    }
    
/**
* @author: Deepak
* @date: 02 Jul 2026
* @description: The purpose of this method is to cover Negative Testcoverage of populateLabTestRequisitionNumber.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/      
    @isTest
    public static void negativeCatchBlock() {
        LabTestRequisitionTriggerHandler.throwExceptionForTest = true;
        
        Test.startTest();
        try {
            LabTestRequisitionTriggerHandler.populateLabTestRequisitionNumber(new List<LabTestRequisition__c>());
            System.assert(false, 'Exception expected');
        } catch (Exception e) {
            Assert.areEqual('Test Exception', e.getMessage());
        }
        Test.stopTest();
    }
}