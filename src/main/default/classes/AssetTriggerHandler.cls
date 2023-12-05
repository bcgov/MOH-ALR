public without sharing class AssetTriggerHandler implements TriggerHandler {
    //attributes
    private boolean triggerIsExecuting;
    private integer triggerSize;
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
        AssetTriggerUtility.generateInvoices(newAsset, newAssetMap);
    }
    //afterUpdate
    public void afterUpdate(List<Asset> oldAssets, List<Asset> newAsset, Map<ID, SObject> oldAssetMap, Map<ID, SObject> newAssetMap) {
        AssetTriggerUtility.generateInvoices(newAsset, newAssetMap); 
        AssetTriggerUtility.generateRenewalInvoices(newAsset, oldAssetMap, newAssetMap);
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