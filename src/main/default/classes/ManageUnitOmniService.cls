/*********************************************************************************************************
* Method Name:
* Purpose:
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
global class ManageUnitOmniService implements Callable {
    public Object call(String action, Map<String,Object> args){
        Map<String,Object> output = (Map<String,Object>)args.get(BCMOH_Constants.IM_OUTPUT);
        Map<String,Object> options = (Map<String,Object>)args.get(BCMOH_Constants.IM_OPTIONS);
        return invokeMethod(action,args,output,options);
    } 
/*********************************************************************************************************
* Method Name:
* Purpose:
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
    global Boolean invokeMethod(String methodName, Map<String,Object> inputMap, Map<String,Object> outMap, Map<String,Object> options) {
        Boolean result = false;        
        try {
            // check methodName
            if(methodName == 'mergeUnits') {                
                mergeUnits(inputMap,outMap);
                result = true;
            }            
        } catch(Exception exp) {
            system.debug('something went wrong::1'+exp);
        }    
        return result;
    }
/*********************************************************************************************************
* Method Name:
* Purpose:
* Created By:Accenture
* Created For:
*********************************************************************************************************/
    public void mergeUnits(Map<String,Object> inputMap,Map<String,Object> outMap){
        Map<String,Decimal> totalQuantityByUnqStringMap = new Map<String,Decimal>();
        Map<String, List<Asset>> assetsByUniqueStringMap = new Map<String, List<Asset>>();
        List<InputWrapper.AddUnitBlock> unitList = new List<InputWrapper.AddUnitBlock>();
        String jsonInput = Json.serialize(inputMap.get(BCMOH_Constants.IM_INPUT));
        Map<String,Object> jsonParsed =(Map<String,Object> ) JSON.deserializeUntyped(jsonInput);
        Object AddUnitBlock = jsonParsed.get(BCMOH_Constants.IM_ADDUNITBLOCK);
        If(AddUnitBlock instanceof List<Object>){
          InputWrapper unitWrapper = (InputWrapper) System.JSON.deserialize(jsonInput, InputWrapper.class);
          unitList.addAll(unitWrapper.AddUnitBlock);
        } else{
          object unit = (object)jsonParsed.get(BCMOH_Constants.IM_ADDUNITBLOCK);          
          InputWrapper.AddUnitBlock unitRec = (InputWrapper.AddUnitBlock) System.JSON.deserialize(Json.serialize(unit), InputWrapper.AddUnitBlock   .class);
          unitList.add(unitRec);         
        }  
        for(InputWrapper.AddUnitBlock record: unitList) {
            Asset assetRecord = createAsset(record);
            String uniqueStr = assetRecord.AccountId+assetRecord.Capacity__c+assetRecord.Type__c;            
            if(assetsByUniqueStringMap.containsKey(uniqueStr)){
              //  Asset assetRecord = createAsset(record);
                assetsByUniqueStringMap.get(uniqueStr).add(assetRecord);
                totalQuantityByUnqStringMap.put(uniqueStr,totalQuantityByUnqStringMap.get(uniqueStr) + record.NoOfUnits);
                continue;
            }
           // Asset assetRecord = createAsset(record);
            assetsByUniqueStringMap.put(uniqueStr,new List<Asset>{assetRecord});
            totalQuantityByUnqStringMap.put(uniqueStr, record.NoOfUnits);
        }
        if(!assetsByUniqueStringMap.isEmpty()){
            insertMergedAssets(assetsByUniqueStringMap,totalQuantityByUnqStringMap);            
        }
        
    }
/*********************************************************************************************************
* Method Name:
* Purpose:
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
    private void insertMergedAssets(Map<String, List<Asset>> assetsByUniqueStringMap,Map<String,Decimal> totalQuantityByUnqStringMap) {
        List<Asset> insertAssetList = new List<Asset>();
        try{
            for (String uniqueStr : assetsByUniqueStringMap.keySet()) {
                List<Asset> mergedUnits = assetsByUniqueStringMap.get(uniqueStr);            
                Asset mergedAsset = new Asset(
                    Name = mergedUnits[0].Name, 
                    AccountId = mergedUnits[0].AccountId,
                    Capacity__c = mergedUnits[0].Capacity__c,
                    Type__c = mergedUnits[0].Type__c,
                    Amount__c = mergedUnits[0].Amount__c,
                    GenerateInvoice__c = mergedUnits[0].GenerateInvoice__c,
                  //  Status = mergedUnits[0].Status,
                    Quantity = totalQuantityByUnqStringMap.get(uniqueStr)
                );
                insertAssetList.add(mergedAsset);
            } 
            if (!insertAssetList.isEmpty()) {
                insert insertAssetList;
            }
        }catch(Exception exp){
            system.debug('something went wrong::'+exp);
        }
    }
/*********************************************************************************************************
* Method Name:
* Purpose:
* Created By:Accenture
* Created For:
* ********************************************************************************************************/ 
    private Asset createAsset(InputWrapper.AddUnitBlock record){
        Set<String> typeValueSet = new Set<String>{'Independent Living','Licensed','Other'};
            return new Asset(
                Name = record.Name,
                AccountId = record.AccountId,
                Capacity__c = typeValueSet.contains(record.UnitType) ? '1' : record.UnitCapacity,
                Type__c = record.UnitType,
                Amount__c = record.AmountValue,
                GenerateInvoice__c = record.GenerateInvoiceValue,
              //  Status = record.GenerateInvoiceValue == true ? 'Pending Invoice' : 'Waived',
                Quantity = record.NoOfUnits
            );
     }
 }