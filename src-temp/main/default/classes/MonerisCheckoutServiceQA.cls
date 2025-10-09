public with sharing class MonerisCheckoutServiceQA {

    @AuraEnabled(cacheable=false)
    public static String createCheckoutTicket(Decimal amount) {
        // ✅ Always point to Moneris QA endpoint
        String endpoint = 'https://gatewayt.moneris.com/chktv2/request/request.php';
        String env = 'qa';

        // ✅ Generate random order number (unique per transaction)
        // Format example: ORDER-20251008-38472
        String randomSuffix = String.valueOf(Math.abs(Crypto.getRandomInteger())).
                              substring(0,5);
        String orderNo = 'ORDER-' + DateTime.now().format('yyyyMMdd-HHmmss') + '-' + randomSuffix;

        // ✅ Payload for Moneris Preload request
        Map<String, Object> payload = new Map<String, Object>{
            'store_id'    => 'monca12327',
            'api_token'   => 'E3IIALskJsDtsIT76CVG',
            'checkout_id' => 'chktA5DVS12327',
            'environment' => env,
            'action'      => 'preload',
            'order_no'    => orderNo,
            'txn_total'   => String.valueOf(amount.setScale(2))
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res;

        try {
            res = http.send(req);
            System.debug('➡️ Moneris QA Response: ' + res.getBody());
        } catch (Exception e) {
            throw new AuraHandledException('QA callout failed: ' + e.getMessage());
        }

        if (res.getStatusCode() != 200) {
            throw new AuraHandledException('Moneris QA returned HTTP ' + res.getStatusCode() + ' ' + res.getStatus());
        }

        try {
            Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            if (parsed.containsKey('response')) {
                Map<String, Object> resp = (Map<String, Object>) parsed.get('response');
                if (resp.containsKey('ticket')) {
                    System.debug('✅ Moneris QA Ticket generated for ' + orderNo);
                    return (String) resp.get('ticket');
                } else {
                    throw new AuraHandledException('Moneris QA did not return a ticket: ' + JSON.serialize(resp));
                }
            } else {
                throw new AuraHandledException('Unexpected Moneris QA response: ' + res.getBody());
            }
        } catch (Exception parseErr) {
            throw new AuraHandledException('Response parse error: ' + parseErr.getMessage() + ' Body: ' + res.getBody());
        }
    }
}