public with sharing class PHOCSPortalPaymentFeeItemService {
    private static final Set<String> PHOCS_ITEM_RECORD_TYPES = new Set<String>{
        'PHOCSRegulatoryTransactionFeeItem',
        'PHOCSNonDairyTransactionFeeItem'
    };
    private static final String PAYMENT_CHANNEL_PORTAL = 'Portal';
    private static final String PAYMENT_STATUS_ERROR = 'Error';
    private static final String STATUS_DUE = 'Due';
    private static final String STATUS_PAID = 'Paid';

    public static void updatePaymentAttempt(
        Id regulatoryTransactionFeeId,
        Boolean isSuccessful,
        String paymentMethod,
        String paymentType,
        String referenceNumber,
        Date paymentDate
    ) {
        if (regulatoryTransactionFeeId == null) {
            return;
        }

        String operatorName = [
            SELECT Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ].Name;

        List<RegulatoryTrxnFeeItem> feeItems = [
            SELECT Id, Status__c, Payment_Method__c, Payment_Type__c,
                   PaymentChannel__c, PaidBy__c, PaymentDate__c,
                   ReferenceNumber__c, PortalPaymentStatus__c
            FROM RegulatoryTrxnFeeItem
            WHERE RegulatoryTrxnFeeId = :regulatoryTransactionFeeId
              AND RecordType.DeveloperName IN :PHOCS_ITEM_RECORD_TYPES
              AND Status__c = :STATUS_DUE
        ];

        for (RegulatoryTrxnFeeItem feeItem : feeItems) {
            feeItem.PaymentChannel__c = PAYMENT_CHANNEL_PORTAL;
            feeItem.PaidBy__c = operatorName;
            if (String.isNotBlank(paymentMethod)) {
                feeItem.Payment_Method__c = paymentMethod;
            }
            if (String.isNotBlank(paymentType)) {
                feeItem.Payment_Type__c = paymentType;
            }

            if (isSuccessful) {
                feeItem.Status__c = STATUS_PAID;
                feeItem.PaymentDate__c = paymentDate == null ? Date.today() : paymentDate;
                if (String.isNotBlank(referenceNumber)) {
                    feeItem.ReferenceNumber__c = referenceNumber;
                }
                feeItem.PortalPaymentStatus__c = null;
            } else {
                feeItem.PortalPaymentStatus__c = PAYMENT_STATUS_ERROR;
            }
        }

        if (!feeItems.isEmpty()) {
            update feeItems;
        }
    }

    public static String normalizePaymentMethod(Boolean isDebit) {
        return isDebit == true ? 'Debit' : 'Credit';
    }

    public static String normalizeCardType(String gatewayCardType) {
        if (String.isBlank(gatewayCardType)) {
            return null;
        }

        String normalizedType = gatewayCardType.trim().toUpperCase();
        if (normalizedType == 'V' || normalizedType == 'VISA') {
            return 'Visa';
        }
        if (normalizedType == 'M' || normalizedType == 'MC' ||
            normalizedType == 'MASTERCARD' || normalizedType == 'MASTER CARD') {
            return 'MasterCard';
        }
        if (normalizedType == 'AX' || normalizedType == 'AMEX' ||
            normalizedType == 'AMERICAN EXPRESS') {
            return 'American Express';
        }
        return null;
    }
}
