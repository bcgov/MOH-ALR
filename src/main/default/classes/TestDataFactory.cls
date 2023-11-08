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

}