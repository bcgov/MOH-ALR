/**********************************************************************************************
* @Author:      Accenture
* @Date:        15 Sep 2026
* @Description: The purpose of this class is to cover code coverage of PHOCSInvoiceDetailsService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                15 Sep -  EHIS-910          -  Deepak      -  Initial version
                15 Sep -  EHIS-910          -  Deepak      -  updated wrapper field references to match the PHOCSInvoiceTemplate merge token renames
***********************************************************************************************/
@isTest
public class PHOCSInvoiceDetailsServiceTest {
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
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of getInvoiceDetails,
*                  verifying every renamed/formatted field, the health-authority flags, and a
*                  single line item's wrapper fields.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void getInvoiceDetails_PopulatesWrapperFields_ForSingleLineItemFee_Test() {
        Account billingAccount = [SELECT Id, Name, AccountNumberRTPrefixed__c, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL,
            DueDate = Datetime.newInstance(2026, 4, 11, 19, 0, 0)
        );
        insert fee;

        RegulatoryTrxnFeeItem item = new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = fee.Id,
            Name = 'Test Line Item',
            FeeAmount = 250
        );
        insert item;

        fee = [SELECT Id, Name, DueDate, TotalFeePaid__c, OutstandingFeeAmount__c FROM RegulatoryTrxnFee WHERE Id = :fee.Id LIMIT 1];
        item = [SELECT Id, FeeAmount, FeeType__c, CreatedDate FROM RegulatoryTrxnFeeItem WHERE Id = :item.Id LIMIT 1];

        Test.startTest();
        PHOCSInvoiceDetailsService.InvoiceDetailsWrapper result = PHOCSInvoiceDetailsService.getInvoiceDetails(fee.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Wrapper should be populated for an existing RegulatoryTrxnFee.');
        Assert.areEqual(fee.Name, result.RegulatoryTrxnFeeName, 'RegulatoryTrxnFeeName should match the fee record.');
        Assert.areEqual(fee.DueDate.format('dd-MMM-yyyy'), result.DueDate, 'DueDate should be formatted as dd-MMM-yyyy.');
        Assert.areEqual(fee.TotalFeePaid__c, result.RTFAmountPaid, 'RTFAmountPaid should match TotalFeePaid__c.');
        Assert.areEqual(fee.OutstandingFeeAmount__c, result.RTFBalanceOutstanding, 'RTFBalanceOutstanding should match OutstandingFeeAmount__c.');

        Assert.areEqual(billingAccount.AccountNumberRTPrefixed__c, result.AccountNumber, 'AccountNumber should match AccountNumberRTPrefixed__c.');

        String expectedNameAddress = String.join(new List<String>{ billingAccount.Name, billingAccount.BillingStreet, billingAccount.BillingCity + ', ' + billingAccount.BillingState, billingAccount.BillingPostalCode }, '<br/>');
        Assert.areEqual(expectedNameAddress, result.RTB_AccountNameAddress, 'RTB_AccountNameAddress should be the concatenated, line-broken address.');

        Assert.areEqual(true, result.IF_HA_Northern, 'IF_HA_Northern should be true for Northern Health - NH.');
        Assert.areEqual(false, result.IF_HA_Interior, 'IF_HA_Interior should be false.');
        Assert.areEqual(false, result.IF_HA_Island, 'IF_HA_Island should be false.');
        Assert.areEqual(false, result.IF_HA_Fraser, 'IF_HA_Fraser should be false.');
        Assert.areEqual(false, result.IF_HA_VancouverCoastal, 'IF_HA_VancouverCoastal should be false.');

        // No HA-account hierarchy is wired up yet, so the healthAuthorityAccount branch in
        // getInvoiceDetails has nothing to resolve and these stay null.
        Assert.isNull(result.HAPhone, 'HAPhone should be null without a resolvable health-authority Account.');
        Assert.isNull(result.HAGSTNumber, 'HAGSTNumber should be null without a resolvable health-authority Account.');
        Assert.isNull(result.HAEmail, 'HAEmail should be null without a resolvable health-authority Account.');
        Assert.isNull(result.HAFax, 'HAFax should be null without a resolvable health-authority Account.');
        Assert.isNull(result.HAAddress, 'HAAddress should be null without a resolvable health-authority Account.');
        Assert.isNull(result.HAAddressInline, 'HAAddressInline should be null without a resolvable health-authority Account.');

        Assert.areEqual(1, result.RTFItem.size(), 'RTFItem should contain one wrapper for the single line item.');
        Map<String, Object> lineItem = result.RTFItem[0];
        Assert.areEqual(item.FeeAmount, (Decimal) lineItem.get('Rate'), 'Rate should equal FeeAmount.');
        Assert.areEqual(item.FeeAmount, (Decimal) lineItem.get('Amount'), 'Amount should equal FeeAmount.');
        Assert.areEqual(item.FeeType__c, (String) lineItem.get('Description'), 'Description should match FeeType__c.');
        Assert.areEqual(item.CreatedDate.format('dd-MMM-yyyy'), (String) lineItem.get('Date'), 'Date should be formatted as dd-MMM-yyyy.');
        Assert.areEqual(item.FeeAmount, result.RTFTotalFeeAmount, 'RTFTotalFeeAmount should equal the single line item FeeAmount.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of getInvoiceDetails when a
*                  fee has multiple line items, verifying RTFTotalFeeAmount sums every item.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void getInvoiceDetails_SumsAllLineItems_ForMultiLineItemFee_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL,
            DueDate = Datetime.newInstance(2026, 7, 24, 19, 0, 0)
        );
        insert fee;

        RegulatoryTrxnFeeItem itemA = new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = fee.Id,
            Name = 'Test Line Item A',
            FeeAmount = 234
        );
        RegulatoryTrxnFeeItem itemB = new RegulatoryTrxnFeeItem(
            RegulatoryTrxnFeeId = fee.Id,
            Name = 'Test Line Item B',
            FeeAmount = 234
        );
        insert new List<RegulatoryTrxnFeeItem>{ itemA, itemB };

        List<RegulatoryTrxnFeeItem> items = [SELECT Id, FeeAmount FROM RegulatoryTrxnFeeItem WHERE RegulatoryTrxnFeeId = :fee.Id];

        Test.startTest();
        PHOCSInvoiceDetailsService.InvoiceDetailsWrapper result = PHOCSInvoiceDetailsService.getInvoiceDetails(fee.Id);
        Test.stopTest();

        Decimal expectedTotal = 0;
        for (RegulatoryTrxnFeeItem item : items) {
            expectedTotal += item.FeeAmount;
        }

        Assert.isNotNull(result, 'Wrapper should be populated for an existing RegulatoryTrxnFee.');
        Assert.areEqual(items.size(), result.RTFItem.size(), 'RTFItem should contain one wrapper per line item.');
        Assert.areEqual(expectedTotal, result.RTFTotalFeeAmount, 'RTFTotalFeeAmount should be the sum of all line item FeeAmounts.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the not-found path,
*                  verifying null is returned when no RegulatoryTrxnFee matches the given Id.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void getInvoiceDetails_ReturnsNull_WhenFeeNotFound_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert fee;
        Id deletedFeeId = fee.Id;
        delete fee;

        Test.startTest();
        PHOCSInvoiceDetailsService.InvoiceDetailsWrapper result = PHOCSInvoiceDetailsService.getInvoiceDetails(deletedFeeId);
        Test.stopTest();

        Assert.isNull(result, 'A null wrapper should be returned when no RegulatoryTrxnFee matches the Id.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of generateInvoicePdf,
*                  verifying the DocumentGenerationProcess request carries the
*                  RegulatoryTrxnFee's own Id as ReferenceObject.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateInvoicePdf_CreatesRequest_WithFeeIdAsReferenceObject_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert fee;
        fee = [SELECT Id, Name FROM RegulatoryTrxnFee WHERE Id = :fee.Id LIMIT 1];

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
        linkTemplateContentVersion(template.Id, templateContentVersion.Id);

        Test.startTest();
        Id resultId = PHOCSInvoiceDetailsService.generateInvoicePdf(fee.Id);
        Test.stopTest();

        Assert.isNotNull(resultId, 'A DocumentGenerationProcess Id should be returned when the fee and template both exist.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id, Type, ReferenceObject, TokenData, RequestText, DocumentTemplateId FROM DocumentGenerationProcess];
        Assert.areEqual(1, generatedProcesses.size(), 'One DocumentGenerationProcess record should be created.');
        Assert.areEqual('GenerateAndConvert', generatedProcesses[0].Type, 'Type should be GenerateAndConvert.');
        Assert.areEqual(fee.Id, generatedProcesses[0].ReferenceObject, 'ReferenceObject should be the RegulatoryTrxnFee Id.');
        Assert.areEqual(template.Id, generatedProcesses[0].DocumentTemplateId, 'DocumentTemplateId should match the PHOCSInvoiceTemplate.');
        Assert.isTrue(generatedProcesses[0].RequestText.contains(templateContentVersion.Id), 'RequestText should carry the resolved templateContentVersionId.');

        PHOCSInvoiceDetailsService.InvoiceDetailsWrapper tokenData = (PHOCSInvoiceDetailsService.InvoiceDetailsWrapper) JSON.deserialize(generatedProcesses[0].TokenData, PHOCSInvoiceDetailsService.InvoiceDetailsWrapper.class);
        Assert.areEqual(fee.Name, tokenData.RegulatoryTrxnFeeName, 'The serialized TokenData should reflect the fee used to build it.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: Links a test ContentVersion to a test DocumentTemplate via
*                  DocumentTemplateContentDoc, since generateDocument resolves
*                  templateContentVersionId through that junction rather than by
*                  ContentVersion.Title alone.
* @param documentTemplateId Id of the DocumentTemplate to link.
* @param contentVersionId Id of the ContentVersion whose ContentDocument should be linked.
*/
    private static void linkTemplateContentVersion(Id documentTemplateId, Id contentVersionId) {
        ContentVersion contentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
        DocumentTemplateContentDoc templateContentDocLink = new DocumentTemplateContentDoc(
            Name = 'PHOCSInvoiceTemplate',
            DocumentTemplateId = documentTemplateId,
            ContentDocumentId = contentVersion.ContentDocumentId
        );
        insert templateContentDocLink;
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the
*                  generateInvoicePdf(Id, InvoiceDetailsWrapper) overload, verifying a
*                  caller-supplied wrapper is submitted directly without re-running
*                  getInvoiceDetails.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateInvoicePdf_WrapperOverload_SubmitsSuppliedWrapper_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert fee;

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
        linkTemplateContentVersion(template.Id, templateContentVersion.Id);

        PHOCSInvoiceDetailsService.InvoiceDetailsWrapper suppliedWrapper = new PHOCSInvoiceDetailsService.InvoiceDetailsWrapper();
        suppliedWrapper.RegulatoryTrxnFeeName = 'Caller-Supplied-Fee-Name';

        Test.startTest();
        Id resultId = PHOCSInvoiceDetailsService.generateInvoicePdf(fee.Id, suppliedWrapper);
        Test.stopTest();

        Assert.isNotNull(resultId, 'A DocumentGenerationProcess Id should be returned when the template exists.');

        DocumentGenerationProcess generatedProcess = [SELECT Id, ReferenceObject, TokenData FROM DocumentGenerationProcess LIMIT 1];
        Assert.areEqual(fee.Id, generatedProcess.ReferenceObject, 'ReferenceObject should be the supplied RegulatoryTrxnFee Id.');

        PHOCSInvoiceDetailsService.InvoiceDetailsWrapper tokenData = (PHOCSInvoiceDetailsService.InvoiceDetailsWrapper) JSON.deserialize(generatedProcess.TokenData, PHOCSInvoiceDetailsService.InvoiceDetailsWrapper.class);
        Assert.areEqual('Caller-Supplied-Fee-Name', tokenData.RegulatoryTrxnFeeName, 'TokenData should reflect the caller-supplied wrapper, not a freshly queried one.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the
*                  generateInvoicePdf(Id, InvoiceDetailsWrapper) overload's null-wrapper path.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateInvoicePdf_WrapperOverload_ReturnsNull_WhenWrapperIsNull_Test() {
        Test.startTest();
        Id resultId = PHOCSInvoiceDetailsService.generateInvoicePdf(null, null);
        Test.stopTest();

        Assert.isNull(resultId, 'A null Id should be returned when the supplied wrapper is null.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess record should be created when the supplied wrapper is null.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of generateInvoicePdf when
*                  no RegulatoryTrxnFee matches the given Id, verifying null is returned and no
*                  DocumentGenerationProcess is created.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateInvoicePdf_ReturnsNull_WhenFeeNotFound_Test() {
        Account billingAccount = [SELECT Id FROM Account WHERE Name = 'ABC ChildCare Inc' LIMIT 1];

        RegulatoryTrxnFee fee = new RegulatoryTrxnFee(
            AccountId = billingAccount.Id,
            RecordTypeId = RT_PHOCS_NON_DAIRY_TXN_FEE,
            Status__c = 'Due',
            FeeType__c = FEE_TYPE_RENEWAL
        );
        insert fee;
        Id deletedFeeId = fee.Id;
        delete fee;

        DocumentTemplate template = new DocumentTemplate(
            Name = 'PHOCSInvoiceTemplate',
            Type = 'MicrosoftWord',
            TokenMappingType = 'JSON',
            TokenMappingMethodType = 'OmniDataTransform'
        );
        insert template;

        Test.startTest();
        Id resultId = PHOCSInvoiceDetailsService.generateInvoicePdf(deletedFeeId);
        Test.stopTest();

        Assert.isNull(resultId, 'A null Id should be returned when the fee record cannot be found.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess record should be created when the fee is not found.');
    }
}