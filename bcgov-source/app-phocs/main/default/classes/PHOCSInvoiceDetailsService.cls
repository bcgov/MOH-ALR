/**********************************************************************************************
* @Author: Accenture
* @Date: 2026-09-15
* @Description: Apex re-implementation of the PHOCSDRGetInvoiceDetails (Extract) and
*                PHOCSTransformInvoiceDetails (Transform) OmniStudio DataMappers. Given a
*                RegulatoryTrxnFee Id, retrieves the fee, its billing Account, that Account's
*                health-authority Account, its line items, and the default
*                PHOCSEnvironmentConfiguration__mdt record, then reshapes them into the exact
*                token names the PHOCSInvoiceTemplate Word document merges against.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                15 Sep -  EHIS-910          -  Deepak      -  Initial version, ported from OmniStudio DataMapper
                15 Sep -  EHIS-910          -  Deepak      -  added generateInvoicePdf, calling PHOCSDocumentGenerationService against the 'PHOCSInvoiceTemplate' DocumentTemplate
                15 Sep -  EHIS-910          -  Deepak      -  added a generateInvoicePdf(Id, InvoiceDetailsWrapper) overload for callers that already have a built wrapper
                15 Sep -  EHIS-910          -  Deepak      -  renamed wrapper fields to match the PHOCSInvoiceTemplate merge tokens exactly (case-sensitive); values were rendering blank because the JSON keys didn't match the template's {{Tokens}}
                15 Sep -  EHIS-910          -  Deepak      -  replaced InvoiceLineItemWrapper with a Map-based RTFItem, since 'Date' is a reserved Apex identifier and couldn't be used as a field name
                15 Sep -  EHIS-910          -  Deepak      -  builds and passes the invoice attachment title ({AccountName__c}_{Name}_Invoice) to PHOCSDocumentGenerationService
***********************************************************************************************/
public with sharing class PHOCSInvoiceDetailsService {

    // Health Authority label values checked by the Transform's IF_HA_* formulas
    private static final String HA_NORTHERN = 'Northern Health - NH';
    private static final String HA_INTERIOR = 'Interior Health - IH';
    private static final String HA_ISLAND = 'Island Health - Island';
    private static final String HA_FRASER = 'Fraser Health - FH';
    private static final String HA_VANCOUVER_COASTAL = 'Vancouver Coastal Health - VCH';

    private static final String DATE_FORMAT = 'dd-MMM-yyyy';

    /**
* @author Deepak
* @date 2026-09-15
* @description Builds one line item's token map for the PHOCSInvoiceTemplate's {{#RTFItem}}
*                 repeating section. A Map is used (rather than a typed wrapper class) because
*                 the template's "Date" token collides with Apex's reserved Date identifier.
* @param item the RegulatoryTrxnFeeItem to map.
* @return Map<String, Object> keyed by Date, Description, Rate, Amount.
*/
    private static Map<String, Object> buildLineItemMap(RegulatoryTrxnFeeItem item) {
        Map<String, Object> line = new Map<String, Object>();
        line.put('Date', (item.CreatedDate != null) ? item.CreatedDate.format(DATE_FORMAT) : null);
        line.put('Description', item.FeeType__c);
        line.put('Rate', item.FeeAmount);
        line.put('Amount', item.FeeAmount);
        return line;
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Final shaped output. Field names match the PHOCSInvoiceTemplate's {{Tokens}}
*                 exactly (case-sensitive) so the document generation merge can resolve them.
*/
    public class InvoiceDetailsWrapper {
        public String RegulatoryTrxnFeeName;
        public String DueDate;
        public String AccountNumber;
        public String RTB_AccountNameAddress;
        public String HAAddress;
        public String HAGSTNumber;
        public String HAPhone;
        public String HAFax;
        public String HAEmail;
        public String HAAddressInline;
        public Decimal RTFAmountPaid;
        public Decimal RTFBalanceOutstanding;
        public Decimal RTFTotalFeeAmount;
        public String HYP_OperatorPortalURL;
        public Boolean IF_HA_Northern;
        public Boolean IF_HA_Interior;
        public Boolean IF_HA_Island;
        public Boolean IF_HA_Fraser;
        public Boolean IF_HA_VancouverCoastal;
        public List<Map<String, Object>> RTFItem;
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Entry point. Runs the "Extract" queries for a RegulatoryTrxnFee record, then
*                 "Transforms" the results into an InvoiceDetailsWrapper, mirroring
*                 PHOCSDRGetInvoiceDetails followed by PHOCSTransformInvoiceDetails.
* @param regulatoryTrxnFeeId Id of the RegulatoryTrxnFee to build invoice details for.
* @return InvoiceDetailsWrapper populated invoice details, or null if the fee record could not be found.
*/
    public static InvoiceDetailsWrapper getInvoiceDetails(Id regulatoryTrxnFeeId) {
        if (regulatoryTrxnFeeId == null) {
            return null;
        }

        List<RegulatoryTrxnFee> feeRecords = [SELECT Id, Name, TotalFeeAmount, TotalFeePaid__c, OutstandingFeeAmount__c, DueDate, CreatedDate, FeeType__c, AccountId FROM RegulatoryTrxnFee WHERE Id = :regulatoryTrxnFeeId LIMIT 1];
        if (feeRecords.isEmpty()) {
            return null;
        }
        RegulatoryTrxnFee fee = feeRecords[0];

        List<RegulatoryTrxnFeeItem> feeItems = [SELECT Id, FeeAmount, FeeType__c, CreatedDate FROM RegulatoryTrxnFeeItem WHERE RegulatoryTrxnFeeId = :fee.Id];

        Account billingAccount = getBillingAccount(fee.AccountId);
        Account healthAuthorityAccount = (billingAccount != null && billingAccount.HierarchyHAId__c != null) ? getHealthAuthorityAccount(billingAccount.HierarchyHAId__c) : null;
        PHOCSEnvironmentConfiguration__mdt envConfig = getDefaultEnvironmentConfiguration();

        return transform(fee, billingAccount, healthAuthorityAccount, feeItems, envConfig);
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Second query step of the Extract: the fee's billing Account.
* @param accountId Id of the Account to retrieve.
* @return Account the billing Account record, or null if not found.
*/
    private static Account getBillingAccount(Id accountId) {
        if (accountId == null) {
            return null;
        }
        List<Account> accounts = [SELECT Id, Name, AccountNumberRTPrefixed__c, BillingStreet, BillingState, 
                                  BillingCity, BillingPostalCode, HierarchyHAId__c, HealthAuthority__c FROM Account WHERE Id = :accountId LIMIT 1];
        return accounts.isEmpty() ? null : accounts[0];
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Fourth query step of the Extract: the health-authority Account, resolved via
*                 the billing Account's HierarchyHAId__c.
* @param hierarchyHAId Id of the health-authority Account to retrieve.
* @return Account the health-authority Account record, or null if not found.
*/
    private static Account getHealthAuthorityAccount(Id hierarchyHAId) {
        List<Account> accounts = [SELECT Id, Name, HAGSTNumber__c, HAAddress__c, HAFax__c, HAPhone__c, HAEmail__c 
                                  FROM Account WHERE Id = :hierarchyHAId LIMIT 1];
        return accounts.isEmpty() ? null : accounts[0];
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Fifth query step of the Extract: the "Default" PHOCSEnvironmentConfiguration__mdt record.
* @return PHOCSEnvironmentConfiguration__mdt the default configuration record, or null if not found.
*/
    private static PHOCSEnvironmentConfiguration__mdt getDefaultEnvironmentConfiguration() {
        List<PHOCSEnvironmentConfiguration__mdt> configs = [SELECT OperatorPortalURL__c FROM PHOCSEnvironmentConfiguration__mdt 
                                                            WHERE DeveloperName = 'Default' LIMIT 1];
        return configs.isEmpty() ? null : configs[0];
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Applies the field renames, formulas, and health-authority flags that
*                 PHOCSTransformInvoiceDetails defines.
* @param fee the queried RegulatoryTrxnFee record.
* @param billingAccount the fee's billing Account, or null.
* @param healthAuthorityAccount the resolved health-authority Account, or null.
* @param feeItems the fee's RegulatoryTrxnFeeItem line items.
* @param envConfig the default PHOCSEnvironmentConfiguration__mdt record, or null.
* @return InvoiceDetailsWrapper the shaped output matching the Transform DataMapper.
*/
    private static InvoiceDetailsWrapper transform(RegulatoryTrxnFee fee, Account billingAccount, Account healthAuthorityAccount, List<RegulatoryTrxnFeeItem> feeItems, PHOCSEnvironmentConfiguration__mdt envConfig) {
        InvoiceDetailsWrapper result = new InvoiceDetailsWrapper();

        result.RegulatoryTrxnFeeName = fee.Name;
        result.DueDate = (fee.DueDate != null) ? fee.DueDate.format(DATE_FORMAT) : null;
        result.RTFAmountPaid = fee.TotalFeePaid__c;
        result.RTFBalanceOutstanding = fee.OutstandingFeeAmount__c;

        if (billingAccount != null) {
            result.AccountNumber = billingAccount.AccountNumberRTPrefixed__c;
            result.RTB_AccountNameAddress = formatAccountNameAddress(billingAccount);

            String ha = billingAccount.HealthAuthority__c;
            result.IF_HA_Northern = (ha == HA_NORTHERN);
            result.IF_HA_Interior = (ha == HA_INTERIOR);
            result.IF_HA_Island = (ha == HA_ISLAND);
            result.IF_HA_Fraser = (ha == HA_FRASER);
            result.IF_HA_VancouverCoastal = (ha == HA_VANCOUVER_COASTAL);
        }

        if (healthAuthorityAccount != null) {
            result.HAPhone = healthAuthorityAccount.HAPhone__c;
            result.HAGSTNumber = healthAuthorityAccount.HAGSTNumber__c;
            result.HAEmail = healthAuthorityAccount.HAEmail__c;
            result.HAFax = healthAuthorityAccount.HAFax__c;
            result.HAAddress = healthAuthorityAccount.HAAddress__c;
            result.HAAddressInline = formatAddressInline(healthAuthorityAccount.HAAddress__c);
        }

        if (envConfig != null) {
            result.HYP_OperatorPortalURL = envConfig.OperatorPortalURL__c;
        }

        result.RTFItem = new List<Map<String, Object>>();
        Decimal invoiceTotal = 0;
        for (RegulatoryTrxnFeeItem item : feeItems) {
            result.RTFItem.add(buildLineItemMap(item));
            invoiceTotal += (item.FeeAmount != null ? item.FeeAmount : 0);
        }
        result.RTFTotalFeeAmount = invoiceTotal;

        return result;
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Mirrors the Transform's CONCAT formula for RTB_AccountNameAddress:
*                 Name<br/>Street<br/>City, State<br/>PostalCode
* @param acc the billing Account to format.
* @return String the formatted, HTML-line-broken name and address.
*/
    private static String formatAccountNameAddress(Account acc) {
        return String.join(new List<String>{ acc.Name, acc.BillingStreet, acc.BillingCity + ', ' + acc.BillingState, acc.BillingPostalCode }, '<br/>');
    }

    /**
* @author Deepak
* @date 2026-09-15
* @description Mirrors the Transform's JOIN(SPLIT(HAAddress, "\n"), ", ") formula.
* @param haAddress the multi-line health-authority address to flatten.
* @return String the single-line, comma-separated address.
*/
    private static String formatAddressInline(String haAddress) {
        if (String.isBlank(haAddress)) {
            return haAddress;
        }
        return String.join(haAddress.split('\n'), ', ');
    }

    /**
* @author: Deepak
* @date: 2026-09-15
* @description: Builds the invoice details for a RegulatoryTrxnFee and submits them as a
*                  DocumentGenerationProcess request against the 'PHOCSInvoiceTemplate'
*                  DocumentTemplate, via the reusable PHOCSDocumentGenerationService.
* @param regulatoryTrxnFeeId Id of the RegulatoryTrxnFee to generate an invoice PDF for.
* @return Id the inserted DocumentGenerationProcess record's Id, or null if the fee record or
*             the 'PHOCSInvoiceTemplate' DocumentTemplate could not be found.
*/
    public static Id generateInvoicePdf(Id regulatoryTrxnFeeId) {
        InvoiceDetailsWrapper invoiceDetails = getInvoiceDetails(regulatoryTrxnFeeId);
        if (invoiceDetails == null) {
            return null;
        }
        return generateInvoicePdf(regulatoryTrxnFeeId, invoiceDetails);
    }

    /**
* @author: Deepak
* @date: 2026-09-15
* @description: Overload of generateInvoicePdf for callers that already have a built
*                  InvoiceDetailsWrapper (e.g. a trigger handler that assembled it separately)
*                  - submits it directly as a DocumentGenerationProcess request against the
*                  'PHOCSInvoiceTemplate' DocumentTemplate, skipping the getInvoiceDetails
*                  lookup.
* @param regulatoryTrxnFeeId Id of the RegulatoryTrxnFee the invoice PDF is for, used as the
*             DocumentGenerationProcess's ReferenceObject.
* @param invoiceDetails the already-built invoice details to serialize and submit.
* @return Id the inserted DocumentGenerationProcess record's Id, or null if invoiceDetails is
*             null or the 'PHOCSInvoiceTemplate' DocumentTemplate could not be found.
*/
    public static Id generateInvoicePdf(Id regulatoryTrxnFeeId, InvoiceDetailsWrapper invoiceDetails) {
        if (invoiceDetails == null) {
            return null;
        }
        String tokenDataJson = JSON.serialize(invoiceDetails);
        String documentTitle = buildInvoiceDocumentTitle(regulatoryTrxnFeeId);
        return generateInvoicePdf(regulatoryTrxnFeeId, invoiceDetails, documentTitle);
    }

    /**
* @author: Deepak
* @date: 2026-09-17
* @description: Generates invoice documents for multiple fees using bulk-loaded invoice data.
* @param regulatoryTrxnFeeIds RegulatoryTrxnFee Ids to generate invoice PDFs for.
* @return List<Id> inserted DocumentGenerationProcess record Ids, in input order where a fee exists.
*/
    public static List<Id> generateInvoicePdf(List<Id> regulatoryTrxnFeeIds) {
        List<Id> documentIds = new List<Id>();
        if (regulatoryTrxnFeeIds == null || regulatoryTrxnFeeIds.isEmpty()) {
            return documentIds;
        }

        Set<Id> feeIds = new Set<Id>(regulatoryTrxnFeeIds);
        Map<Id, RegulatoryTrxnFee> feesById = new Map<Id, RegulatoryTrxnFee>([
            SELECT Id, Name, TotalFeePaid__c, OutstandingFeeAmount__c, DueDate,
                   CreatedDate, AccountId, AccountName__c
            FROM RegulatoryTrxnFee
            WHERE Id IN :feeIds
        ]);

        if (feesById.isEmpty()) {
            return documentIds;
        }

        Map<Id, List<RegulatoryTrxnFeeItem>> itemsByFeeId = new Map<Id, List<RegulatoryTrxnFeeItem>>();
        for (RegulatoryTrxnFeeItem item : [
            SELECT Id, RegulatoryTrxnFeeId, FeeAmount, FeeType__c, CreatedDate
            FROM RegulatoryTrxnFeeItem
            WHERE RegulatoryTrxnFeeId IN :feesById.keySet()
        ]) {
            if (!itemsByFeeId.containsKey(item.RegulatoryTrxnFeeId)) {
                itemsByFeeId.put(item.RegulatoryTrxnFeeId, new List<RegulatoryTrxnFeeItem>());
            }
            itemsByFeeId.get(item.RegulatoryTrxnFeeId).add(item);
        }

        Set<Id> accountIds = new Set<Id>();
        for (RegulatoryTrxnFee fee : feesById.values()) {
            if (fee.AccountId != null) {
                accountIds.add(fee.AccountId);
            }
        }

        Map<Id, Account> billingAccountsById = new Map<Id, Account>();
        Set<Id> healthAuthorityIds = new Set<Id>();
        if (!accountIds.isEmpty()) {
            for (Account account : [
                SELECT Id, Name, AccountNumberRTPrefixed__c, BillingStreet, BillingState,
                       BillingCity, BillingPostalCode, HierarchyHAId__c, HealthAuthority__c
                FROM Account
                WHERE Id IN :accountIds
            ]) {
                billingAccountsById.put(account.Id, account);
                if (account.HierarchyHAId__c != null) {
                    healthAuthorityIds.add(account.HierarchyHAId__c);
                }
            }
        }

        Map<Id, Account> healthAuthorityAccountsById = new Map<Id, Account>();
        if (!healthAuthorityIds.isEmpty()) {
            healthAuthorityAccountsById = new Map<Id, Account>([
                SELECT Id, Name, HAGSTNumber__c, HAAddress__c, HAFax__c, HAPhone__c, HAEmail__c
                FROM Account
                WHERE Id IN :healthAuthorityIds
            ]);
        }

        PHOCSEnvironmentConfiguration__mdt envConfig = getDefaultEnvironmentConfiguration();
        for (Id feeId : regulatoryTrxnFeeIds) {
            RegulatoryTrxnFee fee = feesById.get(feeId);
            if (fee == null) {
                continue;
            }

            Account billingAccount = billingAccountsById.get(fee.AccountId);
            Account healthAuthorityAccount = billingAccount == null
                ? null
                : healthAuthorityAccountsById.get(billingAccount.HierarchyHAId__c);
            InvoiceDetailsWrapper invoiceDetails = transform(
                fee,
                billingAccount,
                healthAuthorityAccount,
                itemsByFeeId.containsKey(feeId)
                    ? itemsByFeeId.get(feeId)
                    : new List<RegulatoryTrxnFeeItem>(),
                envConfig
            );

            documentIds.add(generateInvoicePdf(
                feeId,
                invoiceDetails,
                buildInvoiceDocumentTitle(fee)
            ));
        }

        return documentIds;
    }

    private static Id generateInvoicePdf(
        Id regulatoryTrxnFeeId,
        InvoiceDetailsWrapper invoiceDetails,
        String documentTitle
    ) {
        String tokenDataJson = JSON.serialize(invoiceDetails);
        return PHOCSDocumentGenerationService.generateDocument(
            'PHOCSInvoiceTemplate',
            tokenDataJson,
            regulatoryTrxnFeeId,
            documentTitle
        );
    }

    /**
* @author: Deepak
* @date: 2026-09-15
* @description: Builds the invoice attachment's title: {AccountName__c}_{Name}_Invoice.
* @param regulatoryTrxnFeeId Id of the RegulatoryTrxnFee to build the title for.
* @return String the formatted title, or null if the fee record could not be found.
*/
    private static String buildInvoiceDocumentTitle(Id regulatoryTrxnFeeId) {
        List<RegulatoryTrxnFee> feeRecords = [SELECT Name, AccountName__c FROM RegulatoryTrxnFee WHERE Id = :regulatoryTrxnFeeId LIMIT 1];
        if (feeRecords.isEmpty()) {
            return null;
        }
        return buildInvoiceDocumentTitle(feeRecords[0]);
    }

    private static String buildInvoiceDocumentTitle(RegulatoryTrxnFee fee) {
        return fee.AccountName__c + '_' + fee.Name + '_Invoice';
    }
}