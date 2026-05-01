@isTest(SeeAllData=false)
private class PHOCSExpireOWLRetentionBatchTest {

    static final Id FACILITY_RT_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();

    static Account buildAccount(String name, Boolean retentionActive, Date operationEndDate) {
        Account acc = new Account(
            Name                        = name,
            RecordTypeId                = FACILITY_RT_ID,
            Status__c                   = 'Closed',
            OWLPublicRetentionActive__c = retentionActive,
            OperationEndDate__c         = operationEndDate
        );
        insert acc;
        return acc;
    }

    @isTest
    static void testExpiresPastFiveYears() {
        Account old = buildAccount('Old OWL Facility', true, Date.today().addYears(-6));
        Test.startTest();
        Database.executeBatch(new PHOCSExpireOWLRetentionBatch(), 200);
        Test.stopTest();

        Account result = [SELECT OWLPublicRetentionActive__c FROM Account WHERE Id = :old.Id];
        System.assertEquals(false, result.OWLPublicRetentionActive__c, 'Retention flag must be cleared for facilities past the 5-year window');
    }

    @isTest
    static void testIgnoresWithinFiveYears() {
        Account recent = buildAccount('Recent OWL Facility', true, Date.today().addYears(-3));
        Test.startTest();
        Database.executeBatch(new PHOCSExpireOWLRetentionBatch(), 200);
        Test.stopTest();

        Account result = [SELECT OWLPublicRetentionActive__c FROM Account WHERE Id = :recent.Id];
        System.assertEquals(true, result.OWLPublicRetentionActive__c, 'Retention flag must remain true for facilities still within the 5-year window');
    }

    @isTest
    static void testIgnoresRetentionNotActive() {
        Account nonOwl = buildAccount('Non OWL Facility', false, Date.today().addYears(-6));
        Test.startTest();
        Database.executeBatch(new PHOCSExpireOWLRetentionBatch(), 200);
        Test.stopTest();

        Account result = [SELECT OWLPublicRetentionActive__c FROM Account WHERE Id = :nonOwl.Id];
        System.assertEquals(false, result.OWLPublicRetentionActive__c, 'Facilities with retention not active must never be touched by the expiry batch');
    }

    @isTest
    static void testExactFiveYearBoundary() {
        Account boundary = buildAccount('Boundary OWL Facility', true, Date.today().addYears(-5));
        Test.startTest();
        Database.executeBatch(new PHOCSExpireOWLRetentionBatch(), 200);
        Test.stopTest();

        Account result = [SELECT OWLPublicRetentionActive__c FROM Account WHERE Id = :boundary.Id];
        System.assertEquals(false, result.OWLPublicRetentionActive__c, 'Retention flag must be cleared on the exact 5-year anniversary day with <= logic');
    }

    @isTest
    static void testIgnoresAlreadyExpired() {
        Account alreadyExpired = buildAccount('Already Expired OWL', false, Date.today().addYears(-6));
        Test.startTest();
        Database.executeBatch(new PHOCSExpireOWLRetentionBatch(), 200);
        Test.stopTest();

        Account result = [SELECT OWLPublicRetentionActive__c FROM Account WHERE Id = :alreadyExpired.Id];
        System.assertEquals(false, result.OWLPublicRetentionActive__c, 'Already-expired flag must remain false after batch runs');
    }
}