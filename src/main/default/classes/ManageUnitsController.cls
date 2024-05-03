/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is for 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]   
                11-8-23                        ChangeMeIn@UserSettingsUnder.SFDoc         
***********************************************************************************************/
public with sharing class ManageUnitsController {
    public static String className = 'ManageUnitsController';
    public static String VALIDATE_QTY = 'Updated Quantity cannot be equal, null, negative or greater than the existing quantity.';
    public static final String UNITREQUEST_RECTYPEID_NAME = 'Unit_Request_Record_Type';
    public static String NEW_UNIT_NAME='UnitRequest';
    public static String UNIT_FEE='Full Unit Fee';
    public static String PENDING_INVOICE = 'Pending Invoice';
    public static String UNITREQUEST_STATUS='Completed';
    public static final Id UNITREQUESTRECTYPEID = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(UNITREQUEST_RECTYPEID_NAME).getRecordTypeId();

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled
    public static string getUnitBasedOnResidence(String recordId){
        String assetListString = '[]';
        List<Asset> assetList = new List<Asset>();
        try{
            assetList = [SELECT Id, RecordTypeId, Capacity__c, Type__c, Quantity FROM Asset WHERE AccountId = : recordId AND ParentId =: NULL WITH SECURITY_ENFORCED];
            assetListString =  JSON.serialize(assetList);
        }catch(AuraHandledException e)
        {
            LogService.logAndPublish(className, 'getUnitBasedOnResidence', '', e);
            throw new AuraHandledException(e.getMessage());
        }
        return assetListString;
    }

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @AuraEnabled
    public static string updateUnits(Object data) {
        system.debug('data--'+data);
        List<Asset> assetForCreateList = new List<Asset>();
        List<Asset> assetForValidateList = new List<Asset>();
        List<Asset> assetForUpdateList = (List<Asset>) JSON.deserialize(JSON.serialize(data),List<Asset>.class);
        Map<ID, Asset> existingUnits = new Map<ID, Asset>([SELECT Id,Name,GenerateRenewalInvoice__c, Quantity,AccountId,Capacity__c,Type__c FROM Asset WHERE Id IN :assetForUpdateList WITH SECURITY_ENFORCED]);
        try {
            for(Asset unit : assetForUpdateList){
                Asset newUnit = new Asset();
                newunit.parentId = unit.Id;
                newunit.Amount__c =UNIT_FEE;
                newunit.RecordTypeId = UNITREQUESTRECTYPEID; 
                newunit.Name = NEW_UNIT_NAME+'-'+existingUnits.get(unit.Id).Type__c+'-'+system.today().format();
                newunit.GenerateRenewalInvoice__c = unit.GenerateRenewalInvoice__c;
                newunit.AccountId = existingUnits.get(unit.Id).AccountId;
                newunit.Capacity__c = existingUnits.get(unit.Id).Capacity__c;
                newunit.Type__c = existingUnits.get(unit.Id).Type__c;
                newunit.Status = UNITREQUEST_STATUS;
				if(unit.Quantity >= existingUnits.get(unit.Id).Quantity || unit.Quantity < 0 || unit.Quantity == null){
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
            List<AggregateResult> sumOfQuantity = [SELECT SUM(Quantity)sumQty,ParentId FROM Asset WHERE ParentId IN :assetForUpdateList AND status !=: PENDING_INVOICE WITH SECURITY_ENFORCED group by ParentId];
            if(sumOfQuantity.size()>0){
                for(AggregateResult a: sumOfQuantity){
                    Id unitsIds = (Id)a.get('ParentId');
                    Decimal totalQty = (Decimal)a.get('sumQty');
                    mapOfUnitRequest.put(unitsIds,totalQty);
                }
                for(Asset unit : assetForUpdateList){
                    if (mapOfUnitRequest.containsKey(unit.Id) && mapOfUnitRequest.get(unit.Id) !=unit.Quantity ) {
                        unit.Quantity = mapOfUnitRequest.get(unit.Id);
                        assetForValidateList.add(unit);
                    }
                }
                if(!assetForValidateList.isEmpty() && Asset.SObjectType.getDescribe().isAccessible()){
                    update assetForValidateList;
                }
                GenerateInvoiceController.generateRenewalInvoices(assetForUpdateList);
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

/**
* @Author: Accenture_ALR Dev Team
* @date: 
* @description: The purpose of this method is to
* @return:  
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public class MyException extends Exception {
        
    }
}