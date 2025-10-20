import { LightningElement, wire, track, api } from 'lwc';
import getPaymentLinkUrl from '@salesforce/apex/PHOCSGlobalPayHandler.getPaymentLinkUrl';    
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import createCheckoutTicket from '@salesforce/apex/MonerisCheckoutServiceQA.createCheckoutTicket';
import getPaymentSystemRedirectInfo from '@salesforce/apex/PHOCSPaymentController.getPaymentSystemRedirectInfo';


export default class PhocsPayment extends NavigationMixin(LightningElement) {
    @api regulatoryTransactionFeeId;
    error;

    ticket;
    monerisInstance;
    
    @api recordId;
    @api amount;
    @api customerId;

    // === Get URL parameters ===
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.amount = currentPageReference.state.Amount;
            this.customerId = currentPageReference.state.CustomerId;
            console.log('Record Id:', this.recordId);
            console.log('Amount:', this.amount);
            console.log('Customer Id:', this.customerId);
        }
    }

    connectedCallback() {
        this.redirectPaymentGateway();
    }

    redirectPaymentGateway(){
        getPaymentSystemRedirectInfo({regulatoryTransactionFeeId:this.regulatoryTransactionFeeId})
            .then(result => {
                if(result && result.useMoneris){
                    this.MonerisPayHandler();
                }
                if(result && result.useGlobalPay){
                    this.globalPayHandler();
                }
            })
    }

    /* ============================================================
        GLOBAL PAY
    ============================================================ */
    globalPayHandler(){
        this.redirectUserGlobalPayPaymentPage();
    }
    MonerisPayHandler(){
        this.redirectToRegulatoryPage();
    }

    redirectUserGlobalPayPaymentPage() {
        getPaymentLinkUrl()
            .then(result => {
               if(result)
               this.redirectToPaymentPage(result);
            })
            .catch(error => {
                this.error = error;
            });
    }

     redirectToPaymentPage(paymentPageUrl) {
        window.open(paymentPageUrl,"_self")
    }

    /* ============================================================
         Moneris PAY
    ============================================================ */

     // === User clicks Start Checkout ===

     redirectToRegulatoryPage() {
        const url = `/phocsmonerispayment?recordId=${this.recordId}&Amount=${this.amount}&CustomerId=${this.customerId}`;
        console.log('🌐 Redirecting to:', url);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
        handleMonerisCheckout() {
            createCheckoutTicket({ amount: 10.00 })
                .then(result => {
                    this.ticket = result;
                    console.log('✅ Moneris QA Ticket:', this.ticket);
    
                    this.initializeMonerisCheckout();
                })
                .catch(error => {
                    console.error('❌ Error getting Moneris ticket:', error);
                    alert(error.body?.message || 'Error initializing Moneris Checkout.');
                });
        }
    
        // === Initialize Moneris Checkout ===
        initializeMonerisCheckout() {
            console.log('🚀 Starting Moneris QA Checkout...');
    
            this.monerisInstance = new MonerisCheckout(this.template);
            this.monerisInstance.setMode('qa');
            this.monerisInstance.setCheckoutDiv('monerisCheckout');
    
            // === Register Callbacks ===
            this.monerisInstance.setCallback('page_loaded', this.onPageLoaded);
            this.monerisInstance.setCallback('cancel_transaction', this.onCancelTransaction);
            this.monerisInstance.setCallback('payment_receipt', this.onPaymentReceipt);
            this.monerisInstance.setCallback('payment_complete', this.onPaymentComplete);
            this.monerisInstance.setCallback('error_event', this.onErrorEvent);
    
            // === Start checkout ===
            this.monerisInstance.startCheckout(this.ticket);
        }
    
        // === CALLBACK IMPLEMENTATIONS ===
        onPageLoaded() {
            console.log('🟢 Page loaded successfully.');
        }
    
        onCancelTransaction() {
            console.log('🟡 Transaction cancelled.');
            alert('Transaction cancelled by user.');
        }
    
        onPaymentReceipt(receipt) {
            console.log('🧾 Payment receipt received:', receipt);
        }
    
        onPaymentComplete(response) {
            console.log('🎉 Payment complete:', response);
            alert('Payment completed successfully!');
        }
    
        onErrorEvent(error) {
            console.error('🔴 Moneris error:', error);
            alert('Error during payment: ' + JSON.stringify(error));
        }
}

/* ============================================================
   Embedded Moneris Checkout Implementation (Locker Safe)
   ============================================================ */
class MonerisCheckout {
    constructor(templateRef) {
        this.mode = '';
        this.request_url = '';
        this.checkout_div = 'moneris-checkout';
        this.fullscreen = 'T';
        this.templateRef = templateRef; // ✅ Reference to LWC template
        this.callbacks = {
            page_loaded: '',
            cancel_transaction: '',
            payment_receipt: '',
            payment_complete: '',
            error_event: '',
        };
        this.registerMessageListener();
    }

    registerMessageListener() {
        const eventMethod = window.addEventListener ? 'addEventListener' : 'attachEvent';
        const messageEvent = eventMethod === 'attachEvent' ? 'onmessage' : 'message';
        window[eventMethod](messageEvent, this.receivePostMessage.bind(this), false);
    }

    logConfig() {
        console.log(`request_url: ${this.request_url}, checkout_div: ${this.checkout_div}`);
    }

    setCheckoutDiv(name) {
        this.checkout_div = name;
    }

    setMode(mode) {
        this.mode = mode;
        if (mode === 'qa') {
            this.request_url = 'https://gatewayt.moneris.com/chkt/display/index.php';
        } else if (mode === 'prod') {
            this.request_url = 'https://gateway.moneris.com/chkt/display/index.php';
        } else if (mode === 'dev') {
            this.request_url = 'https://gatewaydev.moneris.com/chkt/display/index.php';
        } else {
            this.request_url = 'https://gatewayqa.moneris.com/chkt/display/index.php';
        }
    }

    setCallback(name, func) {
        if (this.callbacks.hasOwnProperty(name)) {
            this.callbacks[name] = func;
        } else {
            console.warn(`Invalid callback: ${name}`);
        }
    }

    // === Start Checkout ===
    startCheckout(ticket) {
        this.fullscreen = ticket.slice(-1);
        console.log('fullscreen:', this.fullscreen);

        // ✅ Access the div via data-id (safe in LWC DOM)
        const targetDiv = this.templateRef.querySelector('[data-id="monerisCheckout"]');
        if (!targetDiv) {
            console.error(`❌ Target div "monerisCheckout" not found in LWC DOM`);
            return;
        }

        targetDiv.innerHTML = ''; // safe clear

        const checkoutUrl = `${this.request_url}?tck=${ticket}`;
        console.log('🧾 Checkout URL:', checkoutUrl);

        const iframe = document.createElement('iframe');
        iframe.setAttribute('src', checkoutUrl);
        iframe.setAttribute('allowpaymentrequest', 'true');
        iframe.setAttribute('title', 'Payment Details');
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.border = 'none';
        targetDiv.appendChild(iframe);

        if (typeof this.callbacks.page_loaded === 'function') {
            this.callbacks.page_loaded();
        }
    }


    receivePostMessage(resp) {
        try {
            const data = JSON.parse(resp.data);
            const handler = data.handler;

            if (handler && typeof this.callbacks[handler] === 'function') {
                this.callbacks[handler](data);
            } else {
                console.log('📨 Received message:', data);
            }
        } catch (err) {
            console.error('⚠️ Invalid postMessage data', err);
        }
    }

    sendFrameMessage(action) {
        const frame = this.templateRef.querySelector(`#${this.checkout_div}-Frame`)?.contentWindow;
        if (frame) {
            const req = JSON.stringify({ action });
            frame.postMessage(req, this.request_url);
        }
    }

    closeCheckout() {
        this.sendFrameMessage('close_request');
    }

    startTransaction() {
        this.sendFrameMessage('start_transaction');
    }
}