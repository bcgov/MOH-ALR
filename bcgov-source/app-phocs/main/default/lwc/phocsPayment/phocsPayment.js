import { LightningElement,api } from 'lwc';
import getPaymentLinkUrl from '@salesforce/apex/PaymentController.getPaymentLinkUrl';    
import { NavigationMixin } from 'lightning/navigation';

export default class PhocsPayment extends NavigationMixin(LightningElement) {
    @api recordId;
    @api contactId;
    error;

    connectedCallback() {
        this.redirectUserGlobalPayPaymentPage();
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
       // window.location = paymentPageUrl;

           this[NavigationMixin.Navigate](
           {
                type: "standard__webPage",
                attributes: {
                url: paymentPageUrl
                }
            },
            false // Replaces the current page in your browser history with the URL
            );
    }
}