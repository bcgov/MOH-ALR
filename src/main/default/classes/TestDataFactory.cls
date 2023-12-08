@isTest
public class TestDataFactory {
    
    @testVisible
    static Account createResidence(String recordTypeName, String Name,  Boolean dmlOption){
        
        Account Registrant = new Account();
        Registrant.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Registrant').getRecordTypeId();
        Registrant.Name = Name +' '+'Registrant';        
        if(dmlOption){
            insert Registrant;
        }
        
        Account Residence = new Account();
        Residence.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
        Residence.Name = Name;
        residence.ClassType__c = 'Mental Helath';
        Residence.ParentId =Registrant.Id;
        Residence.Status__c = 'Registered Active';//ALR-36 - added status
        if(dmlOption){
            insert Residence;
        }
        return Residence;
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
    public static BusinessLicenseApplication createRenewalBla(String classType, Id accId, Boolean isInsert) {
      String blaRecTypeId = Schema.getGlobalDescribe().get('BusinessLicenseApplication').getDescribe().getRecordTypeInfosByDeveloperName().get('Renewal').getRecordTypeId();
	  Id regAuthId = [SELECT Id, Name, RegulatoryAuthCategory 
                      FROM RegulatoryAuthorizationType WHERE Name =: classType LIMIT 1].Id;
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
}