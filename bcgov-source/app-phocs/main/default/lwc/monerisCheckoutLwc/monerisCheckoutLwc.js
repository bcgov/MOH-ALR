import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import createCheckoutTicket from '@salesforce/apex/MonerisCheckoutServiceQA.createCheckoutTicket';
import capturePaymentStatus from '@salesforce/apex/MonerisCheckoutServiceQA.capturePaymentStatus';

export default class MonerisCheckoutLwc extends NavigationMixin(LightningElement) {
    @track countdown = 30;
    @api recordId;
    @api amount;
    @api customerId;
    ticket;
    monerisInstance;

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
        this.getStateParameters(this.pageReference);
        this.handleMonerisCheckout();
    }

    // === Start Checkout ===
    handleMonerisCheckout() {
        createCheckoutTicket({ recordId: this.recordId, amount: this.amount })
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

        // ✅ Bind all callbacks to preserve context
        this.monerisInstance.setCallback('page_loaded', this.onPageLoaded.bind(this));
        this.monerisInstance.setCallback('cancel_transaction', this.onCancelTransaction.bind(this));
        this.monerisInstance.setCallback('payment_receipt', this.onPaymentReceipt.bind(this));
        this.monerisInstance.setCallback('payment_complete', this.onPaymentComplete.bind(this));
        this.monerisInstance.setCallback('error_event', this.onErrorEvent.bind(this));

        // Start Moneris checkout
        this.monerisInstance.startCheckout(this.ticket);
    }

    // === CALLBACK IMPLEMENTATIONS ===
    onPageLoaded() {
        console.log('🟢 Page loaded successfully.');
    }

    onCancelTransaction() {
        console.log('🟡 Transaction cancelled.');
        alert('Transaction cancelled by user.');
        // Redirect immediately (no timer)
        this.redirectToRegulatoryPage();
    }

    onPaymentReceipt(receipt) {
        console.log('🧾 Payment receipt received:', receipt);
        alert('Payment received! Redirecting to details page in 30 seconds...');
        this.handleCapturePayment();
        this.startCountdownRedirect();
    }

    onPaymentComplete(response) {
        console.log('🎉 Payment complete:', response);
        alert('Payment completed successfully!');
    }

    onErrorEvent(error) {
        console.error('🔴 Moneris error:', error);
        alert('Error during payment: ' + JSON.stringify(error));
    }

    // === Countdown + Redirect ===
    startCountdownRedirect() {
        let remaining = 10;
        const interval = setInterval(() => {
            remaining -= 1;
            this.countdown = remaining;
            if (remaining === 0) {
                clearInterval(interval);
                this.redirectToRegulatoryPage();
            }
        }, 1000);
    }

    redirectToRegulatoryPage() {
        const url = `/regulatory-transaction-fee?recordId=${this.recordId}`;
        console.log('🌐 Redirecting to:', url);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }

    handleCapturePayment() {
        // Example: payment succeeded
        const paymentStatus = 'Paid';

        capturePaymentStatus({ recordId: this.recordId, status: paymentStatus })
            .then(() => {
                console.log('✅ Payment status updated successfully.');
                this.showToast('Success', 'Payment captured successfully!', 'success');
            })
            .catch(error => {
                console.error('❌ Error capturing payment:', error);
                this.showToast('Error', error.body?.message || 'Payment update failed.', 'error');
            });
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
        this.templateRef = templateRef;
        this.callbacks = {
            page_loaded: null,
            cancel_transaction: null,
            payment_receipt: null,
            payment_complete: null,
            error_event: null,
        };
        this.registerMessageListener();
    }

    registerMessageListener() {
        const eventMethod = window.addEventListener ? 'addEventListener' : 'attachEvent';
        const messageEvent = eventMethod === 'attachEvent' ? 'onmessage' : 'message';
        window[eventMethod](messageEvent, this.receivePostMessage.bind(this), false);
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

    setCheckoutDiv(name) {
        this.checkout_div = name;
    }

    setCallback(name, func) {
        if (this.callbacks.hasOwnProperty(name)) {
            this.callbacks[name] = func;
        } else {
            console.warn(`⚠️ Invalid callback name: ${name}`);
        }
    }

    startCheckout(ticket) {
        const targetDiv = this.templateRef.querySelector('[data-id="monerisCheckout"]');
        if (!targetDiv) {
            console.error(`❌ Target div "monerisCheckout" not found in LWC DOM`);
            return;
        }

        targetDiv.innerHTML = '';

        const checkoutUrl = `${this.request_url}?tck=${ticket}`;
        console.log('🧾 Checkout URL:', checkoutUrl);

        const iframe = document.createElement('iframe');
        iframe.src = checkoutUrl;
        iframe.allowPaymentRequest = true;
        iframe.title = 'Payment Details';
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
                console.log('📨 Unhandled Moneris message:', data);
            }
        } catch (err) {
            console.error('⚠️ Invalid postMessage data TypeError:', err);
        }
    }
}