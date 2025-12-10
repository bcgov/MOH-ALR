import { LightningElement, wire, track, api } from 'lwc';
import getPaymentLinkUrl from '@salesforce/apex/PHOCSGlobalPayHandler.getPaymentLinkUrl';    
import getHppJsonForEmbeddedCheckout from '@salesforce/apex/PHOCSGlobalPayHandler.getHppJsonForEmbeddedCheckout';   
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import getPaymentSystemRedirectInfo from '@salesforce/apex/PHOCSPaymentController.getPaymentSystemRedirectInfo';
import updatePaymentStatus from '@salesforce/apex/PHOCSGlobalPayHandler.updatePaymentStatus';
import { loadScript } from 'lightning/platformResourceLoader';
import globalPayJs from '@salesforce/resourceUrl/PHOCSGlobalPaymentCheckoutJS';


export default class PhocsPayment extends NavigationMixin(LightningElement) {
    iframeSrc;
    @api regulatoryTransactionFeeId;
    
    @api source;
    @api state;

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
            this.source = currentPageReference.state.source;
            this.state = currentPageReference.state.state;
        }
    }

    connectedCallback() {
      
    }

    renderedCallback() {
        const url = new URL(window.location.href);
        this.source = url.searchParams.get('source');

        if(this.source  === "GP" && this.state === "1"){
           this.updateGlobalPaymentStaus()
        }else{
            this.redirectPaymentGateway();
        }
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

    updateGlobalPaymentStaus(){
         updatePaymentStatus({regulatoryTransactionFeeId:this.regulatoryTransactionFeeId})
            .then(result => {
               this.redirectToRegTransactionFeePage();
        })
    }
    redirectToRegTransactionFeePage(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'PHOCSRegulatoryTransactionFeeDetails__c'
            },
            state: {
                recordId: this.recordId
            }
        });
    }

    MonerisPayHandler(){
        this.redirectToRegulatoryPage();
    }

    
    /* ============================================================
        GLOBAL PAY
    ============================================================ */
    globalPayHandler(){
        this.loadGlobalPayJs()
            .then(() => this.getHppJson())
            .then(hppJson => this.initGlobalPayIframe(hppJson))
            .catch(error => {
                console.error('Error in GlobalPay HPP flow:', error);
                this.error = error;
            });
    }

   loadGlobalPayJs() {
    return loadScript(this, globalPayJs)
          .then(() => {
           
            // Case 1 — it’s already on window (rare)
            if (window.RealexHpp) {
                console.log('RealexHpp found on window');
                return;
            }

            // Case 2 — it exists as a global (script-level) variable
            if (typeof RealexHpp !== 'undefined' && RealexHpp !== null) {
                console.log('RealexHpp found as global variable, attaching to window');
                window.RealexHpp = RealexHpp;
                return;
            }

            // Case 3 — the file did not define the variable
            console.error('RealexHpp not found in script after loading');
            return Promise.reject('RealexHpp not found');
        })
        .catch(error => {
            console.error('Failed to load GlobalPay script', error);
            return Promise.reject(error);
        });
    }



    getHppJson() {
        return getHppJsonForEmbeddedCheckout({ regulatoryTransactionFeeId: this.regulatoryTransactionFeeId })
            .then(result => {
                if (!result) {
                    return Promise.reject('HPP JSON is empty');
                }
                return result;
            })
            .catch(error => {
                console.error('Error fetching HPP JSON:', error);
                return Promise.reject(error);
            });
    }

    initGlobalPayIframe(hppJson) {
        if (!window.RealexHpp) {
            return Promise.reject('RealexHpp is not loaded');
        }

        // Grab the iframe container
        var iframe = this.template.querySelector('.globalPayIframe');
        if (!iframe) {
            return Promise.reject('Iframe element not found in the template');
        }

        // Ensure iframe has an ID
        if (!iframe.id) {
            iframe.id = `realex-hpp-iframe-${Date.now()}`;
        }

        // Configure RealexHpp
        RealexHpp.setHppUrl('https://pay.sandbox.realexpayments.com/pay');
        RealexHpp.setConfigItem('enableLogging', true);

        // Log HPP events
        window.addEventListener(RealexHpp.constants.logEventName, e => {
            console.log('HPP Log:', e.detail);
        });

        return new Promise((resolve, reject) => {
            // Get the embedded singleton instance
            const embeddedInstance = RealexHpp._internal.RxpEmbedded.getInstance(hppJson);

            // Set the iframe explicitly
            embeddedInstance.setIframe(iframe.id);

            // Initialize embedded mode using autoload
            RealexHpp.embedded.init(
                'autoload',
                iframe.id,
                'https://www.google.com', // merchant URL
                hppJson
            );

            // Make iframe visible
            iframe.style.display = 'block';

            resolve('Realex HPP iframe initialized');
        });
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