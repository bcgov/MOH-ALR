/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]               
***********************************************************************************************/
@isTest
private class FetchAndGenerateCSVTest {

    @isTest
    static void testGenerateCSV() {
        // Test data setup
        RegulatoryAuthorizationType testRegulatoryAuthorization = new RegulatoryAuthorizationType(
            Name = 'Test Regulatory Authorization'
        );
        insert testRegulatoryAuthorization;

        // Create a sample Account to use as the parent in the hierarchy
        Account testParentAccount = new Account(
            Name = 'AAA Recovery Society',
            LicenseType__c = testRegulatoryAuthorization.Id
        );
        insert testParentAccount;

        Account Registrant = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Registrant').getRecordTypeId(),
            Name = 'Test Registrant',
            LicenseType__c = testRegulatoryAuthorization.Id
        );
        insert Registrant;
              
        Account Residence = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Residence').getRecordTypeId(),
            Name = 'Test Residence',
            ParentId = Registrant.Id, // Hierarchy field referencing existing Account record
            LicenseType__c = testRegulatoryAuthorization.Id,
            Status__c = 'Registered Active'
        );
        insert Residence;
        
        Service__c ser = new Service__c(
            ServiceName__c = 'Assistance with daily living activities',
            ServiceType__c = 'Assisted Living Service',
            ProvidedBy__c = 'Registrant',
            Account__c = Residence.id
        );
        insert ser;
        
        BusinessLicense blRec = new BusinessLicense(
              RecordTypeId = Schema.getGlobalDescribe().get('BusinessLicense').getDescribe().getRecordTypeInfosByDeveloperName().get('License').getRecordTypeId(),
              Account__c = Residence.Id,
              RegulatoryAuthorizationTypeId = testRegulatoryAuthorization.Id,
              Status = 'Active',
              RegistrationCertificate__c = 'Test Reg Certificate',
              Name = 'Test Business License'
        );
        insert blRec;
        
        Asset unit1 = TestDataFactory.createUnit('1','Private',2,Residence.Id,true);
        
        Test.startTest();
        // Call the generateCSV method
        String generatedCSV = FetchAndGenerateCSV.generateCSV();

        // Log the generated CSV content for debugging
        System.debug('Generated CSV: ' + generatedCSV);

        // Add your assertions here based on the expected CSV content or any specific criteria
        Assert.areEqual(true, generatedCSV.contains(Registrant.Name), 'CSV should contain Registrant name');
        Assert.areEqual(true, generatedCSV.contains(Residence.Name), 'CSV should contain Residence name');
        Test.stopTest();

    }
}