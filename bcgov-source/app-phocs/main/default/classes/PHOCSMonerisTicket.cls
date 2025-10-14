/*

*/
public class PHOCSMonerisTicket {
    
    public static String generateTicket(PHOCSMonerisConfiguration__mdt moneris, String orderNo, Decimal totalAmt){                   
        String ticket;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Moneris/chktv2/request/request.php');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(getPayload(moneris, orderNo, totalAmt)));
        
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
    
    public static Map<String, Object> getPayload(PHOCSMonerisConfiguration__mdt moneris, String orderNo, Decimal totalAmt){        
        return new Map<String, Object>{
            'store_id'    => moneris.Store_ID__c,
                'api_token'   => moneris.API_Token__c,
                'checkout_id' => moneris.Checkout_Id__c,
                'environment' => moneris.Environment__c,
                'action'      => 'preload',
                'order_no'    => orderNo,
                'txn_total'   => String.valueOf(totalAmt.setScale(2))
                };
                    }

}