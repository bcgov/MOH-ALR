// ============================================================
// PAYMENT REMINDER WRAPPERS
// ============================================================

public class PHOCSRenewalPaymentReminderResponse {

    @AuraEnabled public List<PHOCSPaymentReminderRow> records;
    @AuraEnabled public Integer totalCount;
    @AuraEnabled public Integer pageNumber;
    @AuraEnabled public Integer pageSize;
    @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> accountTypeOptions;
    @AuraEnabled public List<PhocsBLRenewalManagementHelper.PicklistOption> feeTypeOptions;

    public PHOCSRenewalPaymentReminderResponse() {
        records = new List<PHOCSPaymentReminderRow>();
        totalCount = 0;
        pageNumber = 1;
        pageSize = 50;
    }
}