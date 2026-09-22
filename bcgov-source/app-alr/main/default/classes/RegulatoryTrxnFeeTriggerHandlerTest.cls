/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class is 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-40              Sweta          Fee calculation for newly added unit(s)
                           EHIS-910            Deepak         added PHOCS coverage for generateInvoiceOnPaymentReminderChange (triggered via the trigger's PHOCS section on afterUpdate)
                           EHIS-910            Deepak         added AsyncApexJob assertions confirming invoice generation now runs via PHOCSInvoiceGenerationQueueable
***********************************************************************************************/
@isTest
public class RegulatoryTrxnFeeTriggerHandlerTest {

    private static final String HA_NORTHERN = 'Northern Health - NH';
    private static final String FEE_TYPE_RENEWAL = 'Renewal';
    private static final String PAYMENT_REMINDER_SEND_RENEWAL = 'Send Renewal';
    private static final String PAYMENT_REMINDER_LATE_FEE_GENERATED = 'Late Fee Generated';
    private static final Id RT_PHOCS_NON_DAIRY_TXN_FEE = Schema.SObjectType.RegulatoryTrxnFee.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFee').getRecordTypeId();

    @testSetup
    static void setupTestData() {
        Id rtPHOCSFacilityRecordType = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();

        Account billingAccount = new Account(
            Name = 'ABC ChildCare Inc',
            RecordTypeId = rtPHOCSFacilityRecordType,
            BillingStreet = '12 Langley Ave',
            BillingCity = 'Fraser Lake',
            BillingState = 'BC',
            BillingPostalCode = 'V3D A5B',
            HealthAuthority__c = HA_NORTHERN
        );
        insert billingAccount;

        DocumentTemplate template = new DocumentTemplate(
            Name = 'PHOCSInvoiceTemplate',
            Type = 'MicrosoftWord',
            TokenMappingType = 'JSON',
            TokenMappingMethodType = 'OmniDataTransform'
        );
        insert template;

        ContentVersion templateContentVersion = new ContentVersion(
            Title = 'PHOCSInvoiceTemplate',
            PathOnClient = 'PHOCSInvoiceTemplate.docx',
            VersionData = Blob.valueOf('Test template content')
        );
        insert templateContentVersion;
        templateContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :templateContentVersion.Id LIMIT 1];

        DocumentTemplateContentDoc templateContentDocLink = new DocumentTemplateContentDoc(
            Name = 'PHOCSInvoiceTemplate',
            DocumentTemplateId = template.Id,
            ContentDocumentId = templateContentVersion.ContentDocumentId
        );
        insert templateContentDocLink;
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to isolate whether
*                  generateInvoiceOnPaymentReminderChange's own condition logic enqueues the
*                  job correctly, independent of whether the trigger is actually invoking it -
*                  calls the method directly with a hand-built old/new pair instead of going
*                  through an actual DML update.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void generateInvoiceOnPaymentReminderChange_DirectCall_EnqueuesJob_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee oldFee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert oldFee;

        RegulatoryTrxnFee newFee = oldFee.clone(true, true, false, false);
        newFee.PaymentReminder__c = PAYMENT_REMINDER_SEND_RENEWAL;

        Test.startTest();
        RegulatoryTrxnFeeTriggerHandler.generateInvoiceOnPaymentReminderChange(
            new List<RegulatoryTrxnFee>{ newFee },
            new Map<Id, SObject>{ oldFee.Id => oldFee }
        );
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE ApexClass.Name = 'PHOCSInvoiceGenerationQueueable'];
        Assert.areEqual(1, jobs.size(), 'Calling generateInvoiceOnPaymentReminderChange directly should enqueue PHOCSInvoiceGenerationQueueable when PaymentReminder__c changes to a qualifying value.');
        Assert.areEqual('Completed', jobs[0].Status, 'The queueable job should have completed successfully. ExtendedStatus: ' + jobs[0].ExtendedStatus);
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of
*                  generateInvoiceOnPaymentReminderChange, verifying updating a Due,
*                  PHOCSNonDairyTransactionFee fee's PaymentReminder__c to 'Send Renewal'
*                  generates a DocumentGenerationProcess.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void updatePaymentReminderToSendRenewal_GeneratesInvoice_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert fee;

        Test.startTest();
        fee.PaymentReminder__c = PAYMENT_REMINDER_SEND_RENEWAL;
        update fee;
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE ApexClass.Name = 'PHOCSInvoiceGenerationQueueable'];
        Assert.areEqual(1, jobs.size(), 'The invoice generation should run via PHOCSInvoiceGenerationQueueable.');
        Assert.areEqual('Completed', jobs[0].Status, 'The queueable job should have completed successfully. ExtendedStatus: ' + jobs[0].ExtendedStatus);

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id, ReferenceObject FROM DocumentGenerationProcess];
        Assert.areEqual(1, generatedProcesses.size(), 'A DocumentGenerationProcess should be created when PaymentReminder__c changes to Send Renewal.');
        Assert.areEqual(fee.Id, generatedProcesses[0].ReferenceObject, 'ReferenceObject should be the RegulatoryTrxnFee Id.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of
*                  generateInvoiceOnPaymentReminderChange, verifying updating a Due,
*                  PHOCSNonDairyTransactionFee fee's PaymentReminder__c to 'Late Fee Generated'
*                  generates a DocumentGenerationProcess.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void updatePaymentReminderToLateFeeGenerated_GeneratesInvoice_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert fee;

        Test.startTest();
        fee.PaymentReminder__c = PAYMENT_REMINDER_LATE_FEE_GENERATED;
        update fee;
        Test.stopTest();

        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus FROM AsyncApexJob WHERE ApexClass.Name = 'PHOCSInvoiceGenerationQueueable'];
        Assert.areEqual(1, jobs.size(), 'The invoice generation should run via PHOCSInvoiceGenerationQueueable.');
        Assert.areEqual('Completed', jobs[0].Status, 'The queueable job should have completed successfully. ExtendedStatus: ' + jobs[0].ExtendedStatus);

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id, ReferenceObject FROM DocumentGenerationProcess];
        Assert.areEqual(1, generatedProcesses.size(), 'A DocumentGenerationProcess should be created when PaymentReminder__c changes to Late Fee Generated.');
        Assert.areEqual(fee.Id, generatedProcesses[0].ReferenceObject, 'ReferenceObject should be the RegulatoryTrxnFee Id.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the no-op path,
*                  verifying no DocumentGenerationProcess is created when PaymentReminder__c
*                  does not actually change.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void updateUnrelatedField_DoesNotGenerateInvoice_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL,
            PaymentReminder__c = PAYMENT_REMINDER_SEND_RENEWAL
        );
        insert fee;

        Test.startTest();
        fee.DueDate = Datetime.newInstance(2026, 12, 1, 0, 0, 0);
        update fee;
        Test.stopTest();

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess should be created when PaymentReminder__c does not change.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the non-qualifying-value
*                  path, verifying no DocumentGenerationProcess is created when
*                  PaymentReminder__c changes to a value other than Send Renewal or Late Fee
*                  Generated.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void updatePaymentReminderToNull_DoesNotGenerateInvoice_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL,
            PaymentReminder__c = PAYMENT_REMINDER_SEND_RENEWAL
        );
        insert fee;

        Test.startTest();
        fee.PaymentReminder__c = null;
        update fee;
        Test.stopTest();

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess should be created when PaymentReminder__c changes to a non-qualifying value.');
    }
}
    //test data setup
    /*@testSetup public static void setupData() {
        //fetch record type Ids
        Id parentAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Units_Record_Type').getRecordTypeId();
        Id childAssetRTId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('Unit_Request_Record_Type').getRecordTypeId();
        String transFeeRecTypeId = Schema.getGlobalDescribe().get('RegulatoryTrxnFee').getDescribe().getRecordTypeInfosByDeveloperName().get('TransactionFee').getRecordTypeId();
        Id feeRecTypeId;
        //RegulatoryAuthorizationType
        RegulatoryAuthorizationType regAuth = TestDataFactory.createRegAuth('Mental Helath', 'License', 'MH', 1, 2, 3, 4, true);
        
        //account - insert scenario
        Account residenceRec1 = TestDataFactory.createResidence('Residence', 'residenceAccount1', regAuth.Id, true);
        //bla
        BusinessLicenseApplication blaRec = TestDataFactory.createRenewalBla(residenceRec1.LicenseType__c, residenceRec1.Id, true); 
        //asset parent
        Asset unitRec1 = TestDataFactory.createUnit('1', 'Private', 0, residenceRec1.Id, false);
        unitRec1.recordTypeId = parentAssetRTId;
        //unitRec1.GenerateInvoice__c = true;
        unitRec1.Amount__c = 'Full Unit Fee';
        Database.Insert(unitRec1);
        //asset child
        Asset unitRec2 = TestDataFactory.createUnit('1', 'Private', 5, residenceRec1.Id, false);
        unitRec2.recordTypeId = childAssetRTId;
        unitRec2.GenerateInvoice__c = true;
        unitRec2.ParentId = unitRec1.Id;
        unitRec2.Status = BCMOH_Constants.pendingInvoiceStatus;
        Database.Insert(unitRec2);
        //asset child
        /*Asset unitRec3 = TestDataFactory.createUnit('1', 'Private', 4, residenceRec1.Id, false);
        unitRec3.recordTypeId = childAssetRTId;
        unitRec3.GenerateInvoice__c = true;
        unitRec3.ParentId = unitRec1.Id;
        unitRec3.Status = BCMOH_Constants.pendingInvoiceStatus;
        Database.Insert(unitRec3);
        //asset child
        Asset unitRec3 = TestDataFactory.createUnit('1', 'Private', 4, residenceRec1.Id, false);
        unitRec3.recordTypeId = childAssetRTId;
        unitRec3.parentId = unitRec1.Id;
        unitRec3.GenerateInvoice__c = true;
        unitRec3.Status = BCMOH_Constants.pendingInvoiceStatus;
        Database.Insert(unitRec3);
        //regTrans Fee renewal
        //RegulatoryTrxnFee regTransRec = TestDataFactory.createTransFeeRecord(transFeeRecTypeId, residenceRec1.Id, blaRec.Id, BCMOH_Constants.feeType, BCMOH_Constants.dueFeeStatus, true);
        //regTrans Fee unit
        RegulatoryTrxnFee regTransRec2 = TestDataFactory.createTransFeeRecord(transFeeRecTypeId, residenceRec1.Id, blaRec.Id, BCMOH_Constants.unitFeeType, BCMOH_Constants.dueFeeStatus, true);
        //regTransFee Item renewal
        RegulatoryTrxnFeeItem regTransItem = TestDataFactory.createTransFeeItemRecord(feeRecTypeId, regTransRec.Id, unitRec2.Id, unitRec2.Type__c, regAuth.UnitFee__c, unitRec2.Quantity, BCMOH_Constants.feeType, true);
    }
    //update scenario to paid
    @isTest
    static void updateRegulatoryTrxnFeeHandlerTest() {
        Test.startTest();
        RegulatoryTrxnFee regTransFeeRec = [SELECT Id, Status FROM RegulatoryTrxnFee limit 1];
        regTransFeeRec.Status = BCMOH_Constants.feeStatus;
        Database.Update(regTransFeeRec);
        Test.stopTest();
        RegulatoryTrxnFeeItem regFeeRec = [SELECT Id, Unit__r.Status FROM RegulatoryTrxnFeeItem
                                           WHERE RegulatoryTrxnFeeId =: regTransFeeRec.Id LIMIT 1];
        Asset assetRec = [SELECT Id, Status FROM Asset WHERE Id =: regFeeRec.Unit__c LIMIT 1];
        Assert.isTrue(regFeeRec.Unit__r.Status == BCMOH_Constants.feeStatus);
    }
    //update scenario to canceled
    @isTest
    static void updateCancelRegulatoryTrxnFeeHandlerTest() {
        Test.startTest();
        RegulatoryTrxnFee regTransFeeRec = [SELECT Id, Status FROM RegulatoryTrxnFee limit 1];
        regTransFeeRec.Status = BCMOH_Constants.cancelledStatus;
        Database.Update(regTransFeeRec);
        Test.stopTest();
        /*RegulatoryTrxnFeeItem regFeeRec = [SELECT Id, Unit__c FROM RegulatoryTrxnFeeItem
                                           WHERE RegulatoryTrxnFeeId =: regTransFeeRec.Id LIMIT 1];
        Asset assetRec = [SELECT Id, Status FROM Asset WHERE Id =: regFeeRec.Unit__c LIMIT 1];
        Assert.isTrue(assetRec.Id != NULL);
    }
}*/