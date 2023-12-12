public without sharing class AssetTriggerHandler implements TriggerHandler {
    //attributes
    private boolean triggerIsExecuting;
    private integer triggerSize;
    Public static Boolean firstCall = true;//recursive check
    public AssetTriggerHandler helper;
    //beforeInsert
    public void beforeInsert(List<Asset> newAssets) {
    }
    //beforeUpdate
    public void beforeUpdate(List<Asset> oldAsset, List<Asset> newAsset, Map<ID, SObject> oldAssetMap, Map<ID, SObject> newAssetMap) {
    }
    //beforeDelete
    public void beforeDelete(List<Asset> oldAsset, Map<ID, SObject> oldAssetMap) {
    }
    //afterInsert
    public void afterInsert(List<Asset> newAsset, Map<Id, SObject> newAssetMap) {
        //code to be removed starts
        /* for(Asset assetRec : newAsset) {
            //Asset oldRec = (Asset)oldAssetMap.get(assetRec.Id);
            //system.debug('%% afterInsert old asset values '+oldRec.Id+' '+oldRec.GenerateInvoice__c+' '+oldRec.recordTypeId+' '+oldRec.Status+' '+oldRec.Quantity+' '+oldRec.ParentId+' '+oldRec.Name);
            system.debug('%% afterInsert new asset values '+assetRec.Id+' '+assetRec.GenerateInvoice__c+' '+assetRec.recordTypeId+' '+assetRec.Status+' '+assetRec.Quantity+' '+assetRec.ParentId+' '+assetRec.Name);  
        }*/
         //code to be removed ends
        AssetTriggerUtility.generateInvoices(newAsset, newAssetMap, null);//scenario not needed
    }
    //afterUpdate
    public void afterUpdate(List<Asset> oldAssets, List<Asset> newAsset, Map<ID, SObject> oldAssetMap, Map<ID, SObject> newAssetMap) {
        //code to be removed starts
        /*for(Asset assetRec : newAsset) {
            Asset oldRec = (Asset)oldAssetMap.get(assetRec.Id);
            system.debug('%% afterUpdate old asset values '+oldRec.Id+' '+oldRec.GenerateInvoice__c+' '+oldRec.recordTypeId+' '+oldRec.Status+' '+oldRec.Quantity+' '+oldRec.ParentId+' '+oldRec.Name);
            system.debug('%% afterUpdate new asset values '+assetRec.Id+' '+assetRec.GenerateInvoice__c+' '+assetRec.recordTypeId+' '+assetRec.Status+' '+assetRec.Quantity+' '+assetRec.ParentId+' '+assetRec.Name);  
        }*/
        //code to be removed ends
        
        if(firstCall) {
            firstCall = false;
            AssetTriggerUtility.generateInvoices(newAsset, newAssetMap, oldAssetMap); 
        	AssetTriggerUtility.generateRenewalInvoices(newAsset, oldAssetMap, newAssetMap);
        }
    }
    //afterDelete
    public void afterDelete(List<Asset> oldAssets, Map<ID, SObject> oldAssetMap) {
    }
    //afterUndelete
    public void afterUndelete(List<Asset> newAssets, Map<ID, SObject> newAssetMap) {
    }
}
 /*public AssetTriggerHandler helper;
   public AssetTriggerHandler(boolean triggerIsExecuting, integer triggerSize) {
        this.triggerIsExecuting = triggerIsExecuting;
        this.triggerSize = triggerSize;
        this.helper = new AssetTriggerHandler();
    }*/