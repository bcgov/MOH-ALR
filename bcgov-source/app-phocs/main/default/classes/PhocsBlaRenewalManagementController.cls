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
    
    private static final String LATE_FEE_NAME = 'Late Fee';
    private static final String RTFI_LATE_FEE_NAME = 'Late Fee';
    private static final String RTF_STATUS_DUE = 'Due';
    private static final String RTF_STATUS_PARTIALLY_PAID = 'Partially Paid';
    private static final String PAYMENT_REMINDER_SEND = 'Send Reminder';
    private static final String PAYMENT_REMINDER_LATE_FEE_VALUE = 'Send Late Fee';
    private static final String RTF_NOTIFICATION_FIELD = 'PaymentReminder__c';
    private static final String RTF_FEE_TYPE_REGULATORY_TRANSACTION = 'Regulatory Transaction Fee';


    // Record typeIds
    private static final Id RTFItemRecordTypeId = Schema.SObjectType.RegulatoryTrxnFeeItem.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFeeItem').getRecordTypeId();
    private static final Id RTFRecordTypeId = Schema.SObjectType.RegulatoryTrxnFee.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFee').getRecordTypeId();
    private static final Id BLARecordTypeId = Schema.SObjectType.BusinessLicenseApplication.getRecordTypeInfosByDeveloperName().get('OperatingPermitApplication').getRecordTypeId();
    
    
    // ============================================================
    // WRAPPERS
    // ============================================================
    
    public class GenerationResponse {
        @AuraEnabled public List<PHOCSBLRenewalAccountRow> records;
        @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> accountTypeOptions;
        @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> premiseRoleOptions;
    }
    
    public class SendResponse {
        @AuraEnabled public List<PHOCSSendRenewalsRow> records;
        @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> accountTypeOptions;
        @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> premiseRoleOptions;
    } 
    
    // ============================================================
    // RENEWAL GENERATION
    // ============================================================
    
    @AuraEnabled
    public static GenerationResponse getGenerationAccounts(String accountType,Boolean multiplePremise){
        String accountStatus='Open';
        GenerationResponse response = new GenerationResponse();
        response.records = new List<PHOCSBLRenewalAccountRow>();
        response.accountTypeOptions = getAccountTypeOptions();
        response.premiseRoleOptions = getPremiseRoleOptions();
        
        String soql = 'SELECT Id, Name, Parent.Name, Type, ' +
        'Physical_Address__PostalCode__s, ' +
        CATEGORY_L1_FIELD + ', ' +
        CATEGORY_L2_FIELD + ', ' +
        'OperatingMonths__c, ' +
        'MultiplePremiseFacility__c, PremiseRole__c' +        
        ' FROM Account';
        
        List<String> conditions = new List<String>();
        Map<String, Object> bindVars = new Map<String, Object>();
        
        // account status open
        conditions.add('Status__c = :accountStatus');
        bindVars.put('accountStatus', accountStatus);
        
        if (String.isNotBlank(accountType)) {
            conditions.add('Type = :accountType');
            bindVars.put('accountType', accountType);
        }
        
        if (multiplePremise == true) {
            conditions.add('MultiplePremiseFacility__c = true');
        }
        
        if (!conditions.isEmpty()) {
            soql += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        // Default sort: Parent Account ascending.
        soql += ' ORDER BY Parent.Name ASC NULLS FIRST, Name ASC';
        
        List<Account> accounts = Database.queryWithBinds(soql, bindVars, AccessLevel.USER_MODE);
        
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
            PHOCSBLRenewalAccountRow row = new PHOCSBLRenewalAccountRow();
            
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
            if(account.get(POSTAL_CODE_FIELD)!= null)
            row.postalCode = (String) account.get(POSTAL_CODE_FIELD);
            if(account.get(CATEGORY_L1_FIELD)!= null)
            row.categoryL1 = (String) account.get(CATEGORY_L1_FIELD);
            if(account.get(CATEGORY_L2_FIELD)!= null)
            row.categoryL2 = (String) account.get(CATEGORY_L2_FIELD);
            if(account.get(OPERATING_MONTHS_FIELD)!= null)
            row.operatingMonths = (String)account.get(OPERATING_MONTHS_FIELD);
            if(account.get(MULTIPLE_PREMISE_FIELD)!= null)
            row.multiplePremise = toBoolean(account.get(MULTIPLE_PREMISE_FIELD));
            if(account.get(PREMISE_ROLE_FIELD)!= null)
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
        Date today = Date.today();
        Integer targetRYear = Date.today().year();
        String RenewalYear;  
        
        if (today.month() > 4 ||(today.month() == 4 && today.day() > 1)) {
            targetRYear++;
        }        
        RenewalYear = String.valueOf(targetRYear+1); 
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
        DateTime RenewalDate;
        String RenewalYear;  
        
        if (today.month() > 4 ||(today.month() == 4 && today.day() > 1)) {
            targetRYear++;
        }
        RenewalDate =DateTime.newInstance(targetRYear, 4, 1,0,0,0);
        RenewalYear = String.valueOf(RenewalDate.Year()+1);
        if (accountIds == null || accountIds.isEmpty()) {
            return new OperationResponse(false, 'Please select at least one account.');
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
    ' AccountId, LicensePermitName.Status,HealthAuthority__c' +
    ' FROM BusinessLicenseApplicationAccount' +
    ' WHERE LicensePermitName.Status = :blStatus' +
    ' AND RecordTypeId = :recordTypeId' +
    ' AND LicenseType.Name IN :licenseTypes' +
    ' AND ClosedDate__c != NULL' +
    ' ORDER BY ClosedDate__c DESC LIMIT 1)' +
    ' FROM Account WHERE Id IN :accountIds';

List<Account> accounts =
    (List<Account>)Database.queryWithBinds(accountSoql, bindVars, AccessLevel.USER_MODE);        
        if (accounts.isEmpty()) {
            return new OperationResponse(false, 'No valid accounts were selected.');
        }
        
        List<BusinessLicenseApplication> applications = new List<BusinessLicenseApplication>();        
        Map<Id, Decimal> mapBlaIdPoolArea = new Map<Id, Decimal>();        
        for (Account acc : accounts) {
            if (!acc.BusinessLicenseApplicationAccount.isEmpty()) {
                BusinessLicenseApplication bla = acc.BusinessLicenseApplicationAccount[0];                
                applications.add(bla);
                if (!acc.Assets.isEmpty() && acc.Assets[0].PoolAream2__c != null) {                    
                    mapBlaIdPoolArea.put(bla.Id, acc.Assets[0].PoolAream2__c);
                }
            }
        }
        
        if (applications.isEmpty()) {
            return new OperationResponse(
            false,
            'No eligible Business License Applications were found for the selected accounts.'
            );
        }
        
        List<PHOCS_GenerateApplicationFees__mdt> feeList = [SELECT Amount__c,
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
                                                                    FROM PHOCS_GenerateApplicationFees__mdt];
        
        List<RegulatoryTrxnFee> parentFeesToInsert = new List<RegulatoryTrxnFee>();        
        List<RegulatoryTrxnFeeItem> childFeeItemsToInsert = new List<RegulatoryTrxnFeeItem>();        
        Map<Id, PHOCS_GenerateApplicationFees__mdt> blaFeeMap = new Map<Id, PHOCS_GenerateApplicationFees__mdt>();
        
        for (BusinessLicenseApplication bla : applications) {            
            PHOCS_GenerateApplicationFees__mdt feeData = getRenewalFeeAmount(feeList, bla, mapBlaIdPoolArea);
            
            if (feeData != null) {                
                blaFeeMap.put(bla.Id, feeData);                
                RegulatoryTrxnFee newFee = new RegulatoryTrxnFee();                
                newFee.ParentRecordId = bla.Id;
                newFee.RecordTypeId = RTFRecordTypeId;
                newFee.HealthAuthority__c =bla.HealthAuthority__c;
                newFee.Status__c = 'Draft';
                newFee.FeeType__c = 'Renewal';
                newFee.DueDate = RenewalDate;
                newFee.RenewalYear__c = RenewalYear;
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
        
        Database.SaveResult[] feeResults = Database.insert(parentFeesToInsert, false);        
        Integer successfulFees = 0;        
        for (Database.SaveResult result : feeResults) {
            if (result.isSuccess()) {
                successfulFees++;
            } else {
                return new OperationResponse(false, 'Unable to generate renewal fees: ' +result.getErrors()[0].getMessage());
            }
        }        
        for (RegulatoryTrxnFee parentFee : parentFeesToInsert) {            
            PHOCS_GenerateApplicationFees__mdt feeData = blaFeeMap.get(parentFee.ParentRecordId);            
            if (feeData == null) {
                continue;
            }            
            RegulatoryTrxnFeeItem newFeeItem = new RegulatoryTrxnFeeItem();            
            newFeeItem.RegulatoryTrxnFeeId = parentFee.Id;
            newFeeItem.RecordTypeId = RTFItemRecordTypeId;
            newFeeItem.Status__c = 'Due';
            newFeeItem.FeeType__c = feeData.RTFIFeeType__c;
            newFeeItem.Name = feeData.FeeName__c;
            newFeeItem.FeeAmount = feeData.Amount__c;            
            childFeeItemsToInsert.add(newFeeItem);
        }
        
        if (!childFeeItemsToInsert.isEmpty()) {            
            Database.SaveResult[] itemResults = Database.insert(childFeeItemsToInsert, false);            
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
        return new OperationResponse(true, successfulFees + ' Renewal(s) Generated Successfully.');        
    } catch (Exception e) {        
        System.debug('generateRenewalRecords error: ' + e.getMessage());        
        return new OperationResponse(false, 'Renewal generation failed: ' + e.getMessage());
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
public static SendResponse getSendRenewals(String type, String feeName, Boolean multiplePremise, String premiseRole) {
    SendResponse response = new SendResponse();    
    response.records = new List<PHOCSSendRenewalsRow>();
    response.accountTypeOptions = getAccountTypeOptions();
    response.premiseRoleOptions = getPremiseRoleOptions();
    
    // Query RTF REcords
    String rtfSoql = 'SELECT Id,Name, ' + RTF_ACCOUNT_FIELD + ', ' +
    'ParentRecordId,ParentRecord.Name, Status__c FROM RegulatoryTrxnFee' +
    ' WHERE Status__c = :RTF_STATUS_DRAFT'+
    ' AND '+ RTF_FEETYPE_FIELD + ' = :RTF_FEETYPE_RENEWAL';  
    
    Schema.SObjectType rtfType = Schema.getGlobalDescribe().get(RTF_OBJECT);
    
    if (rtfType == null) {
        throw new AuraHandledException(
        'Object ' + RTF_OBJECT + ' does not exist in this org.'
        );
    }
    
    List<RegulatoryTrxnFee> fees = Database.query(rtfSoql);
    
    if (fees.isEmpty()) {
        return response;
    }
    
    Set<Id> accountIds = new Set<Id>();
    Set<Id> feeIds = new Set<Id>();    
    for (RegulatoryTrxnFee fee : fees) {
        Object accountId = fee.get(RTF_ACCOUNT_FIELD);        
        if (accountId != null) {
            accountIds.add((Id) accountId);
        }        
        feeIds.add((Id) fee.get('Id'));
    }
    
    Map<Id, Account> accounts = getAccounts(accountIds);
    
    //Query RTFI separately instead of relying on an assumed
    
    String itemSoql =
    'SELECT Id, ' +
    RTFI_PARENT_FIELD + ', ' +
    RTFI_NAME_FIELD + ', ' +
    RTFI_AMOUNT_FIELD +
    ' FROM ' + RTFI_OBJECT +
    ' WHERE ' + RTFI_PARENT_FIELD + ' IN :feeIds';
    
    Schema.SObjectType itemType = Schema.getGlobalDescribe().get(RTFI_OBJECT);
    
    if (itemType == null) {
        throw new AuraHandledException(
        'Object ' + RTFI_OBJECT + ' does not exist in this org.'
        );
    }    
    List<RegulatoryTrxnFeeItem> items = Database.query(itemSoql);
    
    Map<Id, SObject> itemByFee = new Map<Id, SObject>();    
    for (SObject item : items) {
        Id feeId = (Id) item.get(RTFI_PARENT_FIELD);        
        if (!itemByFee.containsKey(feeId)) {
            itemByFee.put(feeId, item);
        }
    }
    
    for (RegulatoryTrxnFee fee : fees) {
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
        (currentFeeName == null ||!currentFeeName.toLowerCase().contains(feeName.toLowerCase()))) {
            continue;
        }
        
        PHOCSSendRenewalsRow row = new PHOCSSendRenewalsRow();
        
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
            //row.blaId = String.valueOf(blaIdObject);
            row.blaId = String.valueOf(fee.ParentRecord.Name);
            // BLA navigation
            row.blaUrl = '/lightning/r/' +  String.valueOf(blaIdObject) + '/view';
           
        }
        
       // row.feeId = String.valueOf(feeId);
        row.feeId = String.valueOf(fee.get('Name'));
        row.feeUrl = '/lightning/r/' + row.Id + '/view';
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

        String soql ='SELECT Id, Status__c ' +
                        'FROM RegulatoryTrxnFee ' +
                        'WHERE Id IN :regulatoryTransactionFeeIds';
                    Map<String, Object> bindVars = new Map<String, Object>{
                        'regulatoryTransactionFeeIds' => regulatoryTransactionFeeIds
                    };
                    List<RegulatoryTrxnFee> fees = Database.queryWithBinds(
                        soql,
                        bindVars,
                        AccessLevel.USER_MODE
                    );

        if (fees.isEmpty()) {
            return new OperationResponse(
                false,
                'No renewal records were found.'
            );
        }

        for (RegulatoryTrxnFee fee : fees) {
            fee.put(
                'Status__c',
                'Due'
            );
        }

        Database.SaveResult[] results = Database.update(fees, false);
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
// PAYMENT REMINDERS
// ============================================================

@AuraEnabled 
public static PHOCSRenewalPaymentReminderResponse getPaymentReminders( 
    String type,
    String feeName,
    String feeType,
    Integer pageNumber,
    Integer pageSize,
    String sortBy,
    String sortDirection
) {
    PHOCSRenewalPaymentReminderResponse response = new PHOCSRenewalPaymentReminderResponse();

    pageNumber = pageNumber == null || pageNumber < 1
        ? 1
        : pageNumber;

    pageSize = pageSize == null || pageSize < 1
        ? 50
        : Math.min(pageSize, 50);

    response.pageNumber = pageNumber;
    response.pageSize = pageSize;
    response.accountTypeOptions = getAccountTypeOptions();
    response.feeTypeOptions = getFeeTypeOptions();

    /*
     * Never concatenate arbitrary client-provided sort values.
     * Only values in this allowlist can become SOQL.
     */
    Map<String, String> allowedSortFields =
        new Map<String, String>{
            'parentAccountName' => 'Account.Parent.Name',
            'accountName' => 'Account.Name',
            'postalCode' => 'Physical_Address__PostalCode__s',
            'blaId' => 'ParentRecordId',
            'feeId' => 'Id',
            'feeName' => 'Id',
            'feeAmount' => 'Id',
            'dueDate' => 'DueDate',
            'operatingMonths' => 'Account.OperatingMonths__c',
            'multiplePremise' => 'Account.MultiplePremiseFacility__c',
            'premiseRole' => 'Account.PremiseRole__c'
        };

    String orderField =
        allowedSortFields.containsKey(sortBy)
            ? allowedSortFields.get(sortBy)
            : 'Account.Name';

    String direction =
        String.valueOf(sortDirection).toLowerCase() == 'desc'
            ? 'DESC'
            : 'ASC';

    /*
     * Fee Name is sorted through the related Fee Item and cannot
     * safely be represented as a simple parent relationship field.
     *
     * For that column we use Fee Item Name as the secondary
     * deterministic ordering after the primary RTF field.
     */
    String orderBy;

    if (sortBy == 'feeName') {
        orderBy =
            'Id ' + direction;
    } else {
        orderBy = orderField + ' ' + direction;
    }

    String baseWhere =  'Status__c IN (\'Due\', \'Partially Paid\')';

    baseWhere += ' AND ' + RTF_FEETYPE_FIELD + ' != NULL';            

    Map<String, Object> binds =
        new Map<String, Object>();

    if (String.isNotBlank(type)) {
        baseWhere += ' AND Account.Type = :type';
        binds.put('type', type);
    }

    if (String.isNotBlank(feeType)) {
        baseWhere += ' AND ' + RTF_FEETYPE_FIELD +
            ' = :feeType';
        binds.put('feeType', feeType);
    }

    If(String.isNotBlank(RTFRecordTypeId)){
    baseWhere += ' AND RecordTypeId = :RTFRecordTypeId';
    binds.put('RTFRecordTypeId', RTFRecordTypeId);
    }

    /*
     * Fee Name filter is implemented as a semi-join.
     *
     * This avoids loading all Fee Items into Apex.
     */
    if (String.isNotBlank(feeName)) {

        String escapedFeeName =
            '%' +
            String.escapeSingleQuotes(
                feeName.trim()
            ) +
            '%';

        baseWhere +=
            ' AND Id IN (' +
            'SELECT ' + RTFI_PARENT_FIELD +
            ' FROM REGULATORYTRXNFEEITEM' +
            ' WHERE ' + RTFI_NAME_FIELD +
            ' LIKE \'' +
            escapedFeeName +
            '\')';
    }

    String countSoql =
        'SELECT COUNT() FROM REGULATORYTRXNFEE' +
        ' WHERE ' +
        baseWhere;

    response.totalCount =
        Database.countQueryWithBinds(
            countSoql,
            binds,
            AccessLevel.USER_MODE
        );

    if (response.totalCount == 0) {
        return response;
    }

    Integer offsetValue =
        (pageNumber - 1) * pageSize;

    String soql =
        'SELECT Id,Name, ' +
        'AccountId, ' +
        'ParentRecordId, ParentRecord.Name, ' +
        'Status__c, ' +
        RTF_FEETYPE_FIELD + ', ' +
        'DueDate, ' +
        'Account.Id, ' +
        'Account.Name, ' +
        'Account.Parent.Id, ' +
        'Account.Parent.Name, ' +
        'Account.Physical_Address__PostalCode__s, ' + 
        'Account.OperatingMonths__c, ' + 
        'Account.MultiplePremiseFacility__c, ' + 
        'Account.PremiseRole__c' + 
        ' FROM REGULATORYTRXNFEE' +       
        ' WHERE ' +
        baseWhere +
        ' ORDER BY ' +
        orderBy +
        ', Id ASC' +
        ' LIMIT ' + pageSize +
        ' OFFSET ' + offsetValue;

    List<RegulatoryTrxnFee> fees =
        Database.queryWithBinds(
            soql,
            binds,
            AccessLevel.USER_MODE
        );

    if (fees.isEmpty()) {
        return response;
    }

    Set<Id> feeIds = new Set<Id>();

    for (RegulatoryTrxnFee fee : fees) {
        feeIds.add((Id)fee.get('Id'));
    }

    /*
     * Retrieve Fee Items in one bulk query.
     */
    String itemSoql =
        'SELECT Id, ' +
        RTFI_PARENT_FIELD + ', ' +
        RTFI_NAME_FIELD + ', ' +
        RTFI_AMOUNT_FIELD +
        ' FROM ' +
        RTFI_OBJECT +
        ' WHERE ' +
        RTFI_PARENT_FIELD +
        ' IN :feeIds';

    List<SObject> feeItems =
        Database.queryWithBinds(
            itemSoql,
            new Map<String, Object>{
                'feeIds' => feeIds
            },
            AccessLevel.USER_MODE
        );

    Map<Id, SObject> itemByFee =
        new Map<Id, SObject>();

    for (SObject item : feeItems) {

        Id feeId =
            (Id)item.get(RTFI_PARENT_FIELD);

        /*
         * Existing data model appears to use one fee item
         * for each renewal fee. Keep the first item for now.
         */
        if (!itemByFee.containsKey(feeId)) {
            itemByFee.put(feeId, item);
        }
    }

    for (RegulatoryTrxnFee fee : fees) {
        PHOCSPaymentReminderRow row = new PHOCSPaymentReminderRow();
        row.Id = (Id)fee.get('Id');
        Account account = (Account)fee.getSObject('Account');
        if (account == null) {
            continue;
        }
        row.accountName = account.Name;
        row.accountUrl = '/lightning/r/Account/' +account.Id +'/view';
        Account parent = account.Parent;

        if (parent != null) {
            row.parentAccountName = parent.Name;
            row.parentAccountUrl = '/lightning/r/Account/' +parent.Id +'/view';
        } else {
            row.parentAccountName = '';
            row.parentAccountUrl = null;
        }

        row.postalCode = (String)account.get(POSTAL_CODE_FIELD);
        row.operatingMonths = (String)account.get(OPERATING_MONTHS_FIELD);
        row.multiplePremise = toBoolean(account.get(MULTIPLE_PREMISE_FIELD));
        row.premiseRole = (String)account.get(PREMISE_ROLE_FIELD);
        Id blaId = (Id)fee.get( RTF_PARENT_RECORD_FIELD);

        if (blaId != null) {
            //row.blaId = String.valueOf(blaId);
            row.blaId = String.valueOf(fee.ParentRecord.Name);
            row.blaUrl = '/lightning/r/' + blaId +'/view';
        }
        row.feeId = String.valueOf(fee.get('Name'));
        row.feeUrl = '/lightning/r/' + row.Id + '/view';
        Object dueDateValue = fee.get('DueDate');
        if (dueDateValue instanceof Date) {
            row.dueDate = (Date)dueDateValue;
        } else if (
            dueDateValue instanceof Datetime
        ) {
            row.dueDate = ((Datetime)dueDateValue).date();
        }
        SObject item = itemByFee.get(row.Id);

        if (item != null) {
            row.feeName = (String)item.get(RTFI_NAME_FIELD);
            row.feeNameLabel = row.feeName;
            row.feeAmount = toDecimal(item.get(RTFI_AMOUNT_FIELD));
        }
        response.records.add(row);
    }
    return response;
}

@AuraEnabled
public static OperationResponse sendPaymentReminders(String type, String feeName, String feeType, List<Id> deselectedFeeIds) {
    try {
        Set<Id> excludedIds =
            deselectedFeeIds == null
                ? new Set<Id>()
                : new Set<Id>(deselectedFeeIds);

        /*
         * Rebuild the eligible set on the server.
         *
         * Never trust the browser's selection state.
         */
        Set<Id> eligibleFeeIds = getEligiblePaymentReminderIds( type, feeName, feeType);
        eligibleFeeIds.removeAll(excludedIds);
        if (eligibleFeeIds.isEmpty()) {
            return new OperationResponse(
                false,
                'No eligible payment reminder records were selected.'
            );
        }

        /*
         * Revalidate status immediately before processing.
         */
        List<RegulatoryTrxnFee> fees =
            queryEligibleFeesForSending(
                eligibleFeeIds
            );

        if (fees.isEmpty()) {
            return new OperationResponse(
                false,
                'No selected fees are still eligible for payment reminders.'
            );
        }      


        Integer processed = triggerPaymentReminderEmails(fees);

if (processed == 0) {
    return new OperationResponse(
        false,
        'No eligible contacts were found for the selected facilities.'
    );
}

return new OperationResponse(
    true,
    processed +
    ' Emails will be sent to contact(s) on selected facilities'
);
    } catch (Exception e) {
        System.debug(
            LoggingLevel.ERROR,
            'sendPaymentReminders error: ' +
            e.getMessage()
        );

        return new OperationResponse(
            false,
            'Unable to send payment reminders.'
        );
    }
}

private static Set<Id> getEligiblePaymentReminderIds(String type, String feeName, String feeType) {
    String whereClause = 'Status__c IN (:statusDue, :statusPartiallyPaid)';

    Map<String, Object> binds = new Map<String, Object>{
        'statusDue' => RTF_STATUS_DUE,
        'statusPartiallyPaid' => RTF_STATUS_PARTIALLY_PAID
    };

    if (String.isNotBlank(type)) {
        whereClause += ' AND Account.Type = :type';
        binds.put('type', type);
    }

    if (String.isNotBlank(feeType)) {
        whereClause +=
            ' AND ' + RTF_FEETYPE_FIELD + ' = :feeType';

        binds.put('feeType', feeType);
    }

    if (String.isNotBlank(feeName)) {
        whereClause +=
            ' AND Id IN (' +
            'SELECT ' + RTFI_PARENT_FIELD +
            ' FROM ' + RTFI_OBJECT +
            ' WHERE ' + RTFI_NAME_FIELD +
            ' LIKE :feeNameFilter' +
            ')';

        binds.put(
            'feeNameFilter',
            '%' + feeName.trim() + '%'
        );
    }

    String soql =
        'SELECT Id ' +
        'FROM ' + RTF_OBJECT +
        ' WHERE ' + whereClause;

    List<SObject> records =
        Database.queryWithBinds(
            soql,
            binds,
            AccessLevel.USER_MODE
        );

    Set<Id> result = new Set<Id>();

    for (SObject record : records) {
        result.add((Id)record.get('Id'));
    }

    return result;
}

private static List<RegulatoryTrxnFee> queryEligibleFeesForSending( Set<Id> feeIds) {
    if (feeIds.isEmpty()) {
        return new List<RegulatoryTrxnFee>();
    }

    String soql =
        'SELECT Id, Status__c, ' +        
        RTF_ACCOUNT_FIELD + ', ' +
        'ParentRecordId '+
        ' FROM RegulatoryTrxnFee' +       
        ' WHERE Id IN :feeIds' +
        ' AND Status__c IN (\'Due\', \'Partially Paid\')';

    return Database.queryWithBinds(
        soql,
        new Map<String, Object>{
            'feeIds' => feeIds
        },
        AccessLevel.USER_MODE
    );
}




@AuraEnabled
public static PHOCSRenewalLateFeeResponse getLateFeeManagement(
    String type,
    String feeName,
    String feeType,
    Integer pageNumber,
    Integer pageSize,
    String sortBy,
    String sortDirection
) {
    PHOCSRenewalLateFeeResponse response = new PHOCSRenewalLateFeeResponse();

    pageNumber =
        pageNumber == null || pageNumber < 1
            ? 1
            : pageNumber;

    pageSize =
        pageSize == null || pageSize < 1
            ? 50
            : Math.min(pageSize, 50);

    response.pageNumber = pageNumber;
    response.pageSize = pageSize;

    response.accountTypeOptions =
        getAccountTypeOptions();

    response.feeTypeOptions =
        getFeeTypeOptions();

    /*
     * Only fields explicitly exposed by the UI may be used
     * for dynamic ORDER BY.
     */
    Map<String, String> allowedSortFields =
        new Map<String, String>{
            'parentAccountName' =>
                'Account.Parent.Name',

            'accountName' =>
                'Account.Name',

            'postalCode' =>
                'Account.Physical_Address__PostalCode__s',

            'blaId' =>
                'ParentRecordId',

            'feeId' =>
                'Id',

            'dueDate' =>
                'DueDate',

            'operatingMonths' =>
                'Account.OperatingMonths__c',

            'multiplePremise' =>
                'Account.MultiplePremiseFacility__c',

            'premiseRole' =>
                'Account.' + PREMISE_ROLE_FIELD
        };

    String orderField =
        allowedSortFields.containsKey(sortBy)
            ? allowedSortFields.get(sortBy)
            : 'Account.Name';

    String direction =
        String.valueOf(sortDirection).toLowerCase() == 'desc'
            ? 'DESC'
            : 'ASC';

    String orderBy =
        orderField + ' ' + direction;

    /*
     * Base Late Fee eligibility.
     */
    String whereClause ='Status__c IN (:statusDue, :statusPartiallyPaid)' +
        ' AND DueDate < :today';

    Map<String, Object> binds =
        new Map<String, Object>{
            'statusDue' => RTF_STATUS_DUE,
            'statusPartiallyPaid' => RTF_STATUS_PARTIALLY_PAID,
            'today' => Date.today(),
            'lateFeeName' => LATE_FEE_NAME
        };

    if (String.isNotBlank(type)) {
        whereClause +=
            ' AND Account.Type = :type';

        binds.put('type', type);
    }

    if (String.isNotBlank(feeType)) {
        whereClause +=
            ' AND ' + RTF_FEETYPE_FIELD +
            ' = :feeType';

        binds.put('feeType', feeType);
    }

    if (String.isNotBlank(feeName)) {
        whereClause +=
            ' AND Id IN (' +
            'SELECT ' + RTFI_PARENT_FIELD +
            ' FROM ' + RTFI_OBJECT +
            ' WHERE ' + RTFI_NAME_FIELD +
            ' LIKE :feeNameFilter' +
            ')';

        binds.put(
            'feeNameFilter',
            '%' + feeName.trim() + '%'
        );
    }

    /*
     * An invoice that already received a Late Fee must not
     * appear again.
     */
    whereClause +=
        ' AND Id NOT IN (' +
        'SELECT ' + RTFI_PARENT_FIELD +
        ' FROM ' + RTFI_OBJECT +
        ' WHERE ' + RTFI_NAME_FIELD +
        ' = :lateFeeName' +
        ')';

    String countSoql =
        'SELECT COUNT() ' +
        'FROM ' + RTF_OBJECT +
        ' WHERE ' + whereClause;

    response.totalCount =
        Database.countQueryWithBinds(
            countSoql,
            binds,
            AccessLevel.USER_MODE
        );

    if (response.totalCount == 0) {
        return response;
    }

    Integer offsetValue =
        (pageNumber - 1) * pageSize;

    String soql =
        'SELECT Id,Name, ' +
        'AccountId, ' +
        'ParentRecordId,ParentRecord.Name, ' +
        'Status__c, ' +
        RTF_FEETYPE_FIELD + ', ' +
        'DueDate, ' +
        'Account.Id, ' +
        'Account.Name, ' +
        'Account.Parent.Id, ' +
        'Account.Parent.Name, ' +
        'Account.Physical_Address__PostalCode__s, ' +
        'Account.OperatingMonths__c, ' +
        'Account.MultiplePremiseFacility__c, ' +
        'Account.' + PREMISE_ROLE_FIELD +
        ' FROM RegulatoryTrxnFee' +
        ' WHERE ' + whereClause +
        ' ORDER BY ' + orderBy +
        ', Account.Name ASC' +
        ', Id ASC' +
        ' LIMIT ' + pageSize +
        ' OFFSET ' + offsetValue;

    List<RegulatoryTrxnFee> fees =
        Database.queryWithBinds(
            soql,
            binds,
            AccessLevel.USER_MODE
        );

    if (fees.isEmpty()) {
        return response;
    }

    Set<Id> feeIds = new Set<Id>();

    for (RegulatoryTrxnFee fee : fees) {
        feeIds.add((Id)fee.get('Id'));
    }

    /*
     * Bulk-load Fee Items.
     */
    String itemSoql =
        'SELECT Id, ' +
        RTFI_PARENT_FIELD + ', ' +
        RTFI_NAME_FIELD + ', ' +
        RTFI_AMOUNT_FIELD +
        ' FROM ' + RTFI_OBJECT +
        ' WHERE ' + RTFI_PARENT_FIELD +
        ' IN :feeIds';

    List<SObject> feeItems =
        Database.queryWithBinds(
            itemSoql,
            new Map<String, Object>{
                'feeIds' => feeIds
            },
            AccessLevel.USER_MODE
        );

    Map<Id, SObject> itemByFee =
        new Map<Id, SObject>();

    for (SObject item : feeItems) {
        Id feeId =
            (Id)item.get(RTFI_PARENT_FIELD);

        /*
         * Use the normal invoice fee item for display.
         */
        if (!itemByFee.containsKey(feeId) &&
            (String)item.get(RTFI_NAME_FIELD) != LATE_FEE_NAME) {

            itemByFee.put(feeId, item);
        }
    }

    for (RegulatoryTrxnFee fee : fees) {

        PHOCSPaymentReminderRow row =  new PHOCSPaymentReminderRow();

        row.Id = (Id)fee.get('Id');

        Account account =
            (Account)fee.getSObject('Account');

        if (account == null) {
            continue;
        }

        row.accountName = account.Name;

        row.accountUrl =
            '/lightning/r/Account/' +
            account.Id +
            '/view';

        if (account.Parent != null) {
            row.parentAccountName =
                account.Parent.Name;

            row.parentAccountUrl =
                '/lightning/r/Account/' +
                account.Parent.Id +
                '/view';
        }

        row.postalCode =
            (String)account.get(
                POSTAL_CODE_FIELD
            );

        row.operatingMonths =
            (String)account.get(
                OPERATING_MONTHS_FIELD
            );

        row.multiplePremise =
            toBoolean(
                account.get(
                    MULTIPLE_PREMISE_FIELD
                )
            );

        row.premiseRole =
            (String)account.get(
                PREMISE_ROLE_FIELD
            );

        Id blaId =
            (Id)fee.get(
                RTF_PARENT_RECORD_FIELD
            );

        if (blaId != null) {
            //row.blaId = String.valueOf(blaId);
            row.blaId = String.valueOf(fee.ParentRecord.Name);
            row.blaUrl =
                '/lightning/r/' +
                blaId +
                '/view';
        }

        row.feeId = String.valueOf(fee.get('Name'));

        row.feeUrl =
            '/lightning/r/' +
            row.Id +
            '/view';

        Object dueDateValue =
            fee.get('DueDate');

        if (dueDateValue instanceof Date) {
            row.dueDate =
                (Date)dueDateValue;
        } else if (
            dueDateValue instanceof Datetime
        ) {
            row.dueDate =
                ((Datetime)dueDateValue).date();
        }

        SObject item =
            itemByFee.get(row.Id);

        if (item != null) {
            row.feeName =
                (String)item.get(
                    RTFI_NAME_FIELD
                );

            row.feeNameLabel =
                row.feeName;

            row.feeAmount =
                toDecimal(
                    item.get(
                        RTFI_AMOUNT_FIELD
                    )
                );
        }

        response.records.add(row);
    }

    return response;
}

// ============================================================
// LATE FEE MANAGEMENT - GET RECORDS
// ============================================================

@AuraEnabled
public static PHOCSRenewalLateFeeManagementResponse getLateFeeManagementRecords(
    String type,
    String feeName,
    String feeType,
    Integer pageNumber,
    Integer pageSize,
    String sortBy,
    String sortDirection
) {

    PHOCSRenewalLateFeeManagementResponse response =
        new PHOCSRenewalLateFeeManagementResponse();

    try {

        // ----------------------------------------------------
        // Pagination
        // ----------------------------------------------------

        pageNumber =
            pageNumber == null || pageNumber < 1
                ? 1
                : pageNumber;

        pageSize =
            pageSize == null || pageSize < 1
                ? 50
                : Math.min(pageSize, 50);

        response.pageNumber = pageNumber;
        response.pageSize = pageSize;

        // ----------------------------------------------------
        // Picklists
        // ----------------------------------------------------

        response.accountTypeOptions = getAccountTypeOptions();

        response.feeTypeOptions = getFeeTypeOptions();

        // ----------------------------------------------------
        // Build common filters
        // ----------------------------------------------------

        FeeQueryContext context = buildFeeQueryContext(type, feeName, feeType);

        // ----------------------------------------------------
        // Add Late Fee eligibility
        // ----------------------------------------------------

        addLateFeeEligibility(context);

        // ----------------------------------------------------
        // Record Type restriction
        // ----------------------------------------------------

        if (RTFRecordTypeId != null) {
            context.whereClause += ' AND RecordTypeId = :lateFeeRecordTypeId';
            context.binds.put('lateFeeRecordTypeId', RTFRecordTypeId);
        }

        // ----------------------------------------------------
        // Count
        // ----------------------------------------------------

        String countSoql =
            'SELECT COUNT() ' +
            'FROM ' + RTF_OBJECT +
            ' WHERE ' +
            context.whereClause;

        response.totalCount =
            Database.countQueryWithBinds(
                countSoql,
                context.binds,
                AccessLevel.USER_MODE
            );

        if (response.totalCount == 0) {
            return response;
        }

        // ----------------------------------------------------
        // Sort
        // ----------------------------------------------------

        String orderBy =
            getLateFeeOrderBy(
                sortBy,
                sortDirection
            );

        // ----------------------------------------------------
        // Pagination
        // ----------------------------------------------------

        Integer offsetValue =
            (pageNumber - 1) * pageSize;

        // ----------------------------------------------------
        // Query RTFs
        // ----------------------------------------------------

        String soql =
            'SELECT Id,Name, ' +
            'AccountId, ' +
            'ParentRecordId,ParentRecord.Name, ' +
            'Status__c, ' +
            RTF_FEETYPE_FIELD + ', ' +
            'DueDate, ' +

            'Account.Id, ' +
            'Account.Name, ' +
            'Account.Type, ' +
            'Account.Parent.Id, ' +
            'Account.Parent.Name, ' +
            'Account.Physical_Address__PostalCode__s, ' +
            'Account.OperatingMonths__c, ' +
            'Account.MultiplePremiseFacility__c, ' +
            'Account.' + PREMISE_ROLE_FIELD +
            ' FROM RegulatoryTrxnFee' +
            ' WHERE ' +
            context.whereClause +

            ' ORDER BY ' +
            orderBy +
            ', Id ASC' +

            ' LIMIT ' +
            pageSize +

            ' OFFSET ' +
            offsetValue;

        List<RegulatoryTrxnFee> fees =
            Database.queryWithBinds(
                soql,
                context.binds,
                AccessLevel.USER_MODE
            );

        if (fees.isEmpty()) {
            return response;
        }

        // ----------------------------------------------------
        // Fee Items
        // ----------------------------------------------------

        Set<Id> feeIds =
            new Set<Id>();

        for (RegulatoryTrxnFee fee : fees) {

            feeIds.add(
                (Id)fee.get('Id')
            );
        }

        String itemSoql =
            'SELECT Id, ' +
            RTFI_PARENT_FIELD + ', ' +
            RTFI_NAME_FIELD + ', ' +
            RTFI_AMOUNT_FIELD +
            ' FROM ' +
            RTFI_OBJECT +
            ' WHERE ' +
            RTFI_PARENT_FIELD +
            ' IN :feeIds';

        List<SObject> feeItems =
            Database.queryWithBinds(
                itemSoql,
                new Map<String, Object>{
                    'feeIds' => feeIds
                },
                AccessLevel.USER_MODE
            );

        // ----------------------------------------------------
        // Map Fee Item to RTF
        // ----------------------------------------------------

        Map<Id, SObject> itemByFee =
            new Map<Id, SObject>();

        for (SObject item : feeItems) {

            Id feeId =
                (Id)item.get(
                    RTFI_PARENT_FIELD
                );

            /*
             * We only need one item for the display row.
             *
             * Existing payment reminder implementation
             * already follows this model.
             */
            if (!itemByFee.containsKey(feeId)) {

                itemByFee.put(
                    feeId,
                    item
                );
            }
        }

        // ----------------------------------------------------
        // Build response
        // ----------------------------------------------------

        for (RegulatoryTrxnFee fee : fees) {

            PHOCSLateFeeManagementRow row =
                new PHOCSLateFeeManagementRow();

            row.Id =
                (Id)fee.get('Id');

            Account account =
                (Account)fee.getSObject('Account');

            if (account == null) {
                continue;
            }

            // Account
            row.accountName =
                account.Name;

            row.accountUrl =
                '/lightning/r/Account/' +
                account.Id +
                '/view';

            // Parent Account
            Account parent =
                account.Parent;

            if (parent != null) {

                row.parentAccountName =
                    parent.Name;

                row.parentAccountUrl =
                    '/lightning/r/Account/' +
                    parent.Id +
                    '/view';

            } else {

                row.parentAccountName = '';
                row.parentAccountUrl = null;
            }

            // Postal Code
            row.postalCode =
                (String)account.get(
                    POSTAL_CODE_FIELD
                );

            // Operating Months
            row.operatingMonths =
                (String)account.get(
                    OPERATING_MONTHS_FIELD
                );

            // Multiple Premise
            row.multiplePremise =
                toBoolean(
                    account.get(
                        MULTIPLE_PREMISE_FIELD
                    )
                );

            // Premise Role
            row.premiseRole =
                (String)account.get(
                    PREMISE_ROLE_FIELD
                );

            // BLA
            Id blaId =
                (Id)fee.get(
                    RTF_PARENT_RECORD_FIELD
                );

            if (blaId != null) {

                //row.blaId =  String.valueOf(blaId);
                row.blaId = String.valueOf(fee.ParentRecord.Name);

                row.blaUrl =
                    '/lightning/r/' +
                    blaId +
                    '/view';
            }

            // RTF
            row.feeId = String.valueOf(fee.get('Name'));

            row.feeUrl =
                '/lightning/r/' +
                row.Id +
                '/view';

            // Due Date
            Object dueDateValue =
                fee.get('DueDate');

            if (dueDateValue instanceof Date) {

                row.dueDate =
                    (Date)dueDateValue;

            } else if (
                dueDateValue instanceof Datetime
            ) {

                row.dueDate =
                    ((Datetime)dueDateValue).date();
            }

            // Fee Item
            SObject item =
                itemByFee.get(row.Id);

            if (item != null) {

                row.feeName =
                    (String)item.get(
                        RTFI_NAME_FIELD
                    );

                row.feeAmount =
                    toDecimal(
                        item.get(
                            RTFI_AMOUNT_FIELD
                        )
                    );
            }

            response.records.add(row);
        }

        /*
         * If Fee Name was requested as the sort column,
         * sort the returned page in Apex.
         *
         * For very large datasets, the preferred solution is
         * to expose a proper child relationship and sort in SOQL.
         */
        if (sortBy == 'feeName') {

            response.records.sort(
                new LateFeeNameComparator(
                    sortDirection
                )
            );
        }

        return response;

    } catch (Exception e) {

        System.debug(
            LoggingLevel.ERROR,
            'getLateFeeManagementRecords error: ' +
            e.getMessage()
        );

        throw new AuraHandledException(
            'Unable to load late fee records.'
        );
    }
}
public class LateFeeNameComparator
    implements System.Comparator<PHOCSLateFeeManagementRow> {

    private Boolean descending;

    public LateFeeNameComparator(
        String sortDirection
    ) {

        descending =
            'desc'.equalsIgnoreCase(
                sortDirection
            );
    }

    public Integer compare(
        PHOCSLateFeeManagementRow a,
        PHOCSLateFeeManagementRow b
    ) {

        String aValue =
            a.feeName == null
                ? ''
                : a.feeName.toLowerCase();

        String bValue =
            b.feeName == null
                ? ''
                : b.feeName.toLowerCase();

        Integer result =
            aValue.compareTo(bValue);

        return descending
            ? result * -1
            : result;
    }
}

    
// ============================================================
// LATE FEE ELIGIBLE IDS
// ============================================================

private static Set<Id> getEligibleLateFeeIds(
    String type,
    String feeName,
    String feeType
) {

    FeeQueryContext context =
        buildFeeQueryContext(
            type,
            feeName,
            feeType
        );

    addLateFeeEligibility(context);

    if (RTFRecordTypeId != null) {

        context.whereClause +=
            ' AND RecordTypeId = :lateFeeRecordTypeId';

        context.binds.put(
            'lateFeeRecordTypeId',
            RTFRecordTypeId
        );
    }

    String soql =
        'SELECT Id ' +
        'FROM ' +
        RTF_OBJECT +
        ' WHERE ' +
        context.whereClause;

    List<SObject> records =
        Database.queryWithBinds(
            soql,
            context.binds,
            AccessLevel.USER_MODE
        );

    Set<Id> result =
        new Set<Id>();

    for (SObject record : records) {

        result.add(
            (Id)record.get('Id')
        );
    }

    return result;
}

// ============================================================
// COMMON PAYMENT / LATE FEE FILTERS
// ============================================================

private class FeeQueryContext {

    public String whereClause;
    public Map<String, Object> binds;

    public FeeQueryContext() {
        whereClause = '';
        binds = new Map<String, Object>();
    }
}


/**
 * Builds the common filters used by Payment Reminders
 * and Late Fee Management.
 *
 * Late Fee specific conditions are added separately.
 */
private static FeeQueryContext buildFeeQueryContext(
    String type,
    String feeName,
    String feeType
) {

    FeeQueryContext context = new FeeQueryContext();

    List<String> conditions = new List<String>();

    conditions.add('Status__c IN (\'Due\', \'Partially Paid\')'
    );

    if (String.isNotBlank(type)) {

        conditions.add(
            'Account.Type = :type'
        );

        context.binds.put(
            'type',
            type.trim()
        );
    }

    if (String.isNotBlank(feeType)) {

        conditions.add(
            RTF_FEETYPE_FIELD +
            ' = :feeType'
        );

        context.binds.put(
            'feeType',
            feeType.trim()
        );
    }

    if (String.isNotBlank(feeName)) {

        conditions.add(
            'Id IN (' +
                'SELECT ' +
                RTFI_PARENT_FIELD +
                ' FROM ' +
                RTFI_OBJECT +
                ' WHERE ' +
                RTFI_NAME_FIELD +
                ' LIKE :feeNameFilter' +
            ')'
        );

        context.binds.put(
            'feeNameFilter',
            '%' + feeName.trim() + '%'
        );
    }

    context.whereClause =
        String.join(conditions, ' AND ');

    return context;
}
/**
 * Adds Late Fee-specific eligibility rules.
 *
 * Eligible:
 *   Status = Due OR Partially Paid
 *   DueDate is before today
 *
 * Excluded:
 *   Any RTF that already has a RegulatoryTrxnFeeItem
 *   named "Late Fee"
 */
private static void addLateFeeEligibility(
    FeeQueryContext context
) {

    context.whereClause +=
        ' AND DueDate < TODAY';

    context.whereClause +=
        ' AND Id NOT IN (' +
            'SELECT ' +
            RTFI_PARENT_FIELD +
            ' FROM ' +
            RTFI_OBJECT +
            ' WHERE ' +
            RTFI_NAME_FIELD +
            ' = :lateFeeItemName' +
        ')';

    context.binds.put(
        'lateFeeItemName',
        RTFI_LATE_FEE_NAME
    );
}
private static String getLateFeeOrderBy(
    String sortBy,
    String sortDirection
) {

    Map<String, String> allowedSortFields =
        new Map<String, String>{

            'parentAccountName' =>
                'Account.Parent.Name',

            'accountName' =>
                'Account.Name',

            'postalCode' =>
                'Account.Physical_Address__PostalCode__s',

            'blaId' =>
                'ParentRecordId',

            'feeId' =>
                'Id',

            'feeAmount' =>
                'Id',

            'dueDate' =>
                'DueDate',

            'operatingMonths' =>
                'Account.OperatingMonths__c',

            'multiplePremise' =>
                'Account.MultiplePremiseFacility__c',

            'premiseRole' =>
                'Account.' + PREMISE_ROLE_FIELD
        };

    String direction =
        'desc'.equalsIgnoreCase(sortDirection)
            ? 'DESC'
            : 'ASC';

    /*
     * Fee Name requires the child Fee Item.
     *
     * If RegulatoryTrxnFee has a known child relationship
     * in your org, use it here.
     *
     * Otherwise we sort Fee Name in Apex after retrieving
     * the page.
     */
    if (sortBy == 'feeName') {
        return 'Id ' + direction;
    }

    String field =
        allowedSortFields.containsKey(sortBy)
            ? allowedSortFields.get(sortBy)
            : 'Account.Name';

    return field + ' ' + direction;
}


private static Integer triggerPaymentReminderEmails(
    List<RegulatoryTrxnFee> fees
) {
    if (fees == null || fees.isEmpty()) {
        return 0;
    }

    for (RegulatoryTrxnFee fee : fees) {
        fee.PaymentReminder__c =
            PAYMENT_REMINDER_SEND;
    }

    Database.SaveResult[] results =
        Database.update(
            fees,
            false
        );

    Integer successCount = 0;

    for (Database.SaveResult result : results) {

        if (result.isSuccess()) {
            successCount++;
        } else {
            throw new AuraHandledException(
                'Unable to trigger payment reminder: ' +
                result.getErrors()[0].getMessage()
            );
        }
    }

    return successCount;
}

// ============================================================
// SEND LATE FEES
// ============================================================

@AuraEnabled
public static OperationResponse sendLateFees(
    String type,
    String feeName,
    String feeType,
    List<Id> deselectedFeeIds,
    Decimal lateFeeAmount
) {

    try {

        // ----------------------------------------------------
        // Validate Amount
        // ----------------------------------------------------

        if (lateFeeAmount == null || lateFeeAmount <= 0 ) {
            return new OperationResponse(
                false,
                'Late Fee Amount must be greater than 0.00$'
            );
        }

        // ----------------------------------------------------
        // Validate Decimal Precision
        // ----------------------------------------------------

        lateFeeAmount = lateFeeAmount.setScale(
                2,
                RoundingMode.HALF_UP
            );

        // ----------------------------------------------------
        // Build the eligible set server-side
        // ----------------------------------------------------

        Set<Id> eligibleFeeIds = getEligibleLateFeeIds( type, feeName, feeType);

        if (eligibleFeeIds.isEmpty()) {
            return new OperationResponse(
                false,
                'No eligible late fee records were found.'
            );
        }

        // ----------------------------------------------------
        // Remove user-deselected records
        // ----------------------------------------------------

        if (deselectedFeeIds != null && !deselectedFeeIds.isEmpty()) {

            eligibleFeeIds.removeAll(
                new Set<Id>(
                    deselectedFeeIds
                )
            );
        }

        if (eligibleFeeIds.isEmpty()) {

            return new OperationResponse(
                false,
                'No eligible late fee records were selected.'
            );
        }

        // ----------------------------------------------------
        // Revalidate immediately before processing
        // ----------------------------------------------------

        List<RegulatoryTrxnFee> fees =
            queryEligibleLateFeesForSending(
                eligibleFeeIds
            );

        if (fees.isEmpty()) {

            return new OperationResponse(
                false,
                'No selected fees are still eligible for late fees.'
            );
        }

        // ----------------------------------------------------
        // Create Late Fee Items
        // ----------------------------------------------------

        List<RegulatoryTrxnFeeItem> itemsToInsert = new List<RegulatoryTrxnFeeItem>();
        Map<Id, RegulatoryTrxnFee> feeById = new Map<Id, RegulatoryTrxnFee>(fees);

        for (RegulatoryTrxnFee fee : fees) {
            RegulatoryTrxnFeeItem lateFeeItem =      new RegulatoryTrxnFeeItem();
            lateFeeItem.RegulatoryTrxnFeeId = fee.Id;
            lateFeeItem.RecordTypeId = RTFItemRecordTypeId;
            lateFeeItem.Name = RTFI_LATE_FEE_NAME;
            lateFeeItem.Status__c = RTF_STATUS_DUE;
            lateFeeItem.FeeAmount =  lateFeeAmount;

            /*
             * If your RTFI has FeeType__c and it is required,
             * set it here according to your org's picklist.
             *
             * Example:
             *
             * lateFeeItem.FeeType__c =
             *     RTF_FEE_TYPE_REGULATORY_TRANSACTION;
             */

            itemsToInsert.add(
                lateFeeItem
            );
        }

        // ----------------------------------------------------
        // Insert Late Fee Items
        // ----------------------------------------------------

        Database.SaveResult[] itemResults =
            Database.insert(
                itemsToInsert,
                false
            );

        Set<Id> successfullyProcessedFeeIds =
            new Set<Id>();

        List<String> errors =
            new List<String>();

        for (
            Integer i = 0;
            i < itemResults.size();
            i++
        ) {

            Database.SaveResult result =
                itemResults[i];

            RegulatoryTrxnFeeItem item =
                itemsToInsert[i];

            if (result.isSuccess()) {

                successfullyProcessedFeeIds.add(
                    item.RegulatoryTrxnFeeId
                );

            } else {

                for (
                    Database.Error error :
                    result.getErrors()
                ) {

                    errors.add(
                        'Fee ' +
                        item.RegulatoryTrxnFeeId +
                        ': ' +
                        error.getMessage()
                    );
                }
            }
        }

        // ----------------------------------------------------
        // No items were created
        // ----------------------------------------------------

        if (
            successfullyProcessedFeeIds.isEmpty()
        ) {

            return new OperationResponse(
                false,
                'No late fees were generated.'
            );
        }

        // ----------------------------------------------------
        // Trigger existing email automation
        // ----------------------------------------------------

        List<RegulatoryTrxnFee>
            feesToNotify =
                new List<RegulatoryTrxnFee>();

        for (
            Id feeId :
            successfullyProcessedFeeIds
        ) {

            RegulatoryTrxnFee fee =
                feeById.get(feeId);

            if (fee == null) {
                continue;
            }

            /*
             * IMPORTANT:
             *
             * Do not duplicate the existing contact/email
             * logic here.
             *
             * Set the existing automation-driving picklist.
             */
            fee.put(
                RTF_NOTIFICATION_FIELD,
                PAYMENT_REMINDER_LATE_FEE_VALUE
            );

            feesToNotify.add(fee);
        }

        // ----------------------------------------------------
        // Update notification flag
        // ----------------------------------------------------

        Database.SaveResult[] notificationResults =
            Database.update(
                feesToNotify,
                false
            );

        Integer notificationCount = 0;

        for (
            Database.SaveResult result :
            notificationResults
        ) {

            if (result.isSuccess()) {

                notificationCount++;

            } else {

                for (
                    Database.Error error :
                    result.getErrors()
                ) {

                    errors.add(
                        error.getMessage()
                    );
                }
            }
        }

        // ----------------------------------------------------
        // Response
        // ----------------------------------------------------

        if (notificationCount == 0) {

            return new OperationResponse(
                true,
                'Late fees have been generated, but emails could not be queued.'
            );
        }

        String message =
            'Late fees have been generated and emails will be sent to contact(s) on the selected facilities';

        /*
         * Do not expose internal DML details to the end user.
         *
         * Log them instead.
         */
        if (!errors.isEmpty()) {

            System.debug(
                LoggingLevel.ERROR,
                'sendLateFees partial errors: ' +
                String.join(errors, ' | ')
            );
        }

        return new OperationResponse(
            true,
            message
        );

    } catch (Exception e) {

        System.debug(
            LoggingLevel.ERROR,
            'sendLateFees error: ' +
            e.getMessage()
        );

        return new OperationResponse(
            false,
            'Unable to send late fees.'
        );
    }
}


private static List<RegulatoryTrxnFee>
    queryEligibleLateFeesForSending(
        Set<Id> feeIds
    ) {

    if (feeIds == null || feeIds.isEmpty()) {

        return new List<RegulatoryTrxnFee>();
    }

    String soql =
        'SELECT Id, Status__c , ' +
        RTF_ACCOUNT_FIELD + ', ' +
        'ParentRecordId, ' +
        'DueDate ' +
        'FROM RegulatoryTrxnFee WHERE Id IN :feeIds' +

        ' AND Status__c IN (\'Due\', \'Partially Paid\')' +

        ' AND DueDate < TODAY' +

        ' AND Id NOT IN (' +
            'SELECT ' +
            RTFI_PARENT_FIELD +
            ' FROM RegulatoryTrxnFeeItem WHERE ' +
            RTFI_NAME_FIELD +
            ' = :lateFeeItemName' +
        ')';

    Map<String, Object> binds =
        new Map<String, Object>{
            'feeIds' => feeIds,
            'lateFeeItemName' =>
                RTFI_LATE_FEE_NAME
        };

    return (List<RegulatoryTrxnFee>)
        Database.queryWithBinds(
            soql,
            binds,
            AccessLevel.USER_MODE
        );
}                 
                        
  // ============================================================
 // ACCOUNT HELPERS
 // ============================================================
private static Map<Id, Account> getAccounts(Set<Id> accountIds) {
    //Map<Id,Account> retmap = new Map<Id,Account>();
    if (accountIds.isEmpty()) {
        return new Map<Id, Account>();
    }
    
    String soql ='SELECT Id, Name, Parent.Name, Type, ' +
                    POSTAL_CODE_FIELD + ', ' +
                    'MultiplePremiseFacility__c, ' +
                    PREMISE_ROLE_FIELD +
                    ' FROM Account WHERE Id IN :accountIds';

                Map<String, Object> bindVars = new Map<String, Object>{
                    'accountIds' => accountIds
                };

                return new Map<Id, Account>(
                    (List<Account>)Database.queryWithBinds(
                        soql,
                        bindVars,
                        AccessLevel.USER_MODE
                    )
                );
}


private static List<PhocsBLRenewalManagementHelper.PicklistOption> getAccountTypeOptions() {
    
    List<PhocsBLRenewalManagementHelper.PicklistOption> options = new List<PhocsBLRenewalManagementHelper.PicklistOption>();
    
    Schema.DescribeFieldResult describe = Account.Type.getDescribe();
    
    for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
        if (entry.isActive() && ACCOUNTTYPES.contains(entry.getLabel())) {
            options.add(
                new PhocsBLRenewalManagementHelper.PicklistOption(
                    entry.getLabel(),
                    entry.getValue()
                )
            );
        }
    }
    
    return options;
}


private static List<PhocsBLRenewalManagementHelper.PicklistOption> getPremiseRoleOptions() {
    
    List<PhocsBLRenewalManagementHelper.PicklistOption> options = new List<PhocsBLRenewalManagementHelper.PicklistOption>();
    
    Schema.SObjectField field = Account.SObjectType.getDescribe().fields.getMap()
    .get(PREMISE_ROLE_FIELD);
    
    if (field == null) {
        return options;
    }
    
    Schema.DescribeFieldResult describe = field.getDescribe();
    
    for (Schema.PicklistEntry entry : describe.getPicklistValues()) {
        if (entry.isActive()) {
            options.add(
                new PhocsBLRenewalManagementHelper.PicklistOption(
                    entry.getLabel(),
                    entry.getValue()
                )
            );
        }
    }
    
    return options;
}

private static List<PhocsBLRenewalManagementHelper.PicklistOption> getFeeTypeOptions() {

    List<PhocsBLRenewalManagementHelper.PicklistOption> options =
        new List<PhocsBLRenewalManagementHelper.PicklistOption>();

    Schema.SObjectType rtfType =
        Schema.getGlobalDescribe()
            .get(RTF_OBJECT);

    if (rtfType == null) {
        return options;
    }

    Map<String, Schema.SObjectField> fields =
        rtfType.getDescribe()
            .fields
            .getMap();

    Schema.SObjectField feeTypeField =
        fields.get(RTF_FEETYPE_FIELD);

    if (feeTypeField == null) {
        return options;
    }

    for (
        Schema.PicklistEntry entry :
        feeTypeField.getDescribe()
            .getPicklistValues()
    ) {
        if (entry.isActive()) {

            options.add(
                new PhocsBLRenewalManagementHelper.PicklistOption(
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

public class ParentAccountComparator implements System.Comparator<PHOCSSendRenewalsRow> {                            
    public Integer compare( PHOCSSendRenewalsRow a, PHOCSSendRenewalsRow b) {
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