public with sharing class MonerisCheckoutService {
    // Apex method to call Moneris Preload API and return a ticket
    @AuraEnabled(cacheable=false)
    public static String createCheckoutTicket(Decimal amount, String orderId) {
        String endpoint;
        String env; 
        endpoint = 'https://gatewayt.moneris.com/chktv2/request/request.php'; 
        env = 'qa';    // QA/test environment:contentReference[oaicite:17]{index=17}
        // Construct JSON payload
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('store_id', 'monca12327');                        // Moneris Store ID
        payload.put('api_token', 'E3IIALskJsDtsIT76CVG');             // Moneris API token
        payload.put('checkout_id', 'chktA5DVS12327');                 // Moneris Checkout profile ID
        payload.put('environment', env);                             // "qa" or "live":contentReference[oaicite:18]{index=18}
        payload.put('action', 'preload');                            // API action for ticket request:contentReference[oaicite:19]{index=19}
        payload.put('order_no', orderId);                            // Your internal order identifier
        // Amount: format as string with two decimals (in dollars). E.g., 49.99 -> "49.99"
        payload.put('txn_total', String.valueOf(amount.setScale(2))); // Transaction total amount:contentReference[oaicite:20]{index=20}
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        
        System.debug('Payload: ' + payload);
        System.debug('Request: ' + req);
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                // Parse JSON response
                Map<String,Object> resMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                /* Moneris returns: { "response": { "success": "true/false", "ticket": "<token>", "error": {..} } }:contentReference[oaicite:21]{index=21} */
                if(resMap.containsKey('response')) {
                    Map<String,Object> resp = (Map<String,Object>) resMap.get('response');
                    if(String.valueOf(resp.get('success')) == 'true') {
                        String ticket = (String) resp.get('ticket');
                        System.debug('Moneris ticket: ' + ticket);
                        return ticket;  // Return the ticket number
                    } else {
                        // Log error details from Moneris
                        String err = JSON.serialize(resp.get('error'));
                        System.debug('Moneris Preload error: ' + err);
                        throw new AuraHandledException('Moneris error: ' + err);
                    }
                } else {
                    throw new AuraHandledException('Unexpected Moneris response format.');
                }
            } else {
                throw new AuraHandledException('Moneris API call failed with HTTP status ' + res.getStatusCode());
            }
        } catch(Exception e) {
            // Handle callout exceptions (time out, etc.)
            System.debug('Exception during Moneris callout: ' + e);
            throw new AuraHandledException('Payment initialization failed. ' + e.getMessage());
        }
    }
}