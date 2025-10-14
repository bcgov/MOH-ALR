public with sharing class MonerisCheckoutServiceQA {
    static RegulatoryTrxnFee transFee;
    static Map<String, PHOCSMonerisConfiguration__mdt> monerisConfig;// = new Map<String, PHOCSMonerisConfiguration__mdt>();
    
    static{
        if(monerisConfig == null){
            monerisConfig = new Map<String, PHOCSMonerisConfiguration__mdt>();
            for(PHOCSMonerisConfiguration__mdt moneris : [SELECT Id, DeveloperName, Store_ID__c, API_Token__c, Checkout_Id__c, Endpoints__c, HealthAuthority__c, Environment__c FROM PHOCSMonerisConfiguration__mdt]){
                monerisConfig.put(moneris.HealthAuthority__c, moneris);
            }
        }
    }
    
    
    static Map<String, Object> payload;
    
    @AuraEnabled(cacheable=false)
    public static String createCheckoutTicket(String recordId, Decimal amount) {
        PHOCSMonerisConfiguration__mdt moneris;
        System.debug('RecordId : ' + recordId);
        System.debug('Amount : ' + amount);
        
        transFee = getRegulatoryTransFee(recordId);
        if(transFee == null || transFee.Account == null || transFee.Account.HealthAuthority__c == ''){
            throw new AuraHandledException('Please provide a valid transation ID');
        }
        
        moneris = monerisConfig.get(transFee.Account.HealthAuthority__c);
        System.debug(moneris);
        String endpoint = moneris.Endpoints__c;
        
        // Generate random order number (unique per transaction)
        // Format example: ORDER-20251008-38472
        String randomSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0,5);
        String orderNo = 'ORDER-' + DateTime.now().format('yyyyMMdd-HHmmss') + '-' + randomSuffix;
        
        setPayload(moneris, orderNo, amount);
        
        String ticket;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        
        System.debug('Payload: ' + payload);
        System.debug('Request: ' + req);
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
            System.debug('Moneris Response: ' + res.getBody());
        } catch (Exception e) {
            throw new AuraHandledException('Callout failed: ' + e.getMessage());
        }
        
        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Moneris returned HTTP ' + res.getStatusCode() + ' ' + res.getStatus());
        }
        
        try {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (parsed.containsKey('response')) {
                Map<String, Object> resp = (Map<String, Object>) parsed.get('response');
                if (resp.containsKey('ticket')) {                    
                    ticket = (String) resp.get('ticket');
                    updateRegulatoryTransFee(ticket);
                    return ticket;
                } else {
                    throw new AuraHandledException('Moneris did not return a ticket: ' + JSON.serialize(resp));
                }
            } else {
                throw new AuraHandledException('Unexpected Moneris response: ' + res.getBody());
            }
        } catch (Exception parseErr) {
            throw new AuraHandledException('Response parse error: ' + parseErr.getMessage() + ' Body: ' + res.getBody());
        }
    }
    
    public static void updateRegulatoryTransFee(String ticket){
        transFee.PHOCSMonerisTicketNumber__c = ticket;
        update transFee;
    }
    
    public static RegulatoryTrxnFee getRegulatoryTransFee(Id recordId){
        if(transFee == null){
            transFee = [select Id, AccountId, Account.HealthAuthority__c, Account.AccountNumberRTPrefixed__c, Account.AccountNumber, Account.AccountNumberAuto__c, TotalFeeAmount, ReferenceNumber__c, PHOCSMonerisTicketNumber__c from RegulatoryTrxnFee where Id =: recordId limit 1];
        }
        return transFee;
    }
    
    
    // Payload for Moneris Preload request
    public static void setPayload(PHOCSMonerisConfiguration__mdt moneris, String orderNo, Decimal totalAmt){        
        payload = new Map<String, Object>{
            'store_id'    => moneris.Store_ID__c,
                'api_token'   => moneris.API_Token__c,
                'checkout_id' => moneris.Checkout_Id__c,
                'environment' => moneris.Environment__c,
                'action'      => 'preload',
                'order_no'    => orderNo,
                'txn_total'   => String.valueOf(totalAmt.setScale(2))
                };
                    }
    
    @AuraEnabled(cacheable=false)
    public static void capturePaymentStatus(String recordId, String status){
        
        PHOCSMonerisConfiguration__mdt moneris;
        List<RegulatoryTrxnFee> transFees = new List<RegulatoryTrxnFee>();
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);
        
        if(transFee == null || transFee.Account == null || transFee.Account.HealthAuthority__c == ''){
            throw new AuraHandledException('Please provide a valid transation ID');
        }
        
        moneris = monerisConfig.get(transFee.Account.HealthAuthority__c);
        
        Map<String, Object> payload = new Map<String, Object>{
            'store_id'    => moneris.Store_ID__c,
                'api_token'   => moneris.API_Token__c,
                'checkout_id' => moneris.Checkout_Id__c,
                'environment' => moneris.Environment__c,
                'action'      => 'receipt',
                'ticket'      => transFee.PHOCSMonerisTicketNumber__c
                };
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://gatewayt.moneris.com/chkt/request/request.php');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        Http http = new Http();
        HttpResponse res;
        
        res = http.send(req);
        MonerisReceiptWrapper wrapper = MonerisReceiptWrapper.parse(res.getBody());
        
        transFee.PaymentDate__c = Date.today();
        transFee.Status = status;
        transFee.ReferenceNumber__c = wrapper.response.receipt.cc.reference_no;
        transFees.add(transFee);
        if(transFees!= null && transFees.size() > 0){
            try{
                update transFees; 
            }
            catch (Exception parseErr) {
                throw new AuraHandledException('Exception Type: ' + parseErr.getTypeName() + ' Message: ' + parseErr.getMessage() + ' at Line: ' + parseErr.getLineNumber() + ' Cause: ' + parseErr.getCause());
            }
        }
    }
    
}