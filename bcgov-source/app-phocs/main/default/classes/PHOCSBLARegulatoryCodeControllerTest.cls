/**********************************************************************************************
* @Author:      Accenture 
* @Date:        16 Jul 2026
* @Description: The purpose of this class is to cover Code coverage of PHOCSBLARegulatoryCodeController.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                16 Jul -  PHOCS-4529        -  Accenture   -  creates Business Application Regulatory Code junction records
***********************************************************************************************/
@isTest
public class PHOCSBLARegulatoryCodeControllerTest{
    private static final Id FACILITY_RT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
    private static final Id BUSINESS_LICENSE_RT = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('PHOCSExemptions').getRecordTypeId();
    private static final Id PHOCS_REG_CODE_RT = Schema.SObjectType.RegulatoryCode.getRecordTypeInfosByDeveloperName().get('PHOCSRegulatoryCode').getRecordTypeId();
    
    @testSetup
    public static void createTestData() {
        Account childCare = new Account(Name = 'Child Care Facility', Type = 'Child Care', RecordTypeId = FACILITY_RT);
        Account residential = new Account(Name = 'Residential Care', Type = 'Residential Care', RecordTypeId = FACILITY_RT);
        List<Account> accounts = new List<Account>{childCare, residential};
            insert accounts;
        
        // Regulatory Authorities
        RegulatoryAuthority childAuthority = new RegulatoryAuthority(Name = 'Child Care Licensing Regulation');
        RegulatoryAuthority communityAuthority = new RegulatoryAuthority(Name = 'Community Care & Assisted Living Act');
        RegulatoryAuthority residentialAuthority = new RegulatoryAuthority(Name = 'Residential Care Regulation');
        RegulatoryAuthority dolsopAuthority = new RegulatoryAuthority(Name = 'Director of Licensing Standards of Practice');
        List<RegulatoryAuthority> authorities = new List<RegulatoryAuthority>{childAuthority, communityAuthority, residentialAuthority, dolsopAuthority};
            insert authorities;
        
        // Regulatory Codes
        List<RegulatoryCode> regulatoryCodes = new List<RegulatoryCode>{
            new RegulatoryCode(Name = 'RC-001', Subject = 'Subject 1', RegulatoryCodeDescription__c = 'Description 1', Type = 'Exemption',
                               EffectiveFrom = System.today(), RecordTypeId = PHOCS_REG_CODE_RT, RegulatoryAuthorityId = childAuthority.Id),
                new RegulatoryCode(Name = 'RC-002', Subject = 'Subject 2', RegulatoryCodeDescription__c = 'Description 2', Type = 'Exemption',
                                   EffectiveFrom = System.today(), RecordTypeId = PHOCS_REG_CODE_RT, RegulatoryAuthorityId = communityAuthority.Id),
                new RegulatoryCode(Name = 'RC-003', Subject = 'Subject 3', RegulatoryCodeDescription__c = 'Description 3', Type = 'Exemption',
                                   EffectiveFrom = System.today(), RecordTypeId = PHOCS_REG_CODE_RT, RegulatoryAuthorityId = residentialAuthority.Id),
                new RegulatoryCode(Name = 'DOLSOP-CC', Subject = 'Child Care DOLSOP', RegulatoryCodeDescription__c = 'Child Care only', Type = 'Exemption',
                                   EffectiveFrom = System.today(), RecordTypeId = PHOCS_REG_CODE_RT, RegulatoryAuthorityId = dolsopAuthority.Id,
                                   ExemptionFacilityType__c = 'Child Care'),
                new RegulatoryCode(Name = 'DOLSOP-RC', Subject = 'Residential Care DOLSOP', RegulatoryCodeDescription__c = 'Residential Care only', Type = 'Exemption',
                                   EffectiveFrom = System.today(), RecordTypeId = PHOCS_REG_CODE_RT, RegulatoryAuthorityId = dolsopAuthority.Id,
                                   ExemptionFacilityType__c = 'Residential Care')
                };
                    insert regulatoryCodes;
        
        // Regulatory Authorization Type (required lookup on BusinessLicenseApplication)
        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(Name = 'Residential Care Facility Licence', RegulatoryAuthCategory = 'License', IssuingDepartmentId = communityAuthority.Id);
        insert licenseType;
        
        // Business License Applications
        BusinessLicenseApplication childApplication = new BusinessLicenseApplication(RecordTypeId = BUSINESS_LICENSE_RT, AccountId = childCare.Id, LicenseTypeId = licenseType.Id, AppliedDate = System.today(), Category = 'Exemption');
        BusinessLicenseApplication residentialApplication = new BusinessLicenseApplication(RecordTypeId = BUSINESS_LICENSE_RT, AccountId = residential.Id, LicenseTypeId = licenseType.Id, AppliedDate = System.today(), Category = 'Exemption');
        
        List<BusinessLicenseApplication> applications = new List<BusinessLicenseApplication>{childApplication, residentialApplication};
        insert applications;
    }
/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the getEligibleRegulatoryCodes.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/    
    @IsTest
    public static void testGetEligibleRegulatoryCodesChildCare() {
        BusinessLicenseApplication application = [SELECT Id FROM BusinessLicenseApplication WHERE Account.Name = 'Child Care Facility' LIMIT 1];
        
        Test.startTest();
        PHOCSBLARegulatoryCodeController.RegulatoryCodeResponse response = PHOCSBLARegulatoryCodeController.getEligibleRegulatoryCodes(application.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, response, 'Response should not be null');
        Assert.areEqual('Child Care', response.accountType, 'Account type should be Child Care');
        Assert.areEqual(3, response.regulatoryCodes.size(), 'Expected shared and Child Care regulatory codes');
        for (PHOCSBLARegulatoryCodeController.RegulatoryCodeWrapper code : response.regulatoryCodes) {
            Assert.areNotEqual('DOLSOP-RC', code.regulatoryCode, 'Residential Care DOLSOP code must not be returned');
        }
    }

/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the getEligibleRegulatoryCodes.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @IsTest
    public static void testGetEligibleRegulatoryCodesResidential(){
        BusinessLicenseApplication application = [SELECT Id FROM BusinessLicenseApplication WHERE Account.Name = 'Residential Care' LIMIT 1];
        
        Test.startTest();
        PHOCSBLARegulatoryCodeController.RegulatoryCodeResponse response = PHOCSBLARegulatoryCodeController.getEligibleRegulatoryCodes(application.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, response, 'Response should not be null');
        Assert.areEqual('Residential Care', response.accountType, 'Account type should be Residential Care');
        Assert.areEqual(3, response.regulatoryCodes.size(), 'Expected shared and Residential Care regulatory codes');
        for (PHOCSBLARegulatoryCodeController.RegulatoryCodeWrapper code : response.regulatoryCodes) {
            Assert.areNotEqual('DOLSOP-CC', code.regulatoryCode, 'Child Care DOLSOP code must not be returned');
        }
    }
    
/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the getEligibleRegulatoryCodes.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @IsTest
    public static void testSaveRegulatoryCodes() {
        BusinessLicenseApplication application = [SELECT Id FROM BusinessLicenseApplication WHERE Account.Name = 'Child Care Facility' LIMIT 1];
        RegulatoryCode code = [SELECT Id FROM RegulatoryCode WHERE Name = 'RC-001' LIMIT 1];
        List<Id> regulatoryCodeIds = new List<Id>{code.Id};
            
            Test.startTest();
        PHOCSBLARegulatoryCodeController.SaveRegulatoryCodeResponse response = PHOCSBLARegulatoryCodeController.saveRegulatoryCodes(application.Id, regulatoryCodeIds);
        Test.stopTest();
        
        Assert.areEqual(1, response.successCount, 'Expected 1 successful save');
        Assert.areEqual(0, response.failureCount, 'Expected 0 failures');
        
        List<BusinessApplicationRegulatoryCode__c> junctionRecords = [SELECT Id FROM BusinessApplicationRegulatoryCode__c WHERE BusinessLicenseApplication__c = :application.Id];
        Assert.areEqual(1, junctionRecords.size(), 'Expected 1 junction record to be created');
    }

/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the saveRegulatoryCodes.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @IsTest
    public static void testDuplicateSave() {
        BusinessLicenseApplication application = [SELECT Id FROM BusinessLicenseApplication WHERE Account.Name = 'Child Care Facility' LIMIT 1];
        RegulatoryCode code = [SELECT Id FROM RegulatoryCode WHERE Name = 'RC-001'LIMIT 1];
        
        BusinessApplicationRegulatoryCode__c existingJunction = new BusinessApplicationRegulatoryCode__c(BusinessLicenseApplication__c = application.Id, RegulatoryCode__c = code.Id);
        insert existingJunction;
        List<Id> regulatoryCodeIds = new List<Id>{code.Id};
            
        Test.startTest();
        PHOCSBLARegulatoryCodeController.SaveRegulatoryCodeResponse response = PHOCSBLARegulatoryCodeController.saveRegulatoryCodes(application.Id, regulatoryCodeIds);
        Test.stopTest();
        
        Assert.areEqual(0, response.successCount, 'Expected 0 successful saves for duplicate');
        Assert.areEqual(1, response.skippedDuplicateCount, 'Expected 1 skipped duplicate');
    }

/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the getApplicableRegulatoryAuthorities.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @IsTest
    public static void testGetAuthorities() {
        Set<String> authorities = new Set<String>();
        Test.startTest();
        authorities = PHOCSBLARegulatoryCodeController.getApplicableRegulatoryAuthorities('Child Care');
        Test.stopTest();
        
        Assert.areEqual(3, authorities.size(), 'Expected 3 applicable authorities for Child Care');
    }

/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @IsTest
    public static void testGetAuthoritiesInvalid() {
        try {
            PHOCSBLARegulatoryCodeController.getApplicableRegulatoryAuthorities('School');
            Assert.fail('Exception expected for unsupported Account Type');
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Script-thrown exception'), 'Exception message should mention unconfigured Regulatory Codes');
        }
    }

/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/         
    @IsTest
    public static void testSaveWithEmptyList() {
        BusinessLicenseApplication application = [SELECT Id FROM BusinessLicenseApplication WHERE Account.Name = 'Child Care Facility' LIMIT 1];
        try {
            PHOCSBLARegulatoryCodeController.saveRegulatoryCodes(application.Id, new List<Id>());
            Assert.fail('Exception expected when no Regulatory Codes are selected');
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Script-thrown exception'), 'Exception message should mention Regulatory Code selection is required');
        }
    }

/**
* @author: Accenture
* @date: 16 Jul 2026
* @description: Covers the exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/     
    @IsTest
    public static void testNullBusinessLicenseApplication(){
        try {
            PHOCSBLARegulatoryCodeController.getEligibleRegulatoryCodes(null);
            Assert.fail('Exception expected for null Business License Application Id');
        } catch (Exception ex) {
            Assert.isTrue(ex.getMessage().contains('Script-thrown exception'), 'Exception message should mention Business License Application Id is required');
        }
    }
}
