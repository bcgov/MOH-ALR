@isTest
private class ItemTriggerTest {

    @testSetup
    static void setupTestData() {
        Item__c item = new Item__c(
            MenuItems__c = 'Test Item'
        );
        insert item;
    }

    @isTest
    static void testBeforeInsert() {

        Item__c item = new Item__c(
            MenuItems__c = 'Test Insert Item'
        );

        Test.startTest();
        insert item;
        Test.stopTest();

        Item__c insertedItem = [
            SELECT Id, Name,MenuItems__c
            FROM Item__c
            WHERE Id = :item.Id
        ];

        System.assertNotEquals(
            null, insertedItem.Id,
            'Item should be inserted successfully.'
        );
    }

    @isTest
    static void testBeforeUpdate() {

        Item__c item = [
            SELECT Id, Name,MenuItems__c
            FROM Item__c
            LIMIT 1
        ];

        item.MenuItems__c = 'Updated Test Item';

        Test.startTest();
        update item;
        Test.stopTest();

        Item__c updatedItem = [
            SELECT Id, Name,MenuItems__c
            FROM Item__c
            WHERE Id = :item.Id
        ];

        System.assertEquals(
            'Updated Test Item',
            updatedItem.MenuItems__c,
            'Item should be updated successfully.'
        );
    }
}