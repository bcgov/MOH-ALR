@isTest(SeeAllData=false)
private class PHOCSExpireOWLRetentionSchedulerTest {

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
    static void testSchedulerLaunchesBatch() {
        Account expired = buildAccount('Scheduler Expired OWL Facility', true, Date.today().addYears(-6));
        Account recent  = buildAccount('Scheduler Recent OWL Facility',  true, Date.today().addYears(-3));

        Test.startTest();
        new PHOCSExpireOWLRetentionScheduler().execute(null);
        Test.stopTest();

        Map<Id, Account> results = new Map<Id, Account>([
            SELECT Id, OWLPublicRetentionActive__c
            FROM   Account
            WHERE  Id IN (:expired.Id, :recent.Id)
        ]);

        System.assertEquals(false, results.get(expired.Id).OWLPublicRetentionActive__c, 'Scheduler must launch the batch and clear the retention flag past the 5-year window');
        System.assertEquals(true, results.get(recent.Id).OWLPublicRetentionActive__c, 'Scheduler run must leave facilities still within the 5-year window untouched');
    }
}
