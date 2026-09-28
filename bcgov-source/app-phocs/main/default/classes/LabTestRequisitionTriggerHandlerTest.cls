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

        // Orphan Lab Requisitions: the permission set assignment must exist BEFORE the test transaction,
        // otherwise FeatureManagement.checkPermission cannot see the custom permission.
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            String unique = String.valueOf(System.currentTimeMillis());
            User authorizedUser = new User(
                Alias = 'orphauth',
                Email = 'orphanauthuser' + unique + '@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'OrphanAuthorizedUser',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = adminProfile.Id,
                TimeZoneSidKey = 'America/Vancouver',
                Username = 'orphanauthuser' + unique + '@test.com.phocs'
            );
            insert authorizedUser;
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for (PermissionSet permissionSet : [SELECT Id FROM PermissionSet
                                                WHERE Name IN ('PHOCSManageOrphanLabRequisitionsPS', 'EHISPHOCSCRELabTestRequisitions')]) {
                assignments.add(new PermissionSetAssignment(AssigneeId = authorizedUser.Id, PermissionSetId = permissionSet.Id));
            }
            insert assignments;
        }

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

    private static final String ORPHAN_REQUISITION_NUMBER = 'ORPHAN-TEST-0001';

    private static User createAuthorizedUser() {
        // Created in @testSetup so the permission set assignment (and therefore the custom permission)
        // already exists when the test transaction starts.
        return [SELECT Id FROM User WHERE Alias = 'orphauth' AND IsActive = true LIMIT 1];
    }

    private static LabTestRequisition__c createOrphanWithLabTestRequired() {
        Id waterRecordTypeId = Schema.SObjectType.LabTestRequisition__c.getRecordTypeInfosByDeveloperName()
            .get('PHOCSWaterLabTestRequisition').getRecordTypeId();
        LabTestRequisition__c orphan = new LabTestRequisition__c(
            RecordTypeId = waterRecordTypeId,
            LabTestRequisitionNumber__c = ORPHAN_REQUISITION_NUMBER,
            Status__c = 'Submitted',
            TestCategory__c = 'Bacteriological'
        );
        insert orphan;

        Id waterLabTestRequiredRecordTypeId = Schema.SObjectType.LabTestRequired__c.getRecordTypeInfosByDeveloperName()
            .get('PHOCSWaterLabTestRequired').getRecordTypeId();
        insert new LabTestRequired__c(
            RecordTypeId = waterLabTestRequiredRecordTypeId,
            LabTestRequisition__c = orphan.Id,
            ExternalId__c = ORPHAN_REQUISITION_NUMBER + '-TC1'
        );
        return orphan;
    }

    private static Account createFraserFacility() {
        Account facility = new Account(
            Name = 'Fraser Orphan Facility',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId(),
            Type = 'Food',
            HealthAuthority__c = 'Fraser Health - FH'
        );
        insert facility;
        return facility;
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions - assigning a Facility stamps the Health Authority, moves ownership to the
*               Health Authority Admin Intake queue and cascades Facility and Health Authority to the results.
*/
    @isTest
    public static void assignFacilityToOrphanStampsHealthAuthorityAndCascadesTest() {
        User authorizedUser = createAuthorizedUser();
        Account facility = createFraserFacility();
        LabTestRequisition__c orphan = createOrphanWithLabTestRequired();
        Id queueId = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Fraser_Admin_Intake_Queue' LIMIT 1].Id;

        LabTestRequisitionTriggerHandler.hasManageOrphanPermissionForTest = true;
        Test.startTest();
        System.runAs(authorizedUser) {
            update new LabTestRequisition__c(Id = orphan.Id, FacilityName__c = facility.Id, SamplerName__c = 'UAT Sampler');
        }
        Test.stopTest();

        LabTestRequisition__c requisition = [SELECT FacilityName__c, SamplerName__c, HealthAuthority__c, OwnerId FROM LabTestRequisition__c WHERE Id = :orphan.Id];
        Assert.areEqual(facility.Id, requisition.FacilityName__c, 'Facility should be assigned');
        Assert.areEqual('UAT Sampler', requisition.SamplerName__c, 'Sampler Name is required by the record page and is allowed on an orphan');
        Assert.areEqual('Fraser Health - FH', requisition.HealthAuthority__c, 'Health Authority should be stamped from the Facility');
        Assert.areEqual(queueId, requisition.OwnerId, 'Ownership should move to the Health Authority Admin Intake queue');

        LabTestRequired__c labTestRequired = [SELECT FacilityName__c, HealthAuthority__c FROM LabTestRequired__c WHERE LabTestRequisition__c = :orphan.Id LIMIT 1];
        Assert.areEqual(facility.Id, labTestRequired.FacilityName__c, 'Facility should cascade to the Lab Test Required');
        Assert.areEqual('Fraser Health - FH', labTestRequired.HealthAuthority__c, 'Health Authority should cascade to the Lab Test Required');
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions - an authorized user cannot change any field other than Facility Name or
*               Drinking Water Component Name on an orphan.
*/
    @isTest
    public static void authorizedUserCannotEditOtherFieldsTest() {
        User authorizedUser = createAuthorizedUser();
        Account facility = createFraserFacility();
        LabTestRequisition__c orphan = createOrphanWithLabTestRequired();

        String errorMessage;
        LabTestRequisitionTriggerHandler.hasManageOrphanPermissionForTest = true;
        Test.startTest();
        System.runAs(authorizedUser) {
            try {
                update new LabTestRequisition__c(Id = orphan.Id, FacilityName__c = facility.Id, BoilAdvisory__c = 'Yes');
            } catch (DmlException ex) {
                errorMessage = ex.getMessage();
            }
        }
        Test.stopTest();

        Assert.isNotNull(errorMessage, 'Changing a field outside the allowed set should be rejected');
        Assert.isTrue(errorMessage.contains(LabTestRequisitionTriggerHandler.ORPHAN_FIELD_EDIT_ERROR), 'Expected the orphan field edit error');
        LabTestRequisition__c requisition = [SELECT FacilityName__c, BoilAdvisory__c FROM LabTestRequisition__c WHERE Id = :orphan.Id];
        Assert.isNull(requisition.FacilityName__c, 'Facility should not be saved');
        Assert.isNull(requisition.BoilAdvisory__c, 'Boil Water Advisory should not be saved');
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions - covers the catch blocks of the three orphan methods.
*/
    @isTest
    public static void orphanMethodsNegativeCatchBlockTest() {
        LabTestRequisitionTriggerHandler.throwExceptionForTest = true;
        List<LabTestRequisition__c> emptyList = new List<LabTestRequisition__c>();
        Map<Id, LabTestRequisition__c> emptyMap = new Map<Id, LabTestRequisition__c>();

        Test.startTest();
        try {
            LabTestRequisitionTriggerHandler.restrictOrphanFieldEdits(emptyList, emptyMap);
            Assert.fail('Exception expected from restrictOrphanFieldEdits');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        try {
            LabTestRequisitionTriggerHandler.assignOrphanRequisitionsToFacility(emptyList, emptyMap);
            Assert.fail('Exception expected from assignOrphanRequisitionsToFacility');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        try {
            LabTestRequisitionTriggerHandler.cascadeFacilityToLabTestsRequired(emptyList, emptyMap);
            Assert.fail('Exception expected from cascadeFacilityToLabTestsRequired');
        } catch (Exception ex) {
            Assert.areEqual('Test Exception', ex.getMessage());
        }
        Test.stopTest();
    }

/**
* @author: Accenture
* @date: 28 Sep 2026
* @description: Orphan Lab Requisitions - the orphan field restriction only applies to users holding the
*               PHOCSManageOrphanLabRequisitions custom permission.
*/
    @isTest
    public static void orphanRestrictionNotAppliedWithoutPermissionTest() {
        LabTestRequisition__c orphan = createOrphanWithLabTestRequired();

        Test.startTest();
        update new LabTestRequisition__c(Id = orphan.Id, Comments__c = 'Changed by administrator');
        Test.stopTest();

        LabTestRequisition__c requisition = [SELECT Comments__c, HealthAuthority__c FROM LabTestRequisition__c WHERE Id = :orphan.Id];
        Assert.areEqual('Changed by administrator', requisition.Comments__c, 'Users without the permission are not restricted');
        Assert.isNull(requisition.HealthAuthority__c, 'Health Authority stays blank while no Facility is assigned');
    }
}