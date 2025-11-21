public with sharing class PHOCSPaymentController {
    
    private static final string GLOBAL_PAY = 'GlobalPay';
    private static final string MONERIS_PAY = 'Moneris';
    
    @AuraEnabled(cacheable=true) 
    public static PaymentSystemResponse getPaymentSystemRedirectInfo(Id regulatoryTransactionFeeId) {
        PaymentSystemResponse res = new PaymentSystemResponse();
        if (string.isNotBlank(regulatoryTransactionFeeId)) {
            RegulatoryTrxnFee[] regulatoryTrxnFees = [select Id, Account.HealthAuthority__c from RegulatoryTrxnFee where Id=:regulatoryTransactionFeeId];
            if(!regulatoryTrxnFees.isEmpty() &&  string.isNotBlank(regulatoryTrxnFees[0].Account.HealthAuthority__c)){

                string healthAuth =regulatoryTrxnFees[0].Account.HealthAuthority__c;
                PHOCSHealthAuthorityPaymentSetting__mdt paymentSettings = [SELECT Id, PaymentSystem__c, HealthAuthority__c 
                                                                           FROM PHOCSHealthAuthorityPaymentSetting__mdt 
                                                                           WHERE HealthAuthority__c = :healthAuth LIMIT 1];
                res.useMoneris = paymentSettings.PaymentSystem__c == MONERIS_PAY;
                res.useGlobalPay = paymentSettings.PaymentSystem__c == GLOBAL_PAY;
            }
        }
        return res;
    }
	
    
    public Class PaymentSystemResponse{
         @AuraEnabled public boolean useMoneris;
         @AuraEnabled public boolean useGlobalPay;
    }
}