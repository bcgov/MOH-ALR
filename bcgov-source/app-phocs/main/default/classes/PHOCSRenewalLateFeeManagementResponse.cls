// ============================================================
// LATE FEE MANAGEMENT WRAPPERS
// ============================================================

public class PHOCSRenewalLateFeeManagementResponse {

    @AuraEnabled public List<PHOCSLateFeeManagementRow> records;
    @AuraEnabled public Integer totalCount;
    @AuraEnabled public Integer pageNumber;
    @AuraEnabled public Integer pageSize;
    @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> accountTypeOptions;
    @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> feeTypeOptions;

    public PHOCSRenewalLateFeeManagementResponse() {
        records = new List<PHOCSLateFeeManagementRow>();
        totalCount = 0;
        pageNumber = 1;
        pageSize = 50;
    }
}