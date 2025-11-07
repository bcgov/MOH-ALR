@IsTest
private class PHOCSAccountWaterDataTriggerTest {

    @IsTest
    static void testTrigger_OnInsert_EnqueuesQueueable() {

        Test.startTest();

            Account acc = new Account(
                Name = 'Test Insert',
                WaterLicenseNumber__c = 'LIC-123'
            );
            insert acc;

            //  One queueable job must be enqueued
            System.assertEquals(1, Limits.getQueueableJobs(),
                'Queueable should be enqueued when account inserted with License');

        Test.stopTest();
    }

    @IsTest
    static void testTrigger_OnUpdate_EnqueuesWhenLicenseChanges() {

        Account acc = new Account(
            Name = 'Test Update',
            WaterLicenseNumber__c = 'LIC-111'
        );
        insert acc;

        Test.startTest();

            acc.WaterLicenseNumber__c = 'LIC-222';  // <-- changed
            update acc;

            //  Second queueable for update
            System.assertEquals(1, Limits.getQueueableJobs(),
                'Queueable should be enqueued when License is updated');

        Test.stopTest();
    }

    @IsTest
    static void testTrigger_OnUpdate_NoChange_NoQueueable() {

        Account acc = new Account(
            Name = 'No Change Account',
            WaterLicenseNumber__c = 'LIC-000'
        );
        insert acc;

        Test.startTest();

            // Updating a non-related field only
            acc.Name = 'Updated Name';
            update acc;

            //  No queueable job should be added
            System.assertEquals(0, Limits.getQueueableJobs(),
                'Queueable should NOT enqueue when there is no License/Application change');

        Test.stopTest();
    }

    @IsTest
    static void testTrigger_ApplicationNumberChangeEnqueues() {

        Account acc = new Account(
            Name = 'Application Change',
            WaterLicenseApplicationNumber__c = 'APP-001'
        );
        insert acc;

        Test.startTest();

            acc.WaterLicenseApplicationNumber__c = 'APP-002';
            update acc;

            System.assertEquals(1, Limits.getQueueableJobs(),
                'Queueable should run when Application number changes');

        Test.stopTest();
    }
}