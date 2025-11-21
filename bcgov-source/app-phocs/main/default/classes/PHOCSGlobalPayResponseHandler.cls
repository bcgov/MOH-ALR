@RestResource(urlMapping='/phocs/globalPay/status/*')
global without sharing class PHOCSGlobalPayResponseHandler {

    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            String headerSignature = req.headers.get('X-GP-Signature');
            if (String.isBlank(headerSignature)) {
                throw new SecurityException('Missing X-GP-Signature header');
            }
            String rawBody = req.requestBody.toString();
            System.debug('Raw JSON Body: ' + rawBody);

            String appKey = '4yAtqdjSokiV3qwK';
            String stringToHash = rawBody + appKey;
            Blob hash = Crypto.generateDigest('SHA-512', Blob.valueOf(stringToHash));
            String computedSignature = EncodingUtil.convertToHex(hash).toLowerCase();

            // Compare with X-GP-Signature header ---
            if (computedSignature != headerSignature.toLowerCase()) {
                throw new SecurityException('Invalid signature — webhook not from Global Payments');
            }

            GlobalPaymentStatus response = new GlobalPaymentStatus().parse(rawBody);            
            if(string.isNotBlank(response.reference)){
                RegulatoryTrxnFee fees = new RegulatoryTrxnFee(Id=response.reference);
                fees.PaymentResponse__c = rawBody;
                fees.ReferenceNumber__c = response.id;
                fees.Status = response.payment_method.message;
                update fees;
            }
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status":"success"}');

        } catch (Exception e) {
            System.debug('validation failed: ' + e.getMessage());
            res.statusCode = 400;
            res.responseBody = Blob.valueOf(
                JSON.serialize(new Map<String, Object>{
                    'status' => 'error',
                    'message' => e.getMessage()
                })
            );
        }
    }

    public class GlobalPaymentStatus {
        public String id;
        public String time_created;
        public String type;
        public String status;
        public String channel;
        public String capture_mode;
        public String amount;
        public String country;
        public String merchant_id;
        public String merchant_name;
        public String account_id;
        public String account_name;
        public String reference;
        public Payment_Method payment_method;
        public String batch_id;
        public Action action;

        public GlobalPaymentStatus parse(String body) {
            return (GlobalPaymentStatus) JSON.deserialize(body, GlobalPaymentStatus.class);
        }
    }
    public class Payment_Method {
        public String result;
        public String message;
        public String entry_mode;
        public Apm apm;
    }
    public class Apm {
        public String provider;
        public String wait_notification;
        public String fund_status;
        public String payment_description;
        public String confirmed_accountholder;
        public String account_number;
        public String iban;
        public String bank_identifier_code;
        public String bank_name;
        public String bank_address;
        public String optional_redirect;
    }
    public class Action {
        public String id;
        public String type;
        public String time_created;
        public String result_code;
        public String app_id;
        public String app_name;
    }

}