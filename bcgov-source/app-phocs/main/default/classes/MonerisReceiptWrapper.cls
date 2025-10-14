/*

*/
public class MonerisReceiptWrapper {
    public Response response;

    public class Response {
        public String success;
        public Request request;
        public Receipt receipt;
    }

    public class Request {
        public String txn_total;
        public CustInfo cust_info;
        public Shipping shipping;
        public Billing billing;
        public String cc_total;
        public String pay_by_token;
        public CC cc;
        public String ticket;
        public String cust_id;
        public String dynamic_descriptor;
        public String order_no;
        public String eci;
    }

    public class CustInfo {
        public String first_name;
        public String last_name;
        public String phone;
        public String email;
    }

    public class Shipping {
        public String address_1;
        public String address_2;
        public String city;
        public String country;
        public String province;
        public String postal_code;
    }

    // Billing might be null or extended later
    public class Billing {}

    public class CC {
        public String first6last4;
        public String expiry;
        public String cardholder;
    }

    public class Receipt {
        public String result;
        public CCReceipt cc;
    }

    public class CCReceipt {
        public String order_no;
        public String cust_id;
        public String transaction_no;
        public String reference_no;
        public String transaction_code;
        public String transaction_type;
        public String transaction_date_time;
        public String corporate_card;
        public String amount;
        public String response_code;
        public String iso_response_code;
        public String approval_code;
        public String card_type;
        public String dynamic_descriptor;
        public String invoice_number;
        public String customer_code;
        public String eci;
        public String cvd_result_code;
        public String avs_result_code;
        public String cavv_result_code;
        public String first6last4;
        public String expiry_date;
        public String recur_success;
        public String issuer_id;
        public String is_debit;
        public String ecr_no;
        public String batch_no;
        public String sequence_no;
        public String result;
        public String wallet_type;
        public Fraud fraud;
    }

    public class Fraud {
        public Secure3d secure_3d;
        public Kount kount;
        public Cvd cvd;
        public Avs avs;
    }

    public class Secure3d {
        public String decision_origin;
        public String result;
        public String condition;
        public String status;
        public String code;
        public String details;
    }

    public class Kount {
        public String decision_origin;
        public String result;
        public String condition;
        public String status;
        public String code;
        public String details;
    }

    public class Cvd {
        public String decision_origin;
        public String result;
        public String condition;
        public String status;
        public String code;
        public String details;
    }

    public class Avs {
        public String decision_origin;
        public String result;
        public String condition;
        public String status;
        public String code;
        public String details;
    }
    
    public static MonerisReceiptWrapper parse(String jsonResponse){
        return (MonerisReceiptWrapper) JSON.deserialize(jsonResponse, MonerisReceiptWrapper.class);
    }
}