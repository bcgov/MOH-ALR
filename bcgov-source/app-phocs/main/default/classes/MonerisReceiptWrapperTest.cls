@IsTest
private class MonerisReceiptWrapperTest {

    @IsTest
    static void testParse_MonerisReceiptResponse() {
        // === Step 1: Prepare Sample JSON (mirrors actual Moneris API response)
        String sampleJson = '{' +
            '"response": {' +
                '"success": "true",' +
                '"request": {' +
                    '"txn_total": "2500.00",' +
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
                    '"cc_total": "2500.00",' +
                    '"pay_by_token": "0",' +
                    '"cc": {' +
                        '"first6last4": "4242424242",' +
                        '"expiry": "1129",' +
                        '"cardholder": "test"' +
                    '},' +
                    '"ticket": "1760450284MLJg1GHUZ0nz5GIanPSCVVSYFAwt5T",' +
                    '"cust_id": null,' +
                    '"dynamic_descriptor": null,' +
                    '"order_no": "ORDER-20251014-065804-21192",' +
                    '"eci": "7"' +
                '},' +
                '"receipt": {' +
                    '"result": "a",' +
                    '"cc": {' +
                        '"order_no": "ORDER-20251014-065804-21192",' +
                        '"cust_id": null,' +
                        '"transaction_no": "13-0_1274",' +
                        '"reference_no": "660191690010010130",' +
                        '"transaction_code": "00",' +
                        '"transaction_type": "200",' +
                        '"transaction_date_time": "2025-10-14 09:58:40",' +
                        '"corporate_card": "false",' +
                        '"amount": "2500.00",' +
                        '"response_code": "027",' +
                        '"iso_response_code": "01",' +
                        '"approval_code": "B43977",' +
                        '"card_type": "V",' +
                        '"dynamic_descriptor": "",' +
                        '"invoice_number": null,' +
                        '"customer_code": null,' +
                        '"eci": "7",' +
                        '"cvd_result_code": "1M",' +
                        '"avs_result_code": null,' +
                        '"cavv_result_code": null,' +
                        '"first6last4": "4242424242",' +
                        '"expiry_date": "1129",' +
                        '"recur_success": null,' +
                        '"issuer_id": null,' +
                        '"is_debit": "false",' +
                        '"ecr_no": "66019169",' +
                        '"batch_no": "001",' +
                        '"sequence_no": "013",' +
                        '"result": "a",' +
                        '"wallet_type": "",' +
                        '"fraud": {' +
                            '"secure_3d": {' +
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

        // === Step 2: Parse JSON using your class
        MonerisReceiptWrapper wrapper = MonerisReceiptWrapper.parse(sampleJson);

        // === Step 3: Assertions for key fields
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
        System.assertEquals('true', wrapper.response.success, 'Success flag should match');
        System.assertEquals('ORDER-20251014-065804-21192', wrapper.response.request.order_no, 'Order number mismatch');
        System.assertEquals('2500.00', wrapper.response.request.txn_total, 'Transaction total mismatch');

        // Receipt validation
        System.assertEquals('a', wrapper.response.receipt.result, 'Receipt result mismatch');
        System.assertEquals('660191690010010130', wrapper.response.receipt.cc.reference_no, 'Reference number mismatch');
        System.assertEquals('B43977', wrapper.response.receipt.cc.approval_code, 'Approval code mismatch');
        System.assertEquals('V', wrapper.response.receipt.cc.card_type, 'Card type mismatch');

        // Fraud section validation
        System.assertEquals('Merchant', wrapper.response.receipt.cc.fraud.secure_3d.decision_origin, '3D Secure origin mismatch');
        System.assertEquals('1M', wrapper.response.receipt.cc.fraud.cvd.code, 'CVD code mismatch');
    }
}