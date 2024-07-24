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
        List<Account> accList = new List<Account>();
        List<Account> accList1 = new List<Account>();
        List<AssociatedLocation> accList2 = new List<AssociatedLocation>();
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
        accList.add(Residence);
        
        Schema.Location loc = new Schema.Location();
        loc.Name = 'U.S. 101N';
		loc.Longitude = 28.635308;
		loc.Latitude = 28.635308;
		insert loc;
        
        //Address
        Schema.Address addressRec = new Schema.Address(
            City = 'bl',
            Country = 'TT',
            State = 'JK',
            PostalCode = '885588',
            ParentId = loc.Id,
            LocationType = 'Residence'
        );
        Insert addressRec;
        loc.VisitorAddressId = addressRec.Id;
        update loc;
        
        //associate location
        Schema.AssociatedLocation asLoc = new Schema.AssociatedLocation(
        ParentRecordId = Residence.Id,
        LocationId = loc.Id);
        Insert asLoc;
        
        Service__c ser = new Service__c(
            ServiceName__c = 'Assistance with daily living activities',
            ServiceType__c = 'Assisted Living Service',
            ProvidedBy__c = 'Registrant',
            Account__c = Residence.id
        );
        insert ser;
        
        List<BusinessLicense> busiLicense = new List<BusinessLicense>();

        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(Residence.LicenseType__c, Residence.Id, true);
        
        BusinessLicense blRec = TestDataFactory.createBlRecord(regAuth.Id, Residence.Id, Residence.ParentId, '58659', 'BL RECORD 1', true);
        busiLicense.add(blRec);
        
        Contact con = new Contact(LastName = 'Test Contact',Phone ='1234567890');
        insert con;

        AccountContactRelation acr = new AccountContactRelation(
            AccountId = Residence.Id,
            ContactId = con.Id,
            Roles = 'Decision Maker',
            PrimaryContact__c = true
        );
        
        Asset unit1 = TestDataFactory.createUnit('1','Private',2,Residence.Id,true);
        
        Test.startTest();
        // Call the generateCSV method
        String generatedCSV = FetchAndGenerateCSV.generateCSV();
        //String getRegistrationCertificate = FetchAndGenerateCSV.getRegistrationCertificates(busiLicense);

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