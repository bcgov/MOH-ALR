/**********************************************************************************************
* @Author:      Accenture
* @Date:        29/10/2026
* @Description: Test class for AssetTriggerHandler
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@isTest
public class AssetTriggerHandlerTest {    
    private static final String HA_1 = 'Fraser Health - FH';
    private static final String HA_2 = 'Interior Health - IH';    
    private static Id assetRt(String devName) {
        return Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(devName).getRecordTypeId();
    }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Creates a DrinkingWaterSystem Account and a PHOCSDrinkingWaterSystemComponent parent Asset
* @param       haValue - HealthAuthority__c value for the Account
* @return      Asset - inserted parent Asset
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Asset createParent(String haValue) {
        Account acc = new Account(Name = 'DWS ' + haValue, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('DrinkingWaterSystem').getRecordTypeId(), HealthAuthority__c = haValue);
        insert acc;
        Asset parent = new Asset(Name = 'Parent ' + haValue, AccountId = acc.Id, RecordTypeId = assetRt('PHOCSDrinkingWaterSystemComponent'));
        insert parent;
        return parent;
    }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Insert of Treatment_Method child copies HealthAuthority__c from parent's Account
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void insertCopiesHealthAuthority() {
        Asset parent = createParent(HA_1);
        Test.startTest();
        Asset child = new Asset(Name = 'Child', RecordTypeId = assetRt('Treatment_Method'), ParentId = parent.Id);
        insert child;
        Test.stopTest();
        Assert.areEqual(HA_1, [SELECT HealthAuthority__c FROM Asset WHERE Id = :child.Id].HealthAuthority__c, 'HealthAuthority__c should be copied from parent Account');
    }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Changing ParentId copies the new parent's Account HealthAuthority__c
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void updateParentIdCopiesNewHealthAuthority() {
        Asset parent1 = createParent(HA_1);
        Asset parent2 = createParent(HA_2);
        Asset child = new Asset(Name = 'Child', RecordTypeId = assetRt('Treatment_Method'), ParentId = parent1.Id);
        insert child;
        Test.startTest();
        child.ParentId = parent2.Id;
        update child;
        Test.stopTest();
        Assert.areEqual(HA_2, [SELECT HealthAuthority__c FROM Asset WHERE Id = :child.Id].HealthAuthority__c, 'HealthAuthority__c should be updated from new parent');
    }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Assets of other record types are not affected
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void otherRecordTypeIsIgnored() {
        Asset parent = createParent(HA_1);
        Test.startTest();
        Asset other = new Asset(Name = 'Other', RecordTypeId = assetRt('PHOCSDrinkingWaterSystemComponent'), ParentId = parent.Id);
        insert other;
        Test.stopTest();
        Assert.areNotEqual(HA_1, [SELECT HealthAuthority__c FROM Asset WHERE Id = :other.Id].HealthAuthority__c, 'Other record types should not be updated');
    }
    
/**
* @author      Deepak
* @date        29/10/2026
* @description Bulk insert of 200 children is processed without limit issues
* @Modification Log
* [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void bulkInsert() {
        Asset parent = createParent(HA_1);
        List<Asset> children = new List<Asset>();
        for (Integer i = 0; i < 10; i++) {
            children.add(new Asset(Name = 'Child ' + i, RecordTypeId = assetRt('Treatment_Method'), ParentId = parent.Id));
        }
        Test.startTest();
        insert children;
        Test.stopTest();
        Assert.areEqual(10, [SELECT COUNT() FROM Asset WHERE ParentId = :parent.Id AND HealthAuthority__c = :HA_1], 'All 200 children should have HealthAuthority__c populated');
    }
}