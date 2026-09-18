public class PhocsRenewalFeeGenerationBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> feeIds;

    public PhocsRenewalFeeGenerationBatch(List<Id> feeIds) {
        this.feeIds = new Set<Id>(feeIds);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c
            FROM RegulatoryTrxnFee
            WHERE Id IN :feeIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<RegulatoryTrxnFee> scope) {
        for (RegulatoryTrxnFee fee : scope) {
            fee.Status__c = 'Due';
            fee.PaymentReminder__c='Send Renewal';
        }

        if (!scope.isEmpty()) {
            update scope;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional hook for post-processing or job notification.
    }
}