/*

*/
public class PHOCSMonerisService {
    static Map<String, PHOCSMonerisConfiguration__mdt> monerisConfig;
    
    static{
        if(monerisConfig == null){
            monerisConfig = new Map<String, PHOCSMonerisConfiguration__mdt>();
            for(PHOCSMonerisConfiguration__mdt moneris : [SELECT Id, DeveloperName, Store_ID__c, API_Token__c, Checkout_Id__c, Endpoints__c, HealthAuthority__c, Environment__c FROM PHOCSMonerisConfiguration__mdt]){
                monerisConfig.put(moneris.HealthAuthority__c, moneris);
            }
        }
    }
    
    public static String generateTicket(String recordId){
        PHOCSMonerisConfiguration__mdt moneris;
        String ticket;
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);
        if(transFee == null || transFee.Account == null || transFee.Account.HealthAuthority__c == ''){
            throw new AuraHandledException('Please provide a valid transation ID');
        }
        ticket = PHOCSMonerisTicket.generateTicket(monerisConfig.get(transFee.Account.HealthAuthority__c), transFee.Id, transFee.TotalFeeAmount);
        if(ticket != null && ticket != ''){
            updateRegulatoryTransFee(recordId, ticket, null, null);
        }
        return ticket;
    }
    
    public static RegulatoryTrxnFee getRegulatoryTransFee(Id recordId){
        return [select Id,
                Status, 
                AccountId, 
                Account.HealthAuthority__c, 
                Account.AccountNumberRTPrefixed__c, 
                Account.AccountNumber, 
                Account.AccountNumberAuto__c, 
                TotalFeeAmount, 
                ReferenceNumber__c,
                PHOCSMonerisTicketNumber__c 
                from RegulatoryTrxnFee 
                where 
                Id =: recordId limit 1
               ];
    }
    
    public static void checkReceiptStatus(String recordId, String status){
        PHOCSMonerisConfiguration__mdt moneris;
        List<RegulatoryTrxnFee> transFees = new List<RegulatoryTrxnFee>();
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);
        
        if(transFee == null || transFee.Account == null || transFee.Account.HealthAuthority__c == ''){
            throw new AuraHandledException('Please provide a valid transation ID');
        }
        
        if(transFee == null || transFee.PHOCSMonerisTicketNumber__c == ''){
            throw new AuraHandledException('Moneris Ticket is missing for transcation fee');
        }
        
        moneris = monerisConfig.get(transFee.Account.HealthAuthority__c);
        MonerisReceiptWrapper receiptWrapper = PHOCSMonerisReceipts.captureReceiptStatus(monerisConfig.get(transFee.Account.HealthAuthority__c), transFee.PHOCSMonerisTicketNumber__c, status);
        if(receiptWrapper != null){
            updateRegulatoryTransFee(recordId, transFee.PHOCSMonerisTicketNumber__c, receiptWrapper.response.receipt.cc.reference_no, status);
        }
    }
    
    @future
    public static void updateRegulatoryTransFee(String recordId, String ticket, String reference, String status){
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);
        if(ticket != null && ticket != '')
            transFee.PHOCSMonerisTicketNumber__c = ticket;
        if(reference != null && reference != '')
            transFee.ReferenceNumber__c = Reference;
        if(status != null && status != ''){
            transFee.Status = status;
            if(status.equalsIgnoreCase('paid')){
                transFee.PaymentDate__c = Date.today();
            }
        }
        update transFee;
    }
}