import { LightningElement, wire, track, api } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import createCheckoutTicket from '@salesforce/apex/PHOCSMonerisService.generateTicket';
import capturePaymentStatus from '@salesforce/apex/PHOCSMonerisService.checkReceiptStatus';

export default class MonerisCheckoutLwc extends NavigationMixin(LightningElement) {
    @track countdown = 10;
    @track isLoading = true; // 🔹 Show spinner initially
    @api recordId;
    @api amount;
    @api customerId;

    ticket;
    monerisInstance;
    environment;
    baseUrl;

    /** === Read URL Parameters === */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state) {
            this.recordId = currentPageReference.state.recordId;
            this.amount = currentPageReference.state.Amount;
            this.customerId = currentPageReference.state.CustomerId;
        }
    }

    connectedCallback() {
        this.handleMonerisCheckout();
    }

    /** === Step 1: Generate Ticket and Start Checkout === */
    handleMonerisCheckout() {
        this.isLoading = true; // Show spinner
        createCheckoutTicket({ recordId: this.recordId })
            .then(result => {
                this.ticket = result.ticket;
                this.environment = result.environment;
                this.baseUrl = result.baseUrl;
                this.initializeMonerisCheckout();
            })
            .catch(error => {
                this.isLoading = false;
                alert(error.body?.message || 'Error initializing Moneris Checkout.');
            });
    }

    /** === Step 2: Initialize Moneris Checkout === */
    initializeMonerisCheckout() {
        this.monerisInstance = new MonerisCheckout(this.template);
        this.monerisInstance.setMode(this.environment);
        //this.monerisInstance.setBaseUrl(this.baseUrl);
        this.monerisInstance.setCheckoutDiv('monerisCheckout');

        this.monerisInstance.setCallback('page_loaded', () => {});
        this.monerisInstance.setCallback('cancel_transaction', () => this.redirectToRegulatoryPage());
        this.monerisInstance.setCallback('payment_receipt', data => this.handlePaymentReceipt(data));
        this.monerisInstance.setCallback('payment_complete', () => {});
        this.monerisInstance.setCallback('error_event', err => {
            this.isLoading = false;
            alert('Payment error: ' + JSON.stringify(err));
        });

        this.monerisInstance.startCheckout(this.ticket);
        this.isLoading = false;
    }

    /** === Step 3: Handle Receipt + Capture Payment === */
    handlePaymentReceipt(receipt) {
        this.handleCapturePayment();
        this.startCountdownRedirect();
    }

    handleCapturePayment() {
        capturePaymentStatus({ recordId: this.recordId, status: 'Paid' }).catch(error => {
            console.error('Payment capture failed:', error);
        });
    }

    /** === Step 4: Countdown Redirect === */
    startCountdownRedirect() {
        let remaining = this.countdown;
        const interval = setInterval(() => {
            remaining -= 1;
            this.countdown = remaining;
            if (remaining <= 0) {
                clearInterval(interval);
                this.redirectToRegulatoryPage();
            }
        }, 1000);
    }

    redirectToRegulatoryPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: `/regulatory-transaction-fee?recordId=${this.recordId}`
            }
        });
    }
}

/** ============================================================
   Embedded Moneris Checkout (Locker-Safe Implementation)
   ============================================================ */
class MonerisCheckout {
    constructor(templateRef) {
        this.templateRef = templateRef;
        this.callbacks = {};
        this.registerMessageListener();
    }

    registerMessageListener() {
        window.addEventListener('message', this.receivePostMessage.bind(this), false);
    }

    setMode(mode) {
        const urls = {
            qa: 'https://gatewayt.moneris.com/chkt/display/index.php',
            prod: 'https://gateway.moneris.com/chkt/display/index.php',
            dev: 'https://gatewaydev.moneris.com/chkt/display/index.php'
        };
        this.request_url = urls[mode] || urls.qa;
    }

    setCheckoutDiv(name) {
        this.checkout_div = name;
    }

    setCallback(name, func) {
        this.callbacks[name] = func;
    }

    startCheckout(ticket) {
        const targetDiv = this.templateRef.querySelector('[data-id="monerisCheckout"]');
        if (!targetDiv) return;

        targetDiv.innerHTML = '';
        const iframe = document.createElement('iframe');
        iframe.src = `${this.request_url}?tck=${ticket}`;
        Object.assign(iframe.style, {
            width: '100%',
            height: '100%',
            border: 'none'
        });
        targetDiv.appendChild(iframe);

        this.callbacks.page_loaded?.();
    }

    receivePostMessage(event) {
        try {
            const data = JSON.parse(event.data);
            const handler = data.handler;
            this.callbacks[handler]?.(data);
        } catch {
            // Ignore invalid messages
        }
    }
}