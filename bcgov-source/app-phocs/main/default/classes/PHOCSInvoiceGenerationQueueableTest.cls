/**********************************************************************************************
* @Author:      Accenture
* @Date:        15 Sep 2026
* @Description: The purpose of this class is to cover code coverage of PHOCSInvoiceGenerationQueueable.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                15 Sep -  EHIS-910          -  Deepak      -  Initial version
***********************************************************************************************/
@isTest
public class PHOCSInvoiceGenerationQueueableTest {

    private static final String HA_NORTHERN = 'Northern Health - NH';
    private static final String FEE_TYPE_RENEWAL = 'Renewal';
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

        RegulatoryTrxnFee feeA = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        RegulatoryTrxnFee feeB = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert new List<RegulatoryTrxnFee>{ feeA, feeB };
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of execute, verifying a
*                  DocumentGenerationProcess is created for each supplied RegulatoryTrxnFee Id.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void execute_GeneratesInvoiceForEachSuppliedFeeId_Test() {
        List<RegulatoryTrxnFee> fees = [SELECT Id FROM RegulatoryTrxnFee];
        List<Id> feeIds = new List<Id>();
        for (RegulatoryTrxnFee fee : fees) {
            feeIds.add(fee.Id);
        }

        Test.startTest();
        System.enqueueJob(new PHOCSInvoiceGenerationQueueable(feeIds));
        Test.stopTest();

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id, ReferenceObject FROM DocumentGenerationProcess];
        Assert.areEqual(feeIds.size(), generatedProcesses.size(), 'One DocumentGenerationProcess should be created per supplied fee Id.');

        Set<Id> referenceObjectIds = new Set<Id>();
        for (DocumentGenerationProcess generatedProcess : generatedProcesses) {
            referenceObjectIds.add((Id) generatedProcess.ReferenceObject);
        }
        Assert.areEqual(new Set<Id>(feeIds), referenceObjectIds, 'Each DocumentGenerationProcess should reference one of the supplied fee Ids.');

        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'PHOCSInvoiceGenerationQueueable'];
        Assert.areEqual(1, jobs.size(), 'One PHOCSInvoiceGenerationQueueable job should have run.');
        Assert.areEqual('Completed', jobs[0].Status, 'The queueable job should have completed successfully.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of execute with an empty
*                  list, verifying the job completes without creating any
*                  DocumentGenerationProcess records.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void execute_WithEmptyList_CreatesNoInvoices_Test() {
        Test.startTest();
        System.enqueueJob(new PHOCSInvoiceGenerationQueueable(new List<Id>()));
        Test.stopTest();

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess should be created for an empty Id list.');
    }
}