/**
 * ================================================================================================
 *  CLASS NAME      : PHOCSMonerisService
 *  DESCRIPTION     :
 *      This Apex service class acts as the **central integration layer** between Salesforce’s 
 *      PHOCS (Public Health Operating Compliance System) and the **Moneris Payment Gateway**.
 *      
 *      It manages the full Moneris payment lifecycle for Regulatory Transaction Fees — 
 *      from generating checkout tickets to verifying receipt statuses and updating 
 *      transaction records within Salesforce.
 *
 *      The class leverages related helper classes:
 *          • PHOCSMonerisTicket  → For generating Moneris checkout tickets  
 *          • PHOCSMonerisReceipts → For capturing and parsing Moneris payment receipts  
 *          • MonerisReceiptWrapper → For deserializing Moneris API JSON responses
 *
 *  FUNCTIONALITY   :
 *      - Loads and caches Moneris configuration data from Custom Metadata (per Health Authority)
 *      - Generates Moneris checkout tickets for transactions
 *      - Fetches receipt/payment status using ticket numbers
 *      - Updates RegulatoryTrxnFee records with ticket, reference number, payment status, 
 *        and payment date
 *      - Ensures all Moneris API interactions are securely handled via Named Credential: 'Moneris'
 *
 *  WORKFLOW        :
 *      1. generateTicket(recordId)
 *          → Fetches RegulatoryTrxnFee → Calls PHOCSMonerisTicket → Saves ticket in record
 *      2. checkReceiptStatus(recordId, status)
 *          → Fetches RegulatoryTrxnFee → Calls PHOCSMonerisReceipts
 *          → Updates transaction record with receipt info (reference_no, status)
 *
 *  EXAMPLE USAGE   :
 *      // Step 1: Generate Moneris Ticket
 *      String ticket = PHOCSMonerisService.generateTicket('a0A5g00000A2BcQEAV');
 *      System.debug('Generated Ticket: ' + ticket);
 *
 *      // Step 2: Capture Receipt and Update Status
 *      PHOCSMonerisService.checkReceiptStatus('a0A5g00000A2BcQEAV', 'Paid');
 *
 *  IMPLEMENTED BY  : Pawan Atri
 *  IMPLEMENTED ON  : 14-Oct-2025
 *  RELATED TICKET  : EHIS-248
 * ================================================================================================
 */
public class PHOCSMonerisService {
    public static Map<String, PHOCSMonerisConfiguration__mdt> monerisConfig;
    
    static {
        if (monerisConfig == null) {
            monerisConfig = new Map<String, PHOCSMonerisConfiguration__mdt>();
            for (PHOCSMonerisConfiguration__mdt moneris : [
                SELECT Id, DeveloperName, Store_ID__c, API_Token__c, Checkout_Id__c, Endpoints__c, 
                       HealthAuthority__c, Environment__c 
                FROM PHOCSMonerisConfiguration__mdt
            ]) {
                monerisConfig.put(moneris.HealthAuthority__c, moneris);
            }
        }
    }
    
    /**
     * Generates a Moneris checkout ticket for a given Regulatory Transaction Fee record.
     *
     * @param recordId - RegulatoryTrxnFee record Id
     * @return String  - Generated Moneris checkout ticket
     */
    public static String generateTicket(String recordId) {
        PHOCSMonerisConfiguration__mdt moneris;
        String ticket;
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);

        if (transFee == null || transFee.Account == null || transFee.Account.HealthAuthority__c == '') {
            throw new AuraHandledException('Please provide a valid transaction ID');
        }

        ticket = PHOCSMonerisTicket.generateTicket(
            monerisConfig.get(transFee.Account.HealthAuthority__c),
            transFee.Id,
            transFee.TotalFeeAmount
        );

        if (ticket != null && ticket != '') {
            updateRegulatoryTransFee(recordId, ticket, null, null);
        }

        return ticket;
    }
    
    /**
     * Retrieves a Regulatory Transaction Fee record by Id.
     *
     * @param recordId - RegulatoryTrxnFee Id
     * @return RegulatoryTrxnFee record
     */
    public static RegulatoryTrxnFee getRegulatoryTransFee(Id recordId) {
        return [
            SELECT Id, Status, AccountId, Account.HealthAuthority__c, 
                   Account.AccountNumberRTPrefixed__c, Account.AccountNumber, 
                   Account.AccountNumberAuto__c, TotalFeeAmount, ReferenceNumber__c, 
                   PHOCSMonerisTicketNumber__c
            FROM RegulatoryTrxnFee 
            WHERE Id = :recordId 
            LIMIT 1
        ];
    }
    
    /**
     * Checks the Moneris receipt/payment status using a stored ticket number
     * and updates the corresponding transaction record.
     *
     * @param recordId - RegulatoryTrxnFee Id
     * @param status   - Payment status (e.g., 'Paid', 'Failed', 'Pending')
     */
    public static void checkReceiptStatus(String recordId, String status) {
        PHOCSMonerisConfiguration__mdt moneris;
        List<RegulatoryTrxnFee> transFees = new List<RegulatoryTrxnFee>();
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);
        
        if (transFee == null || transFee.Account == null || transFee.Account.HealthAuthority__c == '') {
            throw new AuraHandledException('Please provide a valid transaction ID');
        }
        
        if (transFee == null || transFee.PHOCSMonerisTicketNumber__c == '') {
            throw new AuraHandledException('Moneris Ticket is missing for transaction fee');
        }
        
        moneris = monerisConfig.get(transFee.Account.HealthAuthority__c);
        MonerisReceiptWrapper receiptWrapper = PHOCSMonerisReceipts.captureReceiptStatus(
            monerisConfig.get(transFee.Account.HealthAuthority__c),
            transFee.PHOCSMonerisTicketNumber__c,
            status
        );

        if (receiptWrapper != null && receiptWrapper.response.receipt != null) {
            String receiptStatus;
            if(receiptWrapper.response.receipt.result == 'a'){
                receiptStatus = 'Paid';
            }
            if(receiptWrapper.response.receipt.result == 'd'){
                receiptStatus = 'Canceled';
            }
            updateRegulatoryTransFee(recordId, transFee.PHOCSMonerisTicketNumber__c, receiptWrapper.response.receipt.cc.reference_no, receiptStatus);
        }
    }
    
    /**
     * Asynchronous update for Regulatory Transaction Fee record fields.
     *
     * @param recordId  - RegulatoryTrxnFee Id
     * @param ticket    - Moneris ticket number
     * @param reference - Moneris reference number
     * @param status    - Transaction status
     */
    @future
    public static void updateRegulatoryTransFee(String recordId, String ticket, String reference, String status) {
        RegulatoryTrxnFee transFee = getRegulatoryTransFee(recordId);

        if (ticket != null && ticket != '')
            transFee.PHOCSMonerisTicketNumber__c = ticket;
        if (reference != null && reference != '')
            transFee.ReferenceNumber__c = reference;
        if (status != null && status != '') {
            transFee.Status = status;
            if (status.equalsIgnoreCase('paid')) {
                transFee.PaymentDate__c = Date.today();
            }
        }
        update transFee;
    }
}