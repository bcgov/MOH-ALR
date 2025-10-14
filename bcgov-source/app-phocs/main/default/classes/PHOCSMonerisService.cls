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
            transFee.PHOCSMonerisTicketNumber__c = ticket;
        }
        return ticket;
    }
    
    public static RegulatoryTrxnFee getRegulatoryTransFee(Id recordId){
        return [select Id, 
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
    
    public static void checkReceiptStatus(){
        
    }
    
	@future
    public static void updateRegulatoryTransFee(String recordId, String ticket, String reference){
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);
        if(ticket != null && ticket != '')
            transFee.PHOCSMonerisTicketNumber__c = ticket;
        if(reference != null && reference != '')
            transFee.ReferenceNumber__c = Reference;
        update transFee;
    }
}