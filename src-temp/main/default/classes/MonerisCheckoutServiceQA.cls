public with sharing class MonerisCheckoutServiceQA {
    static RegulatoryTrxnFee transFee;
    static PHOCSMonerisConfiguration__mdt monerisConfig;
    static Map<String, Object> payload;

    @AuraEnabled(cacheable=false)
    public static String createCheckoutTicket(String recordId, Decimal amount) {
        System.debug('RecordId : ' + recordId);
        System.debug('Amount : ' + amount);
        
        transFee = getRegulatoryTransFee(recordId);
        monerisConfig = getMonerisConfig(transFee.Account.HealthAuthority__c);        
        String endpoint = monerisConfig.Endpoints__c;

        // Generate random order number (unique per transaction)
        // Format example: ORDER-20251008-38472
        String randomSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).substring(0,5);
        String orderNo = 'ORDER-' + DateTime.now().format('yyyyMMdd-HHmmss') + '-' + randomSuffix;

        setPayload(orderNo, amount);
            
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
        transFee.ReferenceNumber__c = ticket;
        update transFee;
    }
    
    public static RegulatoryTrxnFee getRegulatoryTransFee(Id recordId){
        if(transFee == null){
            transFee = [select Id, AccountId, Account.HealthAuthority__c, Account.AccountNumberRTPrefixed__c, Account.AccountNumber, Account.AccountNumberAuto__c, TotalFeeAmount, ReferenceNumber__c from RegulatoryTrxnFee where Id =: recordId limit 1];
        }
        return transFee;
    }
    
    public static PHOCSMonerisConfiguration__mdt getMonerisConfig(String healthAuthority){
        if(monerisConfig == null){
            monerisConfig = [SELECT Id, DeveloperName, Store_ID__c, API_Token__c, Checkout_Id__c, Endpoints__c, HealthAuthority__c, Environment__c FROM PHOCSMonerisConfiguration__mdt where HealthAuthority__c =:healthAuthority];
        }
        return monerisConfig;
    }
    
    // Payload for Moneris Preload request
    public static void setPayload(String orderNo, Decimal totalAmt){        
        payload = new Map<String, Object>{
            'store_id'    => monerisConfig.Store_ID__c,
            'api_token'   => monerisConfig.API_Token__c,
            'checkout_id' => monerisConfig.Checkout_Id__c,
            'environment' => monerisConfig.Environment__c,
            'action'      => 'preload',
            'order_no'    => orderNo,
            'txn_total'   => String.valueOf(totalAmt.setScale(2))
        };
    }
}