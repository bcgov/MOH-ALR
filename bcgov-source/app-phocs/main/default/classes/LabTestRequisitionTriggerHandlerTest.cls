/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Jul 2026
* @Description: The purpose of this class is to cover Code coverage of LabTestRequisitionTriggerHandler.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                02 Jul -  PHOCS-4682        -  Accenture   -  Update the Lab Requisition Number.
                28 Aug -  Barcode Generation - Accenture   - Validate asynchronous barcode generation.
                15 Sep -  EHIS-5712         -  Deepak      -  added coverage for updateDairyRequisitionFlag on insert and update
***********************************************************************************************/
@isTest
public class LabTestRequisitionTriggerHandlerTest {
    
    @testSetup
    private static void createTestData() {
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = rtPHOCSFacilityRecordType);
        insert facility;

        Id rtPHOCSDairyFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();
        Account dairyFacility = new Account(Name = 'Test Dairy Facility', RecordTypeId = rtPHOCSDairyFacilityRecordType);
        insert dairyFacility;
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

    @isTest
    public static void assignsWaterRequisitionToNonCcflHealthAuthorityQueue() {
        Id facilityRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Facility').getRecordTypeId();
        Account facility = new Account(
            Name = 'Fraser Portal Facility',
            RecordTypeId = facilityRecordTypeId,
            Type = 'Food',
            HealthAuthority__c = 'Fraser Health - FH'
        );
        insert facility;

        Id waterRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName()
            .get('PHOCSWaterLabTestRequisition').getRecordTypeId();
        Id queueId = [
            SELECT Id FROM Group
            WHERE Type = 'Queue' AND DeveloperName = 'Fraser_Admin_Intake_Queue'
            LIMIT 1
        ].Id;

        LabTestRequisition__c requisition = new LabTestRequisition__c(
            FacilityName__c = facility.Id,
            RecordTypeId = waterRecordTypeId
        );
        insert requisition;

        requisition = [
            SELECT OwnerId, HealthAuthority__c
            FROM LabTestRequisition__c
            WHERE Id = :requisition.Id
        ];
        Assert.areEqual(queueId, requisition.OwnerId);
        Assert.areEqual('Fraser Health - FH', requisition.HealthAuthority__c);
    }

/**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of updateDairyRequisitionFlag
*              on insert, verifying IsDairy__c is set true when FacilityName__c points to a
*              PHOCSDairyFacility Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void updateDairyRequisitionFlag_SetsTrue_WhenFacilityIsDairy_Test() {
        Account dairyFacility = [SELECT Id FROM Account WHERE Name = 'Test Dairy Facility' LIMIT 1];
        Id dairyRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSDairyProductTestRequisition').getRecordTypeId();

        LabTestRequisition__c requisition = new LabTestRequisition__c(FacilityName__c = dairyFacility.Id, RecordTypeId = dairyRequisitionRecordTypeId);

        Test.startTest();
        insert requisition;
        Test.stopTest();

        LabTestRequisition__c requisitionRec = [SELECT Id, IsDairy__c FROM LabTestRequisition__c WHERE Id = :requisition.Id LIMIT 1];
        Assert.areEqual(true, requisitionRec.IsDairy__c, 'IsDairy__c should be true when FacilityName__c is a PHOCSDairyFacility Account.');
    }

/**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of updateDairyRequisitionFlag
*              on insert, verifying IsDairy__c is set false when FacilityName__c points to a
*              non-dairy Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void updateDairyRequisitionFlag_SetsFalse_WhenFacilityIsNotDairy_Test() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Id dairyRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSDairyProductTestRequisition').getRecordTypeId();

        LabTestRequisition__c requisition = new LabTestRequisition__c(FacilityName__c = facility.Id, RecordTypeId = dairyRequisitionRecordTypeId);

        Test.startTest();
        insert requisition;
        Test.stopTest();

        LabTestRequisition__c requisitionRec = [SELECT Id, IsDairy__c FROM LabTestRequisition__c WHERE Id = :requisition.Id LIMIT 1];
        Assert.areEqual(false, requisitionRec.IsDairy__c, 'IsDairy__c should be false when FacilityName__c is not a PHOCSDairyFacility Account.');
    }

/**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of updateDairyRequisitionFlag
*              on update, verifying IsDairy__c flips to true when FacilityName__c changes from a
*              non-dairy Account to a PHOCSDairyFacility Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void updateDairyRequisitionFlag_UpdatesToTrue_WhenFacilityChangedToDairy_Test() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Account dairyFacility = [SELECT Id FROM Account WHERE Name = 'Test Dairy Facility' LIMIT 1];
        Id dairyRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSDairyProductTestRequisition').getRecordTypeId();

        LabTestRequisition__c requisition = new LabTestRequisition__c(FacilityName__c = facility.Id, RecordTypeId = dairyRequisitionRecordTypeId);
        insert requisition;

        Test.startTest();
        requisition.FacilityName__c = dairyFacility.Id;
        update requisition;
        Test.stopTest();

        LabTestRequisition__c requisitionRec = [SELECT Id, IsDairy__c FROM LabTestRequisition__c WHERE Id = :requisition.Id LIMIT 1];
        Assert.areEqual(true, requisitionRec.IsDairy__c, 'IsDairy__c should become true when FacilityName__c changes to a PHOCSDairyFacility Account.');
    }

/**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of updateDairyRequisitionFlag
*              on update, verifying IsDairy__c flips to false when FacilityName__c changes away
*              from a PHOCSDairyFacility Account.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void updateDairyRequisitionFlag_UpdatesToFalse_WhenFacilityChangedAwayFromDairy_Test() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Account dairyFacility = [SELECT Id FROM Account WHERE Name = 'Test Dairy Facility' LIMIT 1];
        Id dairyRequisitionRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName().get('PHOCSDairyProductTestRequisition').getRecordTypeId();

        LabTestRequisition__c requisition = new LabTestRequisition__c(FacilityName__c = dairyFacility.Id, RecordTypeId = dairyRequisitionRecordTypeId);
        insert requisition;

        Test.startTest();
        requisition.FacilityName__c = facility.Id;
        update requisition;
        Test.stopTest();

        LabTestRequisition__c requisitionRec = [SELECT Id, IsDairy__c FROM LabTestRequisition__c WHERE Id = :requisition.Id LIMIT 1];
        Assert.areEqual(false, requisitionRec.IsDairy__c, 'IsDairy__c should become false when FacilityName__c changes away from a PHOCSDairyFacility Account.');
    }
}