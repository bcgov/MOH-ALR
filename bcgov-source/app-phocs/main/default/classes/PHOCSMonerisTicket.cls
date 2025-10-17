/**
 * ================================================================================================
 *  CLASS NAME      : PHOCSMonerisTicket
 *  DESCRIPTION     :
 *      This Apex utility class handles ticket generation for the Moneris Payment Gateway
 *      integration within the PHOCS (Public Health Operating Compliance System) Salesforce
 *      application.
 *
 *      It performs an HTTP POST callout to the Moneris Checkout API (using Named Credential:
 *      'Moneris') to generate a unique "ticket" for initiating a checkout transaction.
 *      The ticket serves as a secure, time-bound reference identifier required by the Moneris
 *      Hosted Checkout or Hosted Tokenization workflows.
 *
 *  FUNCTIONALITY   :
 *      - Builds and sends a payload to Moneris 'preload' API endpoint
 *      - Parses the Moneris JSON response to extract the 'ticket' value
 *      - Validates Moneris response codes and handles exceptions gracefully
 *      - Uses Salesforce Named Credential for endpoint and authentication management
 *
 *  EXAMPLE USAGE   :
 *      PHOCSMonerisConfiguration__mdt moneris = [SELECT Store_ID__c, API_Token__c, Checkout_Id__c, Environment__c 
 *                                                 FROM PHOCSMonerisConfiguration__mdt 
 *                                                 WHERE MasterLabel = 'VCH' LIMIT 1];
 *      String orderNo = 'ORDER-20251014-075904-38472';
 *      Decimal totalAmount = 2500.00;
 *      String ticket = PHOCSMonerisTicket.generateTicket(moneris, orderNo, totalAmount);
 *      System.debug('Generated Ticket: ' + ticket);
 *
 *  IMPLEMENTED BY  : Pawan Atri
 *  IMPLEMENTED ON  : 14-Oct-2025
 *  RELATED TICKET  : EHIS-248
 * ================================================================================================
 */
public class PHOCSMonerisTicket {
    
    /**
     * Performs an HTTP callout to Moneris to generate a checkout ticket
     *
     * @param moneris  - PHOCSMonerisConfiguration__mdt record containing Moneris credentials
     * @param orderNo  - Unique order number for the transaction
     * @param totalAmt - Total transaction amount
     * @return String  - Moneris checkout ticket
     */
    public static String generateTicket(PHOCSMonerisConfiguration__mdt moneris, String orderNo, Decimal totalAmt) {                   
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
            System.debug(res);
            System.debug('Moneris Response: ' + res.getBody());
        } catch (Exception e) {
            //System.debug(e);
            //System.debug('Callout failed: ' + e.getMessage());
            throw new AuraHandledException('Callout failed: ' + e.getMessage());
        }
        
        if (res.getStatusCode() != 200) {
            //System.debug('Moneris returned HTTP ' + res.getStatusCode() + ' ' + res.getStatus());
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
                    //System.debug('Moneris did not return a ticket: ' + JSON.serialize(resp));
                    throw new AuraHandledException('Moneris did not return a ticket: ' + JSON.serialize(resp));
                }
            } else {
                //System.debug('Unexpected Moneris response: ' + res.getBody());
                throw new AuraHandledException('Unexpected Moneris response: ' + res.getBody());
            }
        } catch (Exception parseErr) {
            //System.debug('Response parse error: ' + parseErr.getMessage() + ' Body: ' + res.getBody());
            throw new AuraHandledException('Response parse error: ' + parseErr.getMessage() + ' Body: ' + res.getBody());
        }
    }
    
    /**
     * Builds payload structure for Moneris checkout ticket generation
     *
     * @param moneris  - PHOCSMonerisConfiguration__mdt record
     * @param orderNo  - Unique order number
     * @param totalAmt - Transaction amount
     * @return Map<String, Object> - JSON payload for Moneris API
     */
    public static Map<String, Object> getPayload(PHOCSMonerisConfiguration__mdt moneris, String orderNo, Decimal totalAmt) {        
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