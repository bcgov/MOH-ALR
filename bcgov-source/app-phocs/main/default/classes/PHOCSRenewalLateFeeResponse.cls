// ============================================================
// LATE FEE MANAGEMENT WRAPPERS
// ============================================================

public class PHOCSRenewalLateFeeResponse {

    @AuraEnabled public List<PHOCSPaymentReminderRow> records;
    @AuraEnabled public Integer totalCount;
    @AuraEnabled public Integer pageNumber;
    @AuraEnabled public Integer pageSize;
    @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> accountTypeOptions;
    @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> feeTypeOptions;

    public PHOCSRenewalLateFeeResponse() {
        records = new List<PHOCSPaymentReminderRow>();
        totalCount = 0;
        pageNumber = 1;
        pageSize = 50;
    }
}