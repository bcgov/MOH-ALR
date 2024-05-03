/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class is to maintain re-uable test methods
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-36              ACN-ALR        License renewal initiation 
***********************************************************************************************/
@isTest
public class TestDataFactory {
    
    @testVisible
    static Account createResidence(String recordTypeName, String Name, String licenseId,  Boolean dmlOption){
        
        Account registrant = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Registrant').getRecordTypeId(),
            Name = Name +' '+'Registrant',
            BillingCity = 'TT',
            BillingCountry = 'YY',
            BillingPostalCode = '225522',
            BillingState = 'TT',
            BillingStreet = 'YT');
        if(dmlOption){
            insert registrant;
        }
        
        Account  residence = new Account();
         residence.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
         residence.Name = Name;
        // residence.ClassType__c = 'Mental Helath';
         residence.LicenseType__c = licenseId;//ALR-185
         residence.ParentId = registrant.Id;
                 residence.Status__c = 'Registered Active with Conditions';//'Registered Active';//ALR-36 - added status
        if(dmlOption){
            insert  residence;
        }
        return  residence;
    }
    
     @testVisible
    static Asset createUnit(String Capacity,String Type,Decimal Quantity,Id AccId, Boolean dmlOption){
        
        Asset unit = new Asset();
        unit.Name = 'Units';
        unit.Capacity__c = Capacity;
        unit.Type__c = Type;
        unit.Quantity = Quantity;
        unit.AccountId = AccId;
        if(dmlOption){
            insert unit;
        }
        return unit;
    }
    //method to create regAuthType record - ALR-36
    @testVisible
    public static RegulatoryAuthorizationType createRegAuth(String authName, String authCategory, String authCode, Decimal lateFee, Decimal oneFee, Decimal partialFee, Decimal unitFee, Boolean isInsert) {
        RegulatoryAuthorizationType regAuthRec = new RegulatoryAuthorizationType(
        Name = authName,
        RegulatoryAuthCategory = authCategory,
        RegulatoryAuthorizationCode__c = authCode,
        LateFee__c = lateFee,
        OneTimeFee__c = oneFee,
        PartialUnitFee__c = partialFee,
        UnitFee__c = unitFee);
        if(isInsert) {
            Database.Insert(regAuthRec);
        }
        return regAuthRec;
    }
    //method to create bla record of rec type Renewal - ALR-36
    @testVisible
    public static BusinessLicenseApplication createRenewalBla(String regAuthId, Id accId, Boolean isInsert) {
      String blaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
      BusinessLicenseApplication blaRec = new BusinessLicenseApplication(
          recordTypeId = blaRecTypeId,
          AccountId = accId,
          LicenseTypeId = regAuthId,
          Status = 'Ready for Renewal',
          AppliedDate = DateTime.now(),
          RenewalYear__c = String.valueOf(Date.today().year()));
        if(isInsert) {
            Database.Insert(blaRec);
        }
        return blaRec;
    }
    //create reg trans rec - ALR-40
    @testVisible
    public static RegulatoryTrxnFee createTransFeeRecord(Id recordTypeId, Id accId, Id blaId, String feeType, String feeStatus, Boolean isInsert) {
        RegulatoryTrxnFee transFeeRec = new RegulatoryTrxnFee(
            recordTypeId = recordTypeId,
            AccountId = accId,
            ParentRecordId = blaId,
            FeeType__c = feeType,
            Status = feeStatus);
        if(isInsert) {
            Database.Insert(transFeeRec);
        }
        return transFeeRec;
    }
    //create reg trans fee item rec - ALR-40
    @testVisible
    public static RegulatoryTrxnFeeItem createTransFeeItemRecord(Id recordTypeId, Id regTrxnFeeId, Id assetId, String assetType, Decimal amtValue, Decimal quantValue, String feeType, Boolean isInsert) {
         RegulatoryTrxnFeeItem transFeeItemRec = new RegulatoryTrxnFeeItem(
         RegulatoryTrxnFeeId = regTrxnFeeId,
         Unit__c = assetId,
         Name = assetType,
         Amount__c = amtValue,
         Quantity__c = quantValue,
         FeeAmount = amtValue * quantValue,
         FeeType__c = feeType);
         if(isInsert) {
            Database.Insert(transFeeItemRec);
         }
         return transFeeItemRec;  
     }
    //method to create bl record - ALR-560
    @testVisible
    public static BusinessLicense createBlRecord(String regAuthId, Id accId, Id orgId, String certNo, String blName, Boolean isInsert) {
      String blRecTypeId = Schema.getGlobalDescribe().get('BusinessLicense').getDescribe().getRecordTypeInfosByDeveloperName().get('License').getRecordTypeId();
      BusinessLicense blRec = new BusinessLicense(
          recordTypeId = blRecTypeId,
          Account__c = accId,
          AccountId = orgId,
          RegulatoryAuthorizationTypeId = regAuthId,
          Status = 'Active',
          IsActive = TRUE,
          RegistrationCertificate__c = certNo,
          Name = blName);
        if(isInsert) {
            Database.Insert(blRec);
        }
        return blRec;
    }
    
    //method to create Contact Record - ALR-560
    @testVisible
    public static Contact createContactRecord(Id accId, String emailId, String fname, String lname, Boolean isInsert) {
        String conRecTypeId = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByDeveloperName().get('Contact').getRecordTypeId();
		Contact contRec = new Contact(
          RecordTypeId = conRecTypeId,
          AccountId = accId,
          email	 = emailId,
          Firstname = fname,
          LastName = lname);
        if(isInsert) {
            Database.Insert(contRec);
        }
        return contRec;
    }
    
    //method to create AccountContactRelation record - ALR-560
    @testVisible
    public static AccountContactRelation createAccContRelRecord(Id accId, Id contactId, Boolean isPrimary, Boolean isActive, Boolean isInsert) {
      AccountContactRelation acConRelRec = new AccountContactRelation(
          AccountId = accId,
          ContactId = contactId,
          PrimaryContact__c = isPrimary,
          IsActive = isActive);
        if(isInsert) {
            Database.Insert(acConRelRec);
        }
        return acConRelRec;
    }
    
    //method to create content version and content doc link - ALR-560
    @testVisible
    public static ContentVersion createContentVer(String title, Id linkedId, Boolean isInsert) {
        ContentVersion contentVersionRec = new ContentVersion(
          Title = title,
          PathOnClient = title,
          VersionData = Blob.valueOf('Test Content'),//EncodingUtil.base64Decode(body) - if blob was passed
          IsMajorVersion = true,
     	  ContentLocation = 'S'// S = Stored in Salesforce
     	);
        if(isInsert) {
            Database.Insert(contentVersionRec);
        }
        
        ContentDocument documentRec = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];
        //create ContentDocumentLink record
        ContentDocumentLink cdlRec = new ContentDocumentLink(
        LinkedEntityId = linkedId,
        ContentDocumentId = documentRec.Id,
        shareType = 'V');
        if(isInsert) {
             Database.Insert(cdlRec);
         }
         return contentVersionRec;
    } 
    
    
    @testVisible
    public static Case createComplaintCase(Id accountId, String subject, String description, Boolean wishToRemainAnonymous, Boolean needFeedbackOnResolution, Boolean residentAwareOfComplaint, Boolean dmlOption) {
        //ALR-762 - added recordtypeid
        String pubCompCaseTypeId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('PublicComplaintCase').getRecordTypeId();//ALR-762
        Case complaintCase = new Case(
            RecordTypeId = pubCompCaseTypeId,
            AccountId = accountId,
            Subject = subject,
            Description = description,
            WishtoRemainAnonymous__c = wishToRemainAnonymous ? 'Yes' : 'No',
            NeedFeedbackOnResolution__c = needFeedbackOnResolution ? 'Yes' : 'No',
            ResidentAwareofComplaint__c = residentAwareOfComplaint ? 'Yes' : 'No'
        );
        if (dmlOption) {
            insert complaintCase;
        }
        return complaintCase;
    }
    
    @testVisible
    public static Visit createinspection(Id accountId, Id visittypeId, Id placeid, String inspectionmethod, Boolean dmlOption) {
        //ALR-860
        Visit inspection = new Visit(
            AccountId = accountId,
            VisitTypeId = visittypeId,
            InspectionMethod__c = inspectionmethod,
            PlannedVisitStartTime = System.today(),
            PlaceId = placeid
                    );
        if (dmlOption) {
            insert inspection;
        }
        return inspection;
    }
}