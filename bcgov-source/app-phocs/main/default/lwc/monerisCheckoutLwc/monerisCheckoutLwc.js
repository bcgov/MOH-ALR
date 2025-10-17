import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import createCheckoutTicket from '@salesforce/apex/PHOCSMonerisService.generateTicket';
import capturePaymentStatus from '@salesforce/apex/PHOCSMonerisService.checkReceiptStatus';

export default class MonerisCheckoutLwc extends NavigationMixin(LightningElement) {
    @track countdown = 10;
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
        }
    }

    connectedCallback() {
        this.handleMonerisCheckout();
    }

    // === Start Checkout ===
    handleMonerisCheckout() {
        createCheckoutTicket({ recordId: this.recordId })
            .then(result => {
                this.ticket = result;
                this.initializeMonerisCheckout();
            })
            .catch(error => {
                console.error('Error getting Moneris ticket:', error);
                alert(error.body?.message || 'Error initializing Moneris Checkout.');
            });
    }

    // === Initialize Moneris Checkout ===
    initializeMonerisCheckout() {
        this.monerisInstance = new MonerisCheckout(this.template);
        this.monerisInstance.setMode('qa');
        this.monerisInstance.setCheckoutDiv('monerisCheckout');

        // Bind callbacks
        this.monerisInstance.setCallback('cancel_transaction', this.onCancelTransaction.bind(this));
        this.monerisInstance.setCallback('payment_receipt', this.onPaymentReceipt.bind(this));
        this.monerisInstance.setCallback('error_event', this.onErrorEvent.bind(this));

        this.monerisInstance.startCheckout(this.ticket);
    }

    // === CALLBACKS ===
    onCancelTransaction() {
        alert('Transaction cancelled.');
        this.redirectToRegulatoryPage();
    }

    onPaymentReceipt(receipt) {
        console.log('Payment receipt received:', receipt);
        this.handleCapturePayment();
        this.startCountdownRedirect();
    }

    onErrorEvent(error) {
        console.error('Moneris error:', error);
        alert('Error during payment: ' + JSON.stringify(error));
    }

    // === Capture Payment Status ===
    handleCapturePayment() {
        capturePaymentStatus({ recordId: this.recordId, status: 'Paid' })
            .then(() => console.log('Payment status updated successfully.'))
            .catch(error => console.error('Error capturing payment:', error));
    }

    // === Countdown + Redirect ===
    startCountdownRedirect() {
        let remaining = this.countdown;
        const interval = setInterval(() => {
            remaining--;
            this.countdown = remaining;
            if (remaining === 0) {
                clearInterval(interval);
                this.redirectToRegulatoryPage();
            }
        }, 1000);
    }

    redirectToRegulatoryPage() {
        const url = `/regulatory-transaction-fee?recordId=${this.recordId}`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: { url }
        });
    }
}

/* ============================================================
   Simplified Embedded Moneris Checkout Implementation
   ============================================================ */
class MonerisCheckout {
    constructor(templateRef) {
        this.mode = '';
        this.request_url = '';
        this.checkout_div = 'moneris-checkout';
        this.templateRef = templateRef;
        this.callbacks = {};
        this.registerMessageListener();
    }

    registerMessageListener() {
        window.addEventListener('message', this.receivePostMessage.bind(this), false);
    }

    setMode(mode) {
        const baseUrls = {
            qa: 'https://gatewayt.moneris.com/chkt/display/index.php',
            prod: 'https://gateway.moneris.com/chkt/display/index.php',
            dev: 'https://gatewaydev.moneris.com/chkt/display/index.php',
        };
        this.request_url = baseUrls[mode] || baseUrls.qa;
    }

    setCheckoutDiv(name) {
        this.checkout_div = name;
    }

    setCallback(name, func) {
        this.callbacks[name] = func;
    }

    startCheckout(ticket) {
        const targetDiv = this.templateRef.querySelector('[data-id="monerisCheckout"]');
        if (!targetDiv) return console.error('Target div "monerisCheckout" not found.');
        targetDiv.innerHTML = '';

        const iframe = document.createElement('iframe');
        iframe.src = `${this.request_url}?tck=${ticket}`;
        iframe.allowPaymentRequest = true;
        iframe.style = 'width:100%;height:100%;border:none;';
        targetDiv.appendChild(iframe);
    }

    receivePostMessage(resp) {
        try {
            const data = JSON.parse(resp.data);
            const handler = data.handler;
            if (this.callbacks[handler]) this.callbacks[handler](data);
        } catch (err) {
            console.error('Invalid postMessage data:', err);
        }
    }
}
