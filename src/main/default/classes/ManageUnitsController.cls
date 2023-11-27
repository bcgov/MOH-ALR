/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 11-27-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ManageUnitsController {
    Public static String VALIDATE_QTY = 'Updated Quantity cannot be equal,null, negative or greater than the existing quantity.';
    public static final String UNITREQUEST_RECTYPEID_NAME = 'Unit_Request_Record_Type';
    Public static String NEW_UNIT_NAME='Unit Request';
    Public static String UNIT_FEE='Unit Fee';
    Public static String UNITREQUEST_STATUS='Completed';
    public static final Id UNITREQUESTRECTYPEID = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(UNITREQUEST_RECTYPEID_NAME).getRecordTypeId();
    
    @AuraEnabled
    public static string getUnitBasedOnResidence(String recordId){
        String assetListString = '[]';
        List<Asset> assetList = new List<Asset>();
        try{
            assetList = [SELECT Id, Capacity__c, Type__c, Quantity FROM Asset WHERE AccountId = : recordId AND ParentId =: NULL WITH SECURITY_ENFORCED];
            assetListString =  JSON.serialize(assetList);
        }catch(AuraHandledException e)
        {
            throw new AuraHandledException(e.getMessage());
        }
        return assetListString;
    }
    @AuraEnabled
    public static string updateUnits(Object data) {
                List<Asset> assetForCreateList = new List<Asset>();
        List<Asset> assetForValidateList = new List<Asset>();
        List<Asset> assetForUpdateList = (List<Asset>) JSON.deserialize(JSON.serialize(data),List<Asset>.class);
        Map<ID, Asset> existingUnits = new Map<ID, Asset>([SELECT Id,Name,GenerateRenewalInvoice__c, Quantity,AccountId,Capacity__c,Type__c FROM Asset where Id IN :assetForUpdateList]);
        try {
            for(Asset unit : assetForUpdateList){
                Asset newUnit = new Asset();
                newunit.parentId = unit.Id;
                newunit.Amount__c =UNIT_FEE;
                newunit.RecordTypeId = UNITREQUESTRECTYPEID;
                newunit.Name = NEW_UNIT_NAME;
                newunit.GenerateRenewalInvoice__c = unit.GenerateRenewalInvoice__c;
                newunit.AccountId = existingUnits.get(unit.Id).AccountId;
                newunit.Capacity__c = existingUnits.get(unit.Id).Capacity__c;
                newunit.Type__c = existingUnits.get(unit.Id).Type__c;
                newunit.Status = UNITREQUEST_STATUS;
                if(unit.Quantity >= existingUnits.get(unit.Id).Quantity || unit.Quantity < 0 || unit.Quantity == null)
                {
                    throw new MyException(VALIDATE_QTY);
                }else{
                    newunit.Quantity=unit.Quantity-existingUnits.get(unit.Id).Quantity;
                }
                assetForCreateList.add(newunit);
                if(unit.GenerateRenewalInvoice__c==true && existingUnits.get(unit.Id).GenerateRenewalInvoice__c==false){
                        unit.GenerateRenewalInvoice__c = true;
                }else if(unit.GenerateRenewalInvoice__c==false && existingUnits.get(unit.Id).GenerateRenewalInvoice__c==true){
                        unit.GenerateRenewalInvoice__c = true;
                }
                
            }
            if(!assetForUpdateList.isEmpty() && Asset.SObjectType.getDescribe().isAccessible() && !assetForCreateList.isEmpty()){
                update assetForUpdateList;
                insert assetForCreateList;
            }
            Map<Id,Decimal> mapOfUnitRequest = new Map<Id,Decimal>();
            List<AggregateResult> sumOfQuantity = [Select SUM(Quantity)sumQty,ParentId from Asset where ParentId IN :assetForUpdateList group by ParentId];
            if(sumOfQuantity.size()>0){
                for(AggregateResult a: sumOfQuantity){
                    Id unitsIds = (Id)a.get('ParentId');
                    Decimal totalQty = (Decimal)a.get('sumQty');
                    mapOfUnitRequest.put(unitsIds,totalQty);
                }
                For(Asset unit : assetForUpdateList){
                    if (mapOfUnitRequest.containsKey(unit.Id) && mapOfUnitRequest.get(unit.Id) !=unit.Quantity ) {
                        unit.Quantity = mapOfUnitRequest.get(unit.Id);
                        assetForValidateList.add(unit);
                    }
                }
                if(!assetForValidateList.isEmpty() && Asset.SObjectType.getDescribe().isAccessible()){
                    update assetForValidateList;
                }
            }
            return 'Success';
        }
        catch(Exception e)
        {   
            if ( String.isNotBlank( e.getMessage() ) && e.getMessage().contains( 'error:' ) ) {
                throw new AuraHandledException(e.getMessage().split('error:')[1].split(':')[0] + '.');
            } else {
                throw new AuraHandledException(e.getMessage());
            }
            
        }
    }
    public class MyException extends Exception {
        
    }
}