import { LightningElement, wire, track, api } from 'lwc';
import getPaymentLinkUrl from '@salesforce/apex/PHOCSGlobalPayHandler.getPaymentLinkUrl';    
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getPaymentSystemRedirectInfo from '@salesforce/apex/PHOCSPaymentController.getPaymentSystemRedirectInfo';


export default class PhocsPayment extends NavigationMixin(LightningElement) {
    @api regulatoryTransactionFeeId;
    error;

    ticket;
    monerisInstance;
    
    isGlobalPay = false;
    isMonerisPay = false;
    
    @api recordId;
    @api amount;
    @api customerId;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.amount = currentPageReference.state.Amount;
            this.customerId = currentPageReference.state.CustomerId;
        }
    }

    connectedCallback() {
        this.redirectPaymentGateway();
    }

    redirectPaymentGateway(){
        getPaymentSystemRedirectInfo({regulatoryTransactionFeeId:this.regulatoryTransactionFeeId})
            .then(result => {
                if(result && result.useMoneris){
                    this.isMonerisPay = true;
                    this.MonerisPayHandler();
                }
                if(result && result.useGlobalPay){
                    this.isGlobalPay = true;
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
        getPaymentLinkUrl({regulatoryTransactionFeeId:this.regulatoryTransactionFeeId})
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
}