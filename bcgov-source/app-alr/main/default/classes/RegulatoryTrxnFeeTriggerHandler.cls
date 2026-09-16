/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this class is 
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-40              ACN-ALR        Fee calculation for newly added unit(s)
                           EHIS-910            Deepak         added generateInvoiceOnPaymentReminderChange, called separately from the trigger's PHOCS section
                           EHIS-910            Deepak         generateInvoiceOnPaymentReminderChange now bulk-collects qualifying fee Ids and enqueues PHOCSInvoiceGenerationQueueable instead of calling PHOCSInvoiceDetailsService inline
***********************************************************************************************/
public without sharing class RegulatoryTrxnFeeTriggerHandler implements TriggerHandler {
    public static Boolean skipAfterUpdate = false;
    public RegulatoryTrxnFeeTriggerHandler helper;

    private static final Id RT_PHOCS_NON_DAIRY_TRANSACTION_FEE = Schema.SObjectType.RegulatoryTrxnFee.getRecordTypeInfosByDeveloperName().get('PHOCSNonDairyTransactionFee').getRecordTypeId();
    private static final String STATUS_DUE = 'Due';
    private static final String PAYMENT_REMINDER_SEND_RENEWAL = 'Send Renewal';
    private static final String PAYMENT_REMINDER_LATE_FEE_GENERATED = 'Late Fee Generated';

    //beforeInsert
    public void beforeInsert(List<RegulatoryTrxnFee> newRegTransList) {
    }
    //beforeUpdate
    public void beforeUpdate(List<RegulatoryTrxnFee> oldRegTransList, List<RegulatoryTrxnFee> newRegTransList, Map<ID, SObject> oldRegTransMap, Map<ID, SObject> newRegTransMap) {
    }
    //beforeDelete
    public void beforeDelete(List<RegulatoryTrxnFee> oldRegTransList, Map<ID, SObject> oldRegTransMap) {
    }
    //afterInsert
    public void afterInsert(List<RegulatoryTrxnFee> newRegTransList, Map<Id, SObject> newRegTransMap) {
    }
    //afterUpdate
    public void afterUpdate(List<RegulatoryTrxnFee> oldRegTransList, List<RegulatoryTrxnFee> newRegTransList, Map<ID, SObject> oldRegTransMap, Map<ID, SObject> newRegTransMap) {
       if (skipAfterUpdate) {
           return;
       }

       RegulatoryTrxnFeeUtility.updateUnitStatus(newRegTransList, oldRegTransMap, newRegTransMap);
    }
    //afterDelete
    public void afterDelete(List<RegulatoryTrxnFee> oldRegTransList, Map<ID, SObject> oldRegTransMap) {
    }
    //afterUndelete
    public void afterUndelete(List<RegulatoryTrxnFee> oldRegTransList, Map<ID, SObject> newRegTransMap) {
    }

    //PHOCS: generates the invoice PDF when PaymentReminder__c changes to Send Renewal or Late
    //Fee Generated on a Due, PHOCSNonDairyTransactionFee record type fee. Called directly from
    //the trigger's PHOCS section, not from afterUpdate above. Runs asynchronously via
    //PHOCSInvoiceGenerationQueueable so the calling transaction isn't blocked by the per-record
    //SOQL/DML work PHOCSInvoiceDetailsService performs.
    public static void generateInvoiceOnPaymentReminderChange(List<RegulatoryTrxnFee> newRegTransList, Map<Id, SObject> oldRegTransMap) {
        List<Id> feeIdsToGenerateInvoiceFor = new List<Id>();

        for (RegulatoryTrxnFee newFee : newRegTransList) {
            RegulatoryTrxnFee oldFee = (RegulatoryTrxnFee) oldRegTransMap.get(newFee.Id);
            Boolean paymentReminderChanged = (oldFee.PaymentReminder__c != newFee.PaymentReminder__c);
            Boolean statusChanged = (oldFee.Status__c != newFee.Status__c);
            Boolean paymentReminderTriggersInvoice = (newFee.PaymentReminder__c == PAYMENT_REMINDER_SEND_RENEWAL || newFee.PaymentReminder__c == PAYMENT_REMINDER_LATE_FEE_GENERATED);

            if ((paymentReminderChanged || statusChanged) && paymentReminderTriggersInvoice && newFee.Status__c == STATUS_DUE && newFee.RecordTypeId == RT_PHOCS_NON_DAIRY_TRANSACTION_FEE) {
                feeIdsToGenerateInvoiceFor.add(newFee.Id);
            }
        }

        if (!feeIdsToGenerateInvoiceFor.isEmpty()) {
            System.enqueueJob(new PHOCSInvoiceGenerationQueueable(feeIdsToGenerateInvoiceFor));
        }
    }
}