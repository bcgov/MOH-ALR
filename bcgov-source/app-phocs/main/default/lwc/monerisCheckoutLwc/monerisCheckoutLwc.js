import { LightningElement, track } from 'lwc';
import generateTicket from '@salesforce/apex/MonerisCheckoutService.generateTicket';
import getReceipt from '@salesforce/apex/MonerisCheckoutService.getReceipt';

export default class MonerisCheckoutLwc extends LightningElement {
    @track amount = 10.00;
    @track orderNo = 'ORDER-' + Date.now();
    @track isLoading = false;
    monerisLoaded = false;
    ticket = null;

    handleAmountChange(event) {
        this.amount = parseFloat(event.target.value);
    }

    handleOrderChange(event) {
        this.orderNo = event.target.value;
    }

    async startPayment() {
        this.isLoading = true;

        try {
            // 1️⃣ Generate ticket from Apex
            const ticketResponse = await generateTicket({ amount: this.amount, orderNo: this.orderNo });
            const parsed = JSON.parse(ticketResponse);
            this.ticket = parsed.ticket;

            // 2️⃣ Load Moneris script if not loaded
            if (!this.monerisLoaded) {
                await this.loadMonerisScript();
                this.monerisLoaded = true;
            }

            // 3️⃣ Start Moneris checkout
            this.launchCheckout(this.ticket);
        } catch (err) {
            console.error('Moneris Error:', err);
            alert('Error: ' + err.body?.message || err.message);
        } finally {
            this.isLoading = false;
        }
    }

    async loadMonerisScript() {
        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = 'https://gatewayt.moneris.com/chktv2/js/chkt_v2.00.js';
            script.onload = resolve;
            script.onerror = reject;
            document.body.appendChild(script);
        });
    }

    launchCheckout(ticket) {
        const container = this.template.querySelector('#monerisContainer');
        container.innerHTML = ''; // reset

        const checkout = new window.monerisCheckout();
        checkout.setMode('qa'); // prod later
        checkout.setCallback((data) => {
            console.log('Payment Response:', data);

            if (data.response?.success === true) {
                this.handleReceipt(ticket);
            } else {
                alert('Payment failed or cancelled.');
            }
        });

        checkout.startCheckout(ticket, container);
    }

    async handleReceipt(ticket) {
        try {
            const receiptResponse = await getReceipt({ ticket });
            const receipt = JSON.parse(receiptResponse);
            alert(`Payment Successful\nTransaction ID: ${receipt.response?.transaction?.id}`);
        } catch (err) {
            console.error('Receipt error:', err);
            alert('Could not fetch payment receipt.');
        }
    }
}
