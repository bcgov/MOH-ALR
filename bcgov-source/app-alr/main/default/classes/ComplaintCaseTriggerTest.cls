/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           ALR - 509           Sri Teja       Public complaints/Cases additional changes
                           ALR-762             ACN-ALR        Error Thrown on creation of Reportable Incident Case
                           EHIS-688            ACN-PHOCS      Updates IsDairyCase__c for PHOCS Case record types
***********************************************************************************************/
@isTest
public class ComplaintCaseTriggerTest {

    @testSetup
    public static void makeData() {
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);
        System.assertNotEquals(null, regAuth.Id, 'RegulatoryAuthorizationType record creation failed');
        Account residence = TestDataFactory.createResidence('Residence','residence1', regAuth.Id, true);
        System.assertNotEquals(null, residence.Id, 'Residence account creation failed');
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        Account facility = new Account(Name = 'Test Facility', RecordTypeId = rtPHOCSFacilityRecordType);
        insert facility;
        Id rtPHOCSDairyFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PHOCSDairyFacility').getRecordTypeId();
        Account dairyFacility = new Account(Name = 'Test Dairy Facility', RecordTypeId = rtPHOCSDairyFacilityRecordType);
        insert dairyFacility;
    }

    @isTest
    static void testComplaintCaseTrigger() {
        List<Case> caseList = new List<Case>();
        Test.startTest();
        Account residence = [SELECT Id FROM Account WHERE Name = 'residence1' LIMIT 1];
        System.assertNotEquals(null, residence.Id, 'Residence account not found');
        
        Case complaintCase = TestDataFactory.createComplaintCase(residence.Id, 'Test Case', 'Testing the trigger', false, false, false, false);
        System.assertNotEquals(null, complaintCase.RecordTypeId, 'Complaint case record type is not set');
        
        caseList.add(complaintCase);
        insert complaintCase;
        Test.stopTest();
        
        Case caseRec = [SELECT Id, Complaint_Case_ID__c FROM Case WHERE Id = :caseList[0].Id LIMIT 1];
        System.assertNotEquals(null, caseRec.Id, 'Inserted case record not found');
        
        Assert.isNotNull(caseRec.Complaint_Case_ID__c, 'Complaint_Case_ID__c should not be null');
    }
    
    @isTest
    static void testPHOCSCaseAfterInsert() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Id rtPHOCSComplaintRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSComplaint').getRecordTypeId();
        Case phocsCase = TestDataFactory.createComplaintCase(facility.Id, 'PHOCS Complaint Test', 'Testing PHOCS after insert', false, false, false, false);
        phocsCase.RecordTypeId = rtPHOCSComplaintRecordType;
        Test.startTest();
        insert phocsCase;
        Test.stopTest();
        Case caseRec = [SELECT Id, AccountId, IsDairyCase__c FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(facility.Id, caseRec.AccountId, 'Case AccountId should be the Facility account');
        System.assertEquals(false, caseRec.IsDairyCase__c, 'IsDairyCase__c should be false for a non-dairy facility');
    }

    @isTest
    static void testPHOCSCaseAccountChangeToDairy() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Account dairyFacility = [SELECT Id FROM Account WHERE Name = 'Test Dairy Facility' LIMIT 1];
        Id rtPHOCSComplaintRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSComplaint').getRecordTypeId();
        Case phocsCase = TestDataFactory.createComplaintCase(facility.Id, 'PHOCS Dairy Test', 'Testing AccountId change to dairy facility', false, false, false, false);
        phocsCase.RecordTypeId = rtPHOCSComplaintRecordType;
        insert phocsCase;
        Case insertedCase = [SELECT Id, AccountId, IsDairyCase__c FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(facility.Id, insertedCase.AccountId, 'Case AccountId should initially be the Facility account');
        System.assertEquals(false, insertedCase.IsDairyCase__c, 'IsDairyCase__c should initially be false');
        phocsCase.AccountId = dairyFacility.Id;
        Test.startTest();
        update phocsCase;
        Test.stopTest();
        Case updatedCase = [SELECT Id, AccountId, IsDairyCase__c FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(dairyFacility.Id, updatedCase.AccountId, 'Case AccountId should be changed to the dairy facility');
        System.assertEquals(true, updatedCase.IsDairyCase__c, 'IsDairyCase__c should be true for PHOCSDairyFacility');
    }

    @isTest
    static void testPHOCSCaseAccountChangeFromDairy() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Account dairyFacility = [SELECT Id FROM Account WHERE Name = 'Test Dairy Facility' LIMIT 1];
        Id rtPHOCSComplaintRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSComplaint').getRecordTypeId();
        Case phocsCase = TestDataFactory.createComplaintCase(dairyFacility.Id, 'PHOCS Dairy Change Test', 'Testing AccountId change from dairy facility', false, false, false, false);
        phocsCase.RecordTypeId = rtPHOCSComplaintRecordType;
        insert phocsCase;
        Case insertedCase = [SELECT Id, AccountId, IsDairyCase__c FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(dairyFacility.Id, insertedCase.AccountId, 'Case AccountId should initially be the dairy facility');
        System.assertEquals(true, insertedCase.IsDairyCase__c, 'IsDairyCase__c should initially be true');
        phocsCase.AccountId = facility.Id;
        Test.startTest();
        update phocsCase;
        Test.stopTest();
        Case updatedCase = [SELECT Id, AccountId, IsDairyCase__c FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(facility.Id, updatedCase.AccountId, 'Case AccountId should be changed to the Facility account');
        System.assertEquals(false, updatedCase.IsDairyCase__c, 'IsDairyCase__c should be false after changing from dairy to non-dairy facility');
    }

    @isTest
    static void testPHOCSCaseAccountIdUnchanged() {
        Account facility = [SELECT Id FROM Account WHERE Name = 'Test Facility' LIMIT 1];
        Id rtPHOCSComplaintRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSComplaint').getRecordTypeId();
        Case phocsCase = TestDataFactory.createComplaintCase(facility.Id, 'PHOCS Account Unchanged Test', 'Testing AccountId unchanged', false, false, false, false);
        phocsCase.RecordTypeId = rtPHOCSComplaintRecordType;
        insert phocsCase;
        Case insertedCase = [SELECT Id, AccountId, IsDairyCase__c, Subject FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(facility.Id, insertedCase.AccountId, 'Case AccountId should be the Facility account');
        System.assertEquals(false, insertedCase.IsDairyCase__c, 'IsDairyCase__c should initially be false');
        phocsCase.Subject = 'Updated Subject';
        Test.startTest();
        update phocsCase;
        Test.stopTest();
        Case updatedCase = [SELECT Id, AccountId, IsDairyCase__c, Subject FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(facility.Id, updatedCase.AccountId, 'Case AccountId should remain unchanged');
        System.assertEquals('Updated Subject', updatedCase.Subject, 'Case Subject should be updated');
        System.assertEquals(false, updatedCase.IsDairyCase__c, 'IsDairyCase__c should remain false when AccountId does not change');
    }

    @isTest
    static void testPHOCSCaseWithoutAccount() {
        Id rtPHOCSComplaintRecordType = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PHOCSComplaint').getRecordTypeId();
        Case phocsCase = TestDataFactory.createComplaintCase(null, 'PHOCS No Account Test', 'Testing PHOCS case without Account', false, false, false, false);
        phocsCase.RecordTypeId = rtPHOCSComplaintRecordType;
        Test.startTest();
        insert phocsCase;
        Test.stopTest();
        Case caseRec = [SELECT Id, AccountId, IsDairyCase__c FROM Case WHERE Id = :phocsCase.Id LIMIT 1];
        System.assertEquals(null, caseRec.AccountId, 'AccountId should be null');
        System.assertEquals(false, caseRec.IsDairyCase__c, 'IsDairyCase__c should be false when AccountId is null');
    }
}