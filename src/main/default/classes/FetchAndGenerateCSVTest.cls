/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                           ALR-799              ACN-ALR       Issues on Web Services Residence Report   
*@Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]    
                09-05-2024      ALR-1259        ACN-ALR     Added New Method (testGenerateCSVAddedCheck) to Cover check in class
***********************************************************************************************/
@isTest
private class FetchAndGenerateCSVTest {

    @isTest
    static void testGenerateCSV() {
        
        // Create an instance of DMLOptions
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);

        Account Registrant = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Registrant').getRecordTypeId(),
            Name = 'Test Registrant',
            LicenseType__c = regAuth.Id
        );
        insert Registrant;
              
        Account Residence = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        
        Service__c ser = new Service__c(
            ServiceName__c = 'Assistance with daily living activities',
            ServiceType__c = 'Assisted Living Service',
            ProvidedBy__c = 'Registrant',
            Account__c = Residence.id
        );
        insert ser;

        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(Residence.LicenseType__c, Residence.Id, true);
        
        Asset unit1 = TestDataFactory.createUnit('1','Private',2,Residence.Id,true);
        
        Test.startTest();
        // Call the generateCSV method
        String generatedCSV = FetchAndGenerateCSV.generateCSV();

        // Log the generated CSV content for debugging
        System.debug('Generated CSV: ' + generatedCSV);

        // Add your assertions here based on the expected CSV content or any specific criteria
        Assert.areEqual(false, generatedCSV.contains(Registrant.Name), 'CSV should contain Registrant name');
        Assert.areEqual(true, generatedCSV.contains(Residence.Name), 'CSV should contain Residence name');
        Test.stopTest();

    }
    
    @isTest
    static void testGenerateCSVAddedCheck() {

        // Create an instance of DMLOptions
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Health', 'License', 'MH', 1, 2, 3, 4, true);

        Account Registrant = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Registrant').getRecordTypeId(),
            Name = 'Test Registrant',
            LicenseType__c = regAuth.Id
        );
        insert Registrant;
              
        Account Residence = TestDataFactory.createResidence('Residence', 'residence1', regAuth.Id, true);
        Residence.ExemptionofAddressPublication__c = true;
        update Residence;
        
        Service__c ser = new Service__c(
            ServiceName__c = 'Assistance with daily living activities',
            ServiceType__c = 'Assisted Living Service',
            ProvidedBy__c = 'Registrant',
            Account__c = Residence.id
        );
        insert ser;
        
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(Residence.LicenseType__c, Residence.Id, true);

        Asset unit1 = TestDataFactory.createUnit('1','Private',2,Residence.Id,true);
        
        Test.startTest();
        String generatedCSV = FetchAndGenerateCSV.generateCSV();

        System.debug('Generated CSV: ' + generatedCSV);

        Assert.areEqual(false, generatedCSV.contains(Registrant.Name), 'CSV should contain Registrant name');
        Assert.areEqual(true, generatedCSV.contains(Residence.Name), 'CSV should contain Residence name');
        Test.stopTest();

    }
}