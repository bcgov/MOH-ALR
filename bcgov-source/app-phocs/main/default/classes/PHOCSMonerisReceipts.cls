public class PHOCSMonerisReceipts {
    public static MonerisReceiptWrapper captureReceiptStatus(PHOCSMonerisConfiguration__mdt moneris, String ticket, String status){
        Map<String, Object> payload = new Map<String, Object>{
            'store_id'    => moneris.Store_ID__c,
                'api_token'   => moneris.API_Token__c,
                'checkout_id' => moneris.Checkout_Id__c,
                'environment' => moneris.Environment__c,
                'action'      => 'receipt',
                'ticket'      => ticket
                };
                    
                    HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Moneris/chktv2/request/request.php');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
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
            MonerisReceiptWrapper wrapper = MonerisReceiptWrapper.parse(res.getBody());
            return wrapper;
        } catch (Exception parseErr) {
            throw new AuraHandledException('Response parse error: ' + parseErr.getMessage() + ' Body: ' + res.getBody());
        }
    }    
}