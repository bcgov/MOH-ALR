public class PhocsLateFeeGenerationBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Set<Id> feeIds;
    private Decimal lateFeeAmount;
	private static final String RTFI_LATE_FEE_NAME = 'Late Fee';
    private static final String PAYMENT_REMINDER_LATE_FEE_VALUE = 'Send Late Fee';
    private static final String RTF_NOTIFICATION_FIELD = 'PaymentReminder__c';
    private static final Id RTFItemRecordTypeId = Schema.SObjectType.RegulatoryTrxnFeeItem.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFeeItem').getRecordTypeId();
    
    public PhocsLateFeeGenerationBatch(Set<Id> feeIds, Decimal lateFeeAmount) {
        this.feeIds = feeIds;
        this.lateFeeAmount = lateFeeAmount;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status__c, ParentRecordId, DueDate
            FROM RegulatoryTrxnFee
            WHERE Id IN :feeIds
            AND Status__c IN ('Due', 'Partially Paid')
            AND DueDate < TODAY
            AND Id NOT IN (
                SELECT RegulatoryTrxnFeeId
                FROM RegulatoryTrxnFeeItem
                WHERE Name = :RTFI_LATE_FEE_NAME
            )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<RegulatoryTrxnFee> scope) {
        List<RegulatoryTrxnFeeItem> itemsToInsert = new List<RegulatoryTrxnFeeItem>();
        Map<Id, RegulatoryTrxnFee> feeById = new Map<Id, RegulatoryTrxnFee>(scope);

        for (RegulatoryTrxnFee fee : scope) {
            RegulatoryTrxnFeeItem lateFeeItem = new RegulatoryTrxnFeeItem();
            lateFeeItem.RegulatoryTrxnFeeId = fee.Id;
            lateFeeItem.RecordTypeId = RTFItemRecordTypeId;
            lateFeeItem.Name = RTFI_LATE_FEE_NAME;
            lateFeeItem.Status__c = 'Due';
            lateFeeItem.FeeAmount = lateFeeAmount;
            itemsToInsert.add(lateFeeItem);
        }

        if (!itemsToInsert.isEmpty()) {
            Database.SaveResult[] itemResults = Database.insert(itemsToInsert, false);

            Set<Id> successfullyProcessedFeeIds = new Set<Id>();
            List<RegulatoryTrxnFee> feesToNotify = new List<RegulatoryTrxnFee>();
            List<String> errors = new List<String>();

            for (Integer i = 0; i < itemResults.size(); i++) {
                Database.SaveResult result = itemResults[i];
                RegulatoryTrxnFeeItem item = itemsToInsert[i];

                if (result.isSuccess()) {
                    successfullyProcessedFeeIds.add(item.RegulatoryTrxnFeeId);
                } else {
                    for (Database.Error error : result.getErrors()) {
                        errors.add('Fee ' + item.RegulatoryTrxnFeeId + ': ' + error.getMessage());
                    }
                }
            }

            for (Id feeId : successfullyProcessedFeeIds) {
                RegulatoryTrxnFee fee = feeById.get(feeId);
                if (fee != null) {
                    fee.put(RTF_NOTIFICATION_FIELD, PAYMENT_REMINDER_LATE_FEE_VALUE);
                    feesToNotify.add(fee);
                }
            }

            if (!feesToNotify.isEmpty()) {
                Database.update(feesToNotify, false);
            }

            if (!errors.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'sendLateFees partial errors: ' + String.join(errors, ' | '));
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional hook for post-processing or notification.
    }
}