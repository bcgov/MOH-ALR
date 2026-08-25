/**
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
* Class Name      : PHOCSBLARenewalManagementController
* Author          : Accenture
* Created Date    : Aug 18, 2026
* Last Modified By: 
* Last Modified On: Aug 18, 2026
* Description     : This class implements for handling the BL Fees Renewal 
*  
* Change History  :
*  Date          │   Author     │   Change
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*  Aug 18, 2026  │ <YourName>   │ Initial version
* ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
*/

public with sharing class PhocsBlaRenewalManagementController {
    
    /*
    * ============================================================
    * ORG-SPECIFIC CONFIGURATION
    * ============================================================
    *
    * Replace these API names with the actual fields in your org.
    */
    
    // Account fields
    private static final String ACCOUNT_TYPE_FIELD = 'Type';    
    private static final String POSTAL_CODE_FIELD = 'Physical_Address__PostalCode__s';    
    private static final String CATEGORY_L1_FIELD = 'CategoryL1__c';    
    private static final String CATEGORY_L2_FIELD = 'CategoryL2__c';    
    private static final String OPERATING_MONTHS_FIELD = 'OperatingMonths__c';    
    private static final String MULTIPLE_PREMISE_FIELD = 'MultiplePremiseFacility__c';    
    private static final String PREMISE_ROLE_FIELD = 'PremiseRole__c';    
    
       
    
    // Regulatory Transaction Fee
    
    private static final String RTF_OBJECT ='RegulatoryTrxnFee';    
    private static final String RTF_ACCOUNT_FIELD ='AccountId';    
    private static final String RTF_PARENT_RECORD_FIELD = 'ParentRecordId';
    private static final String RTF_PARENT_BLA_NAME_FIELD = 'ParentRecord.Name';    
    private static final String RTF_STATUS_FIELD = 'Status__c';
    private static final String RTF_FEETYPE_FIELD ='FeeType__c';
    private static final String BL_STATUS_FIELD ='Active';
    private static final String RTF_FEETYPE_RENEWAL ='Renewal';
    private static final String RTF_STATUS_DRAFT ='Draft';
    
    
    // Regulatory Transaction Fee Item
    private static final String RTFI_OBJECT = 'RegulatoryTrxnFeeItem';    
    private static final String RTFI_PARENT_FIELD = 'RegulatoryTrxnFeeId';    
    private static final String RTFI_NAME_FIELD = 'Name';    
    private static final String RTFI_AMOUNT_FIELD ='FeeAmount';
    private static final Set<String> ACCOUNTTYPES= new Set<string>{'Food','Drinking water','Recreational water'};
        
    private static final String[] LICENSETYPES= new string[]{'Drinking Water Operating Permit','Food Premises Operating Permit','Pool Operating Permit'};
    
    // Record typeIds
    private static final Id RTFItemRecordTypeId = Schema.SObjectType.RegulatoryTrxnFeeItem.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFeeItem').getRecordTypeId();
    private static final Id RTFRecordTypeId = Schema.SObjectType.RegulatoryTrxnFee.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFee').getRecordTypeId();
    private static final Id BLARecordTypeId = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('OperatingPermitApplication').getRecordTypeId();
    
    
    // ============================================================
    // WRAPPERS
    // ============================================================
    
    public class GenerationResponse {
        @AuraEnabled public List<AccountRow> records;
        @AuraEnabled public List<PicklistOption> accountTypeOptions;
        @AuraEnabled public List<PicklistOption> premiseRoleOptions;
    }
    
    public class SendResponse {
        @AuraEnabled public List<SendRow> records;
        @AuraEnabled public List<PicklistOption> accountTypeOptions;
        @AuraEnabled public List<PicklistOption> premiseRoleOptions;
    }
    
    public class AccountRow {
        @AuraEnabled public Id Id;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        
        @AuraEnabled public Id parentAccountId;
        @AuraEnabled public String parentAccountUrl;
        @AuraEnabled public String parentAccountName;
        
        @AuraEnabled public String postalCode;
        @AuraEnabled public String categoryL1;
        @AuraEnabled public String categoryL2;
        @AuraEnabled public String operatingMonths;
        @AuraEnabled public Boolean multiplePremise;
        @AuraEnabled public String premiseRole;
    }
    
    public class SendRow {
        @AuraEnabled public Id Id;
        
        @AuraEnabled public String parentAccountName;
        @AuraEnabled public String parentAccountUrl;
        
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String postalCode;
        
        @AuraEnabled public String blaId;
        @AuraEnabled public String blaName;
        @AuraEnabled public String blaUrl;
        @AuraEnabled public String feeId;
        @AuraEnabled public String feeName;
        @AuraEnabled public Decimal feeAmount;
        @AuraEnabled public Boolean multiplePremise;
        @AuraEnabled public String premiseRole;
    }
    
    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        
        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
    
    
    // ============================================================
    // RENEWAL GENERATION
    // ============================================================
    
    @AuraEnabled
    public static GenerationResponse getGenerationAccounts(String accountType,Boolean multiplePremise){
        String accountStatus='Open';
        GenerationResponse response = new GenerationResponse();
        response.records = new List<AccountRow>();
        response.accountTypeOptions = getAccountTypeOptions();
        response.premiseRoleOptions = getPremiseRoleOptions();
        
        String soql = 'SELECT Id, Name, Parent.Name, Type, ' +
        POSTAL_CODE_FIELD + ', ' +
        CATEGORY_L1_FIELD + ', ' +
        CATEGORY_L2_FIELD + ', ' +
        OPERATING_MONTHS_FIELD + ', ' +
        MULTIPLE_PREMISE_FIELD + ', ' +
        PREMISE_ROLE_FIELD +
        ' FROM Account';
        
        List<String> conditions = new List<String>();
        
        // account status open
        conditions.add('Status__c = :accountStatus');
        
        if (String.isNotBlank(accountType)) {
            conditions.add('Type = :accountType');
        }
        
        if (multiplePremise == true) {
            conditions.add( MULTIPLE_PREMISE_FIELD + ' = true');
        }
        
        if (!conditions.isEmpty()) {
            soql += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        // Default sort: Parent Account ascending.
        soql += ' ORDER BY Parent.Name ASC NULLS FIRST, Name ASC';
        
        List<Account> accounts = Database.query(soql);
        
        Map<Id,Account> acctMap = new Map<Id,Account>();
        acctMap.putAll(accounts);
        
        List<Id> validAcctIds = new List<Id>();
        List<Account> validAccounts = new List<Account>();
        if(accounts.size()>0){
            validAcctIds = hasBLAhasvalidBL(new List<Id>(acctMap.keySet()));
            for(Id acctId:validAcctIds){
                validAccounts.add(acctMap.get(acctId));
            }            
        }
        
        for (Account account : validAccounts) {
            AccountRow row = new AccountRow();
            
            row.Id = account.Id;
            
            if (account.Parent != null) {
                row.parentAccountId = account.Parent.Id;
                row.parentAccountName = account.Parent.Name;
                
                // Clickable Parent Account URL
                row.parentAccountUrl = '/lightning/r/Account/' + account.Parent.Id +'/view';
            } else {
                row.parentAccountName = '';
                row.parentAccountUrl = null;
            }
            
            row.accountName = account.Name;
            //Clickable Account URL
            row.accountUrl ='/lightning/r/Account/' + account.Id +'/view';
            row.postalCode = (String) account.get(POSTAL_CODE_FIELD);
            row.categoryL1 = (String) account.get(CATEGORY_L1_FIELD);
            row.categoryL2 = (String) account.get(CATEGORY_L2_FIELD);
            row.operatingMonths = (String)account.get(OPERATING_MONTHS_FIELD);
            row.multiplePremise = toBoolean(account.get(MULTIPLE_PREMISE_FIELD));
            row.premiseRole = (String) account.get(PREMISE_ROLE_FIELD);
            response.records.add(row);
        }
        return response;
    }
    
    // ============================================================
    // Get the BLA of accounts which has eligible BL
    // ============================================================
    @AuraEnabled 
    public static List<Id> hasBLAhasvalidBL(List<Id> acctIds){
        List<Id> blaValidaccIds = new List<Id>();
        List<Id> validblaIds = new List<Id>();
        Set<Id> idSet = new Set<Id>();
        Integer currentYear = Date.today().year();
        String RenewalYear = String.valueOf(Date.today().year()+1);
        try{
            for(BusinessLicenseApplication bla:[SELECT Id,
                Name,AccountId,
                LicensePermitName.Status 
                FROM BusinessLicenseApplication 
                where LicenseType.name in :LICENSETYPES AND
                LicensePermitName.Status='Active' AND 
                accountId =:acctIds]){
                    blaValidaccIds.add(bla.AccountId);
                    validblaIds.add(bla.id);
                }
                idSet = new Set<Id>(blaValidaccIds);
                
                if(idSet.size()>0){
                    for(RegulatoryTrxnFee hasRenewalrtf:[SELECT Id,
                        AccountId,
                        FeeType__c, 
                        RenewalYear__c 
                        FROM RegulatoryTrxnFee 
                        WHERE AccountId =:blaValidaccIds
                        AND FeeType__c='Renewal'
                        AND RenewalYear__c=:RenewalYear]){
                            idSet.remove(hasRenewalrtf.AccountId);
                        }
                                                 
                    }
                }catch(QueryException qe){
                    throw new QueryException('Error occured while querying the records.');
                }
                
                return new List<Id>(idSet);
            }
            
            // ============================================================
            // GENERATE RENEWAL RTF + RTFI
            // ============================================================
            
 @AuraEnabled
public static OperationResponse generateRenewalRecords(List<Id> accountIds) {
    try {
        Date today = Date.today();
        Integer targetRYear = Date.today().year();
        
        Map<String, PHOCS_GenerateApplicationFees__mdt> feeMap =
        PHOCS_GenerateApplicationFees__mdt.getall();
        
        if (today.month() > 4 ||
        (today.month() == 4 && today.day() > 1)) {
            targetRYear++;
        }
        
        if (accountIds == null || accountIds.isEmpty()) {
            return new OperationResponse(
            false,
            'Please select at least one account.'
            );
        }
        
        Map<String, Object> bindVars = new Map<String, Object>{
    'blStatus' => BL_STATUS_FIELD,
    'recordTypeId' => BLARecordTypeId,
    'licenseTypes' => LICENSETYPES,
    'accountIds' => accountIds
};

String accountSoql =
    'SELECT Id, Name,' +
    '(SELECT Id, PoolAream2__c, Status FROM Assets ' +
    ' WHERE Status = :blStatus LIMIT 1),' +
    '(SELECT Id, Status, ClosedDate__c, LicenseType.Name,' +
    ' Account.Type, Account.CategoryL2__c,' +
    ' Account.NumberOfSeats__c, Account.NoofConnections__c,' +
    ' AccountId, LicensePermitName.Status' +
    ' FROM BusinessLicenseApplicationAccount' +
    ' WHERE LicensePermitName.Status = :blStatus' +
    ' AND RecordTypeId = :recordTypeId' +
    ' AND LicenseType.Name IN :licenseTypes' +
    ' AND ClosedDate__c != NULL' +
    ' ORDER BY ClosedDate__c DESC LIMIT 1)' +
    ' FROM Account WHERE Id IN :accountIds';

List<Account> accounts =
    (List<Account>)Database.queryWithBinds(
        accountSoql,
        bindVars,
        AccessLevel.USER_MODE
    );

        
        if (accounts.isEmpty()) {
            return new OperationResponse(
            false,
            'No valid accounts were selected.'
            );
        }
        
        List<BusinessLicenseApplication> applications =
        new List<BusinessLicenseApplication>();
        
        Map<Id, Decimal> mapBlaIdPoolArea =
        new Map<Id, Decimal>();
        
        for (Account acc : accounts) {
            if (!acc.BusinessLicenseApplicationAccount.isEmpty()) {
                BusinessLicenseApplication bla =
                acc.BusinessLicenseApplicationAccount[0];
                
                applications.add(bla);
                
                if (!acc.Assets.isEmpty() &&
                acc.Assets[0].PoolAream2__c != null) {
                    
                    mapBlaIdPoolArea.put(
                    bla.Id,
                    acc.Assets[0].PoolAream2__c
                    );
                }
            }
        }
        
        if (applications.isEmpty()) {
            return new OperationResponse(
            false,
            'No eligible Business License Applications were found for the selected accounts.'
            );
        }
        
        List<PHOCS_GenerateApplicationFees__mdt> feeList =
        [
        SELECT Amount__c,
        CategoryString__c,
        ConnectionString__c,
        FeeName__c,
        LicenseType__c,
        MetricType__c,
        PoolAreaString__c,
        PoolMinArea__c,
        ProRateFees__c,
        RTFIFeeType__c,
        SeatsString__c
        FROM PHOCS_GenerateApplicationFees__mdt
        ];
        
        List<RegulatoryTrxnFee> parentFeesToInsert =
        new List<RegulatoryTrxnFee>();
        
        List<RegulatoryTrxnFeeItem> childFeeItemsToInsert =
        new List<RegulatoryTrxnFeeItem>();
        
        Map<Id, PHOCS_GenerateApplicationFees__mdt> blaFeeMap =
        new Map<Id, PHOCS_GenerateApplicationFees__mdt>();
        
        for (BusinessLicenseApplication bla : applications) {
            
            PHOCS_GenerateApplicationFees__mdt feeData =
            getRenewalFeeAmount(
            feeList,
            bla,
            mapBlaIdPoolArea
            );
            
            if (feeData != null) {
                
                blaFeeMap.put(bla.Id, feeData);
                
                RegulatoryTrxnFee newFee =
                new RegulatoryTrxnFee();
                
                newFee.ParentRecordId = bla.Id;
                newFee.RecordTypeId = RTFRecordTypeId;
                newFee.Status__c = 'Draft';
                newFee.FeeType__c = 'Renewal';
                newFee.DueDate = DateTime.newInstance(targetRYear, 4, 1,0,0,0);
                newFee.RenewalYear__c =
                String.valueOf(targetRYear);
                newFee.AccountId = bla.AccountId;
                
                parentFeesToInsert.add(newFee);
            }
        }
        
        if (parentFeesToInsert.isEmpty()) {
            return new OperationResponse(
            false,
            'No renewal fee records could be generated for the selected accounts.'
            );
        }
        
        Database.SaveResult[] feeResults =
        Database.insert(parentFeesToInsert, false);
        
        Integer successfulFees = 0;
        
        for (Database.SaveResult result : feeResults) {
            if (result.isSuccess()) {
                successfulFees++;
            } else {
                return new OperationResponse(
                false,
                'Unable to generate renewal fees: ' +
                result.getErrors()[0].getMessage()
                );
            }
        }
        
        for (RegulatoryTrxnFee parentFee : parentFeesToInsert) {
            
            PHOCS_GenerateApplicationFees__mdt feeData =
            blaFeeMap.get(parentFee.ParentRecordId);
            
            if (feeData == null) {
                continue;
            }
            
            RegulatoryTrxnFeeItem newFeeItem =
            new RegulatoryTrxnFeeItem();
            
            newFeeItem.RegulatoryTrxnFeeId = parentFee.Id;
            newFeeItem.RecordTypeId = RTFItemRecordTypeId;
            newFeeItem.Status__c = 'Due';
            newFeeItem.FeeType__c = feeData.RTFIFeeType__c;
            newFeeItem.Name = feeData.FeeName__c;
            newFeeItem.FeeAmount = feeData.Amount__c;
            
            childFeeItemsToInsert.add(newFeeItem);
        }
        
        if (!childFeeItemsToInsert.isEmpty()) {
            
            Database.SaveResult[] itemResults =
            Database.insert(childFeeItemsToInsert, false);
            
            for (Database.SaveResult result : itemResults) {
                
                if (!result.isSuccess()) {
                    return new OperationResponse(
                    false,
                    'Renewal fee was created, but the fee item could not be created: ' +
                    result.getErrors()[0].getMessage()
                    );
                }
            }
        }
        
        return new OperationResponse(
        true,
        successfulFees +
        ' Renewal(s) Generated Successfully.'
        );
        
    } catch (Exception e) {
        
        System.debug(
        'generateRenewalRecords error: ' +
        e.getMessage()
        );
        
        return new OperationResponse(
        false,
        'Renewal generation failed: ' + e.getMessage()
        );
    }
}
/*
* This block is for the implementation with the actual BLA renewal
* fee-calculation rule.
*/
private static PHOCS_GenerateApplicationFees__mdt getRenewalFeeAmount(List<PHOCS_GenerateApplicationFees__mdt> feeList, 
BusinessLicenseApplication bla,Map<Id,Decimal> mapBlaIdPoolArea) {
    for (PHOCS_GenerateApplicationFees__mdt m : feeList) {        
        if (m.LicenseType__c != bla.LicenseType.Name) continue;
        
        // 1. Drinking Water Logic Check
        if (bla.LicenseType.Name == 'Drinking Water Operating Permit') {                
            if (m.MetricType__c=='NoofConnections__c' && m.ConnectionString__c != null &&  m.ConnectionString__c == bla.Account.NoofConnections__c) {
                
                return m;                    
            }
        }
        // 2. Food Premise Logic Check
        else if (bla.LicenseType.Name == 'Food Premises Operating Permit') {
            String seats = bla.Account.NumberOfSeats__c;                
            // Check Mobile Unit condition
            if (m.MetricType__c == 'CategoryL2__c' && bla.Account.Type == 'Food' && 
            (bla.Account.CategoryL2__c == 'Mobile Type B' || bla.Account.CategoryL2__c == 'Mobile Type C')) {
                
                return m;
                
            }
            // Check Seating conditions
            if (m.MetricType__c == 'NumberOfSeats__c' && seats != null && seats ==m.SeatsString__c) {
                
                return m;                    
            }
        }
        // 3. Pool Logic Check
        else if (bla.LicenseType.Name == 'Pool Operating Permit') {
            Decimal area =mapBlaIdPoolArea.get(bla.Id);
            if (m.MetricType__c =='PoolAream2__c' && area != null && area >= m.PoolMinArea__c && (m.PoolAreaString__c == null || area <= m.PoolAreaString__c)) {
                
                return m;                
            }
        }            
    }
    return null;
}               
                
// ============================================================
// SEND FEEs for  RENEWALS
// ============================================================

@AuraEnabled
public static SendResponse getSendRenewals(
String type,
String feeName,
Boolean multiplePremise,
String premiseRole
) {
    SendResponse response = new SendResponse();
    
    response.records = new List<SendRow>();
    response.accountTypeOptions = getAccountTypeOptions();
    response.premiseRoleOptions = getPremiseRoleOptions();
    
    /*
    * RTF query.
    *
    * Adjust the RTF account/parent/status fields if the actual
    * Salesforce object in your org differs.
    */
    String rtfSoql = 'SELECT Id, ' + RTF_ACCOUNT_FIELD + ', ' +
    RTF_PARENT_RECORD_FIELD + ', ' + RTF_PARENT_BLA_NAME_FIELD + ', ' +
    RTF_STATUS_FIELD + ' FROM ' + RTF_OBJECT +
    ' WHERE '+RTF_STATUS_FIELD + ' = :RTF_STATUS_DRAFT'+
    ' AND '+ RTF_FEETYPE_FIELD + ' = :RTF_FEETYPE_RENEWAL';  
    
    Schema.SObjectType rtfType = Schema.getGlobalDescribe().get(RTF_OBJECT);
    
    if (rtfType == null) {
        throw new AuraHandledException(
        'Object ' + RTF_OBJECT + ' does not exist in this org.'
        );
    }
    
    List<SObject> fees =
    Database.query(rtfSoql);
    
    if (fees.isEmpty()) {
        return response;
    }
    
    Set<Id> accountIds = new Set<Id>();
    Set<Id> feeIds = new Set<Id>();
    
    for (SObject fee : fees) {
        Object accountId = fee.get(RTF_ACCOUNT_FIELD);
        
        if (accountId != null) {
            accountIds.add((Id) accountId);
        }
        
        feeIds.add((Id) fee.get('Id'));
    }
    
    Map<Id, Account> accounts = getAccounts(accountIds);
    
    /*
    * Query RTFI separately instead of relying on an assumed
    * child relationship name.
    */
    String itemSoql =
    'SELECT Id, ' +
    RTFI_PARENT_FIELD + ', ' +
    RTFI_NAME_FIELD + ', ' +
    RTFI_AMOUNT_FIELD +
    ' FROM ' + RTFI_OBJECT +
    ' WHERE ' + RTFI_PARENT_FIELD + ' IN :feeIds';
    
    Schema.SObjectType itemType =
    Schema.getGlobalDescribe().get(RTFI_OBJECT);
    
    if (itemType == null) {
        throw new AuraHandledException(
        'Object ' + RTFI_OBJECT + ' does not exist in this org.'
        );
    }
    
    List<SObject> items = Database.query(itemSoql);
    
    Map<Id, SObject> itemByFee = new Map<Id, SObject>();
    
    for (SObject item : items) {
        Id feeId = (Id) item.get(RTFI_PARENT_FIELD);
        
        if (!itemByFee.containsKey(feeId)) {
            itemByFee.put(feeId, item);
        }
    }
    
    for (SObject fee : fees) {
        Id feeId = (Id) fee.get('Id');
        
        Id accountId = (Id) fee.get(RTF_ACCOUNT_FIELD);
        
        Account account = accounts.get(accountId);
        
        if (account == null) {
            continue;
        }
        
        String accountType = account.Type;
        String currentPremiseRole = (String) account.get(PREMISE_ROLE_FIELD);
        Boolean currentMultiplePremise = toBoolean(account.get(MULTIPLE_PREMISE_FIELD));
        
        /*
        * Apply filters.
        */
        if (String.isNotBlank(type) && accountType != type) {
            continue;
        }
        
        if (multiplePremise == true && currentMultiplePremise != true) {
            continue;
        }
        
        if (String.isNotBlank(premiseRole) && currentPremiseRole != premiseRole) {
            continue;
        }
        
        SObject item = itemByFee.get(feeId);
        
        String currentFeeName = '';
        Decimal currentFeeAmount = 0;
        
        if (item != null) {
            currentFeeName = (String) item.get(RTFI_NAME_FIELD);
            
            currentFeeAmount = toDecimal(item.get(RTFI_AMOUNT_FIELD));
        }
        
        if (String.isNotBlank(feeName) &&
        (currentFeeName == null ||
        !currentFeeName
        .toLowerCase()
        .contains(feeName.toLowerCase()))) {
            continue;
        }
        
        SendRow row = new SendRow();
        
        row.Id = feeId;
        
        if (account.Parent != null) {
            row.parentAccountName =  account.Parent.Name;
            //Parent Account navigation
            row.parentAccountUrl ='/lightning/r/Account/' + account.Parent.Id + '/view';
        } else {
            row.parentAccountName = '';
            row.parentAccountUrl = null;
        }
        
        row.accountName = account.Name;
        //Account navigation
        row.accountUrl ='/lightning/r/Account/' + account.Id + '/view';
        row.postalCode = (String) account.get(POSTAL_CODE_FIELD);
        
        /*
        * RTF ParentRecordId = BLA ID.
        */
        Object blaIdObject = fee.get(RTF_PARENT_RECORD_FIELD);
        if (blaIdObject != null) {
            row.blaId = String.valueOf(blaIdObject);
            // BLA navigation
            row.blaUrl = '/lightning/r/' +  String.valueOf(blaIdObject) + '/view';
        }
        
        row.feeId = String.valueOf(feeId);
        row.feeName =  currentFeeName;
        row.feeAmount = currentFeeAmount;
        row.multiplePremise = currentMultiplePremise;
        row.premiseRole = currentPremiseRole;
        
        response.records.add(row);
    }
    
    /*
    * Default Parent Account ascending.
    */
    response.records.sort(
    new ParentAccountComparator()
    );
    return response;
}
                    
                    
                    
                        
// ============================================================
// SEND / UPDATE FEE STATUS
   // ============================================================                        
  @AuraEnabled
public static OperationResponse sendSelectedRenewals(List<Id> regulatoryTransactionFeeIds) {
    try {

        if (regulatoryTransactionFeeIds == null ||
            regulatoryTransactionFeeIds.isEmpty()) {

            return new OperationResponse(
                false,
                'Please select at least one renewal.'
            );
        }

        String soql =
            'SELECT Id, ' +
            RTF_STATUS_FIELD +
            ' FROM ' + RTF_OBJECT +
            ' WHERE Id IN :regulatoryTransactionFeeIds';

        List<SObject> fees = Database.query(soql);

        if (fees.isEmpty()) {
            return new OperationResponse(
                false,
                'No renewal records were found.'
            );
        }

        for (SObject fee : fees) {
            fee.put(
                RTF_STATUS_FIELD,
                'Due'
            );
        }

        Database.SaveResult[] results =
            Database.update(fees, false);

        Integer successCount = 0;

        for (Database.SaveResult result : results) {

            if (result.isSuccess()) {
                successCount++;
            } else {
                return new OperationResponse(
                    false,
                    'Unable to send renewal: ' +
                    result.getErrors()[0].getMessage()
                );
            }
        }

        return new OperationResponse(
            true,
            successCount +
            ' Renewal invoices have been generated successfully and contacts have been notified.'
        );

    } catch (Exception e) {

        System.debug(
            'sendSelectedRenewals error: ' +
            e.getMessage()
        );

        return new OperationResponse(
            false,
            'Unable to send renewals: ' + e.getMessage()
        );
    }
}
                        
                        
  // ============================================================
 // ACCOUNT HELPERS
 // ============================================================
private static Map<Id, Account> getAccounts(
    Set<Id> accountIds
) {
    //Map<Id,Account> retmap = new Map<Id,Account>();
    if (accountIds.isEmpty()) {
        return new Map<Id, Account>();
    }
    
    String soql =
    'SELECT Id, Name, Parent.Name, Type, ' +
    POSTAL_CODE_FIELD + ', ' +
    MULTIPLE_PREMISE_FIELD + ', ' +
    PREMISE_ROLE_FIELD +
    ' FROM Account WHERE Id IN :accountIds';
    
    return new Map<Id, Account>((List<Account>)Database.query(soql));
}


private static List<PicklistOption> getAccountTypeOptions() {
    
    List<PicklistOption> options = new List<PicklistOption>();
    
    Schema.DescribeFieldResult describe = Account.Type.getDescribe();
    
    for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
        if (entry.isActive() && ACCOUNTTYPES.contains(entry.getLabel())) {
            options.add(
                new PicklistOption(
                    entry.getLabel(),
                    entry.getValue()
                )
            );
        }
    }
    
    return options;
}


private static List<PicklistOption> getPremiseRoleOptions() {
    
    List<PicklistOption> options = new List<PicklistOption>();
    
    Schema.SObjectField field = Account.SObjectType.getDescribe().fields.getMap()
    .get(PREMISE_ROLE_FIELD);
    
    if (field == null) {
        return options;
    }
    
    Schema.DescribeFieldResult describe = field.getDescribe();
    
    for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
        if (entry.isActive()) {
            options.add(
                new PicklistOption(
                    entry.getLabel(),
                    entry.getValue()
                )
            );
        }
    }
    
    return options;
}


// ============================================================
// COMPARATORS
// ============================================================

public class ParentAccountComparator implements System.Comparator<SendRow> {                            
    public Integer compare( SendRow a, SendRow b) {
        String aValue = a.parentAccountName == null ? '' : a.parentAccountName;                                
        String bValue = b.parentAccountName == null ? '' : b.parentAccountName;                                
        return aValue.toLowerCase().compareTo(bValue.toLowerCase());
    }
}


// ============================================================
// TYPE CONVERSION
// ============================================================

private static Decimal toDecimal(Object value) {
    if (value == null) {
        return null;
    }                            
    if (value instanceof Decimal) {
        return (Decimal) value;
    }                            
    return Decimal.valueOf(String.valueOf(value));
}


private static Boolean toBoolean(Object value) {
    if (value == null) {
        return false;
    }
    
    if (value instanceof Boolean) {
        return (Boolean) value;
    }
    
    return Boolean.valueOf(String.valueOf(value));
}                        
                       
public class OperationResponse {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String message;

    public OperationResponse(Boolean success, String message) {
        this.success = success;
        this.message = message;
    }
}
}