public with sharing class MonerisCheckoutService {

    private static final String STORE_ID = 'monca12327';
    private static final String API_TOKEN = 'E3IIALskJsDtsIT76CVG';
    private static final String CHECKOUT_ID = 'chktA5DVS12327';
    private static final String NAMED_CREDENTIAL = 'Moneris_QA';
    private static final String ENDPOINT = 'https://gatewayt.moneris.com/chktv2/request/request.php';

    @AuraEnabled(cacheable=false)
    public static String generateTicket(Decimal amount, String orderNo) {
        Map<String, Object> payload = new Map<String, Object>{
            'store_id'    => STORE_ID,
            'api_token'   => API_TOKEN,
            'checkout_id' => CHECKOUT_ID,
            'txn_total'   => String.valueOf(amount.setScale(2)),
            'environment' => 'qa',
            'action'      => 'preload',
            'order_no'    => orderNo
        };

        System.debug('ENDPOINT :: ' + ENDPOINT);
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(ENDPOINT);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new AuraHandledException('Moneris Preload Failed: ' + res.getBody());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getReceipt(String ticket) {
        Map<String, Object> payload = new Map<String, Object>{
            'store_id'    => STORE_ID,
            'api_token'   => API_TOKEN,
            'checkout_id' => CHECKOUT_ID,
            'action'      => 'receipt',
            'ticket'      => ticket
        };

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(ENDPOINT);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            return res.getBody();
        } else {
            throw new AuraHandledException('Receipt fetch failed: ' + res.getBody());
        }
    }
}