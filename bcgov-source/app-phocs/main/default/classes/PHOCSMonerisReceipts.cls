/**
 * ================================================================================================
 *  CLASS NAME      : PHOCSMonerisReceipts
 *  DESCRIPTION     :
 *      This Apex service class is responsible for retrieving (capturing) the receipt details 
 *      from the Moneris Payment Gateway using a previously generated checkout ticket.
 *
 *      It sends a POST callout to the Moneris Checkout API (via Named Credential: 'Moneris')
 *      with the `action` parameter set to `'receipt'`, along with store credentials and 
 *      the Moneris ticket number. The response is then deserialized into the 
 *      `MonerisReceiptWrapper` class for further processing within Salesforce.
 *
 *  FUNCTIONALITY   :
 *      - Builds a JSON payload to request receipt details from Moneris
 *      - Executes a secure callout using Salesforce Named Credential
 *      - Parses the JSON response using `MonerisReceiptWrapper`
 *      - Returns a strongly typed object containing receipt data such as 
 *        transaction number, approval code, and reference number
 *      - Handles all HTTP and JSON parsing errors gracefully
 *
 *  EXAMPLE USAGE   :
 *      PHOCSMonerisConfiguration__mdt moneris = [SELECT Store_ID__c, API_Token__c, 
 *                                                       Checkout_Id__c, Environment__c 
 *                                                FROM PHOCSMonerisConfiguration__mdt 
 *                                                WHERE MasterLabel = 'VCH' LIMIT 1];
 *
 *      String ticket = '1760450284MLJg1GHUZ0nz5GIanPSCVVSYFAwt5T';
 *      String status = 'Completed';
 *
 *      MonerisReceiptWrapper receipt = PHOCSMonerisReceipts.captureReceiptStatus(moneris, ticket, status);
 *      System.debug('Reference Number: ' + receipt.response.receipt.cc.reference_no);
 *
 *  IMPLEMENTED BY  : Pawan Atri
 *  IMPLEMENTED ON  : 14-Oct-2025
 *  RELATED TICKET  : EHIS-248
 * ================================================================================================
 */
public class PHOCSMonerisReceipts {
    
    /**
     * Fetches Moneris receipt details for a given transaction ticket.
     *
     * @param moneris - PHOCSMonerisConfiguration__mdt record containing Moneris credentials
     * @param ticket  - The unique Moneris ticket generated during checkout
     * @param status  - The transaction status (e.g., 'Completed', 'Pending')
     * @return MonerisReceiptWrapper - Parsed Moneris receipt response
     */
    public static MonerisReceiptWrapper captureReceiptStatus(
        PHOCSMonerisConfiguration__mdt moneris,
        String ticket,
        String status
    ) {
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