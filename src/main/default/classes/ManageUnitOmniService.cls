/*********************************************************************************************************
* Class Name: ManageUnitOmniService
* Purpose:Manage units coming FROM ManageUnitOmniscript
* Created By:Accenture_ALR
* Created For:
* ********************************************************************************************************/
global class ManageUnitOmniService implements Callable { 
    public static String className = 'ManageUnitOmniService';
    public Set<Id> accountIdSet = new Set<Id>();
    public String unitRecordtypeId = BCMOH_Constants.parentAssetRecTypeId;
    public Object call(String action, Map<String,Object> args){
        Map<String,Object> output = (Map<String,Object>)args.get(BCMOH_Constants.IM_OUTPUT);
        Map<String,Object> options = (Map<String,Object>)args.get(BCMOH_Constants.IM_OPTIONS);
        return invokeMethod(action,args,output,options);
    } 
    /*********************************************************************************************************
* Method Name:invokeMethod
* Purpose: Invokable method FROM FROM Omniscript
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
            LogService.logAndPublish(className, 'invokeMethod', '', exp);
        }    
        return result;
    }
    /*********************************************************************************************************
* Method Name:mergeUnits
* Purpose: Merge common units comming FROM Omniscript
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
    public void mergeUnits(Map<String,Object> inputMap,Map<String,Object> outMap){
        Map<String,Decimal> totalQuantityByUnqStringMap = new Map<String,Decimal>();
        Map<String, List<Asset>> assetsByUniqueStringMap = new Map<String, List<Asset>>();
        Map<String, Asset> assetsByUniqueParentStringMap = new Map<String,Asset>();
        List<InputWrapper.AddUnitBlock> unitList = new List<InputWrapper.AddUnitBlock>();        
        String jsonInput = Json.serialize(inputMap.get(BCMOH_Constants.IM_INPUT));
        Map<String,Object> jsonParsed =(Map<String,Object> ) JSON.deserializeUntyped(jsonInput);
        Object AddUnitBlock = jsonParsed.get(BCMOH_Constants.IM_ADDUNITBLOCK);
        try{
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
                accountIdSet.add(assetRecord.AccountId);
                String uniqueStr = assetRecord.AccountId+assetRecord.Capacity__c+assetRecord.Type__c;            
                if(assetsByUniqueStringMap.containsKey(uniqueStr)){                
                    assetsByUniqueStringMap.get(uniqueStr).add(assetRecord);
                    totalQuantityByUnqStringMap.put(uniqueStr,totalQuantityByUnqStringMap.get(uniqueStr) + record.NoOfUnits);
                    continue;
                }            
                assetsByUniqueStringMap.put(uniqueStr,new List<Asset>{assetRecord});
                totalQuantityByUnqStringMap.put(uniqueStr, record.NoOfUnits);
            }
            for (Asset existingunit : [SELECT Id, Name, GenerateRenewalInvoice__c, Quantity, AccountId, Capacity__c, Type__c, ParentId FROM Asset WHERE AccountId IN :accountIdSet AND ParentId =:NULL AND recordtypeId =:BCMOH_Constants.parentAssetRecTypeId WITH SECURITY_ENFORCED]) {
                String uniqueParentStr = existingunit.AccountId+existingunit.Capacity__c+existingunit.Type__c;            
                if(!assetsByUniqueParentStringMap.containsKey(uniqueParentStr)){
                    assetsByUniqueParentStringMap.put(uniqueParentStr,existingunit);          
                    // continue;
                }           
                
            }
            if(!assetsByUniqueStringMap.isEmpty()){
                insertMergedAssets(assetsByUniqueStringMap,totalQuantityByUnqStringMap,assetsByUniqueParentStringMap);            
            }
        }
        catch(Exception exp) {
            LogService.logAndPublish(className, 'mergeUnits', '', exp);
        }  
    }
    /*********************************************************************************************************
* Method Name:insertMergedAssets
* Purpose:Inserting merged Units,Updating Parent,creating parent if Parent does not exists.
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
    private void insertMergedAssets(Map<String, List<Asset>> assetsByUniqueStringMap,Map<String,Decimal> totalQuantityByUnqStringMap,Map<String, Asset> assetsByUniqueParentStringMap) {
        List<Asset> insertAssetList = new List<Asset>();            
        try{
            for (String uniqueStr : assetsByUniqueStringMap.keySet()) {
                List<Asset> mergedUnits = assetsByUniqueStringMap.get(uniqueStr);                            
                Asset mergedAsset = createMergedAsset(mergedUnits[0]);
                mergedAsset.Quantity = totalQuantityByUnqStringMap.get(uniqueStr); 
                //Find parent record for child
                if(assetsByUniqueParentStringMap.containsKey(uniqueStr)){ //- make merged unit as child and update parent unit
                    Asset parentUnit = assetsByUniqueParentStringMap.get(uniqueStr);
                    parentUnit.Quantity = mergedAsset.GenerateInvoice__c == true ? parentUnit.Quantity : parentUnit.Quantity + mergedAsset.Quantity;                    
                    mergedAsset.parentId = parentUnit.Id;                    
                    insertAssetList.add(parentUnit);                   
                }else{//Parent not found-Create parent unit and update merged record as child.
                    Asset parentUnitAsset =new Asset(
                        Name = BCMOH_Constants.unitName+'-'+mergedUnits[0].Type__c,
                        AccountId = mergedUnits[0].AccountId,
                        Capacity__c = mergedUnits[0].Capacity__c,
                        Type__c = mergedUnits[0].Type__c,
                        RecordTypeId = BCMOH_Constants.parentAssetRecTypeId,
                        Quantity = mergedAsset.GenerateInvoice__c == true ? 0 : mergedAsset.Quantity                                
                    );
                    insertAssetList.add(parentUnitAsset);
                    mergedAsset.parentId = parentUnitAsset.Id;               
                }
                insertAssetList.add(mergedAsset);
            } 
            if (!insertAssetList.isEmpty()) {              
                Database.UpsertResult[] insertedAssetsSR = Database.Upsert(insertAssetList,false);
                updateParentOnChildAssets(insertedAssetsSR);                
            }            
        }catch(exception ex){
            LogService.logAndPublish(BCMOH_Constants.MANAGEUNITCLASSNAME, BCMOH_Constants.INSERTMERGERASSETMETHODNAME, '', ex);
        }
    }
    /*********************************************************************************************************
* Method Name:createAsset
* Purpose:Reusable create Asset method
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
                GenerateInvoice__c = typeValueSet.contains(record.UnitType) ? false : record.GenerateInvoiceValue,
                Description = record.Description,
                //  Status = record.GenerateInvoiceValue == true ? 'Pending Invoice' : 'Waived',
                Quantity = record.NoOfUnits
            );
    }
    
    /*********************************************************************************************************
* Method Name:createMergedAsset
* Purpose:Reusable create MergedAsset method
* Created By:Accenture
* Created For:
* ********************************************************************************************************/ 
    private Asset createMergedAsset(Asset mergedUnit){        
        return new Asset(                    
            Name = BCMOH_Constants.unitRequestName+'-'+mergedUnit.Type__c+'-'+system.today().format(),
            AccountId = mergedUnit.AccountId,
            Capacity__c = mergedUnit.Capacity__c,
            Type__c = mergedUnit.Type__c,
            Amount__c = mergedUnit.Amount__c,
            GenerateInvoice__c = mergedUnit.GenerateInvoice__c,
            Description = mergedUnit.Description,                  
            Status = mergedUnit.GenerateInvoice__c == true ? BCMOH_Constants.pendingInvoiceStatus : BCMOH_Constants.waivedStatus,
            RecordTypeId = BCMOH_Constants.unitRequestRecTypeId            
        );
    }
    
    /*********************************************************************************************************
* Method Name:updateParentOnChildAssets
* Purpose: Update parent Id on newly created unit request
* Created By:Accenture
* Created For:
* ********************************************************************************************************/
    private void updateParentOnChildAssets(Database.UpsertResult[] insertedAssetsSR){
        Map<String, Asset> insertedParentMap = new Map<String, Asset>();
        List<Asset> updateParentonChildAssetList = new List<Asset>();  
        Set<Id> insertedAssetIdSet = new Set<Id>();
        try{
            for(Database.UpsertResult sr : insertedAssetsSR) {
                If(sr.isSuccess()){                
                    insertedAssetIdSet.add(sr.getId()); 
                }                                      
            }
            List<Asset> insertedAssetList = [SELECT Id, Amount__c, Status, Name, Description, GenerateRenewalInvoice__c,GenerateInvoice__c, Quantity, AccountId, Capacity__c, Type__c, ParentId ,RecordTypeId FROM Asset WHERE Id IN : insertedAssetIdSet WITH SECURITY_ENFORCED];
            for (Asset insertedAsset : insertedAssetList){
                String unitstr = insertedAsset.AccountId+insertedAsset.Capacity__c+insertedAsset.Type__c;
                if(!insertedParentMap.containsKey(unitstr) && insertedAsset.RecordTypeId == BCMOH_Constants.parentAssetRecTypeId ){
                    insertedParentMap.put(unitstr,insertedAsset);          
                    continue;
                }  
            } 
            for (Asset insertedChildAsset : insertedAssetList){
                String unitstr = insertedChildAsset.AccountId+insertedChildAsset.Capacity__c+insertedChildAsset.Type__c;
                if(insertedParentMap.containsKey(unitstr) && insertedChildAsset.RecordTypeId == BCMOH_Constants.unitRequestRecTypeId && insertedChildAsset.ParentId == NULL){
                    insertedChildAsset.ParentId = insertedParentMap.get(unitstr).Id;
                    updateParentonChildAssetList.Add(insertedChildAsset);
                }  
            }
            
            if(!updateParentonChildAssetList.isEmpty()){
                update updateParentonChildAssetList;
            }
            GenerateInvoiceController.generateInvoices(insertedAssetList);
            
        }Catch(exception ex){
            LogService.logAndPublish(BCMOH_Constants.MANAGEUNITCLASSNAME, BCMOH_Constants.UPDATEPARENTONCHILDASSETMETHODNAME, '', ex);
        }
    }    
}