@IsTest
global class MonerisReceiptMock implements HttpCalloutMock {
    
    global HTTPResponse respond(HTTPRequest req) {
        // --- Prepare a sample Moneris API mock JSON response ---
        String mockBody = '{' +
            '"response": {' +
                '"success": "true",' +
                '"request": {' +
                    '"txn_total": "125.00",' +
                    '"cust_info": {' +
                        '"first_name": null,' +
                        '"last_name": null,' +
                        '"phone": null,' +
                        '"email": null' +
                    '},' +
                    '"shipping": {' +
                        '"address_1": null,' +
                        '"address_2": null,' +
                        '"city": null,' +
                        '"country": null,' +
                        '"province": null,' +
                        '"postal_code": null' +
                    '},' +
                    '"billing": null,' +
                    '"cc_total": "125.00",' +
                    '"pay_by_token": "0",' +
                    '"cc": {' +
                        '"first6last4": "5454545454",' +
                        '"expiry": "0630",' +
                        '"cardholder": "Test Test"' +
                    '},' +
                    '"ticket": "1760633356HvaZZUqLeXDhtpp33jMfRuwvGHTlnT",' +
                    '"cust_id": null,' +
                    '"dynamic_descriptor": null,' +
                    '"order_no": "ORDER-20251016-094916-13133",' +
                    '"eci": "7"' +
                '},' +
                '"receipt": {' +
                    '"result": "a",' +
                    '"cc": {' +
                        '"order_no": "ORDER-20251016-094916-13133",' +
                        '"cust_id": null,' +
                        '"transaction_no": "30-0_1276",' +
                        '"reference_no": "660191690010010300",' +
                        '"transaction_code": "00",' +
                        '"transaction_type": "200",' +
                        '"transaction_date_time": "2025-10-16 12:49:50",' +
                        '"corporate_card": "false",' +
                        '"amount": "125.00",' +
                        '"response_code": "027",' +
                        '"iso_response_code": "01",' +
                        '"approval_code": "T42938",' +
                        '"card_type": "M",' +
                        '"dynamic_descriptor": "",' +
                        '"invoice_number": null,' +
                        '"customer_code": null,' +
                        '"eci": "7",' +
                        '"cvd_result_code": "1M",' +
                        '"avs_result_code": null,' +
                        '"cavv_result_code": null,' +
                        '"first6last4": "5454545454",' +
                        '"expiry_date": "0630",' +
                        '"recur_success": null,' +
                        '"issuer_id": null,' +
                        '"is_debit": "false",' +
                        '"ecr_no": "66019169",' +
                        '"batch_no": "001",' +
                        '"sequence_no": "030",' +
                        '"result": "a",' +
                        '"wallet_type": "",' +
                        '"fraud": {' +
                            '"3d_secure": {' +
                                '"decision_origin": "Merchant",' +
                                '"result": "3",' +
                                '"condition": "1",' +
                                '"status": "disabled",' +
                                '"code": "",' +
                                '"details": ""' +
                            '},' +
                            '"kount": {' +
                                '"decision_origin": "Merchant",' +
                                '"result": "3",' +
                                '"condition": "0",' +
                                '"status": "disabled",' +
                                '"code": "",' +
                                '"details": ""' +
                            '},' +
                            '"cvd": {' +
                                '"decision_origin": "Merchant",' +
                                '"result": "1",' +
                                '"condition": "0",' +
                                '"status": "success",' +
                                '"code": "1M",' +
                                '"details": ""' +
                            '},' +
                            '"avs": {' +
                                '"decision_origin": "Merchant",' +
                                '"result": "3",' +
                                '"condition": "0",' +
                                '"status": "disabled",' +
                                '"code": "",' +
                                '"details": ""' +
                            '}' +
                        '}' +
                    '}' +
                '}' +
            '}' +
        '}';


        // --- Create and return mock HTTP response ---
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(mockBody);
        res.setStatusCode(200);
        return res;
    }
}