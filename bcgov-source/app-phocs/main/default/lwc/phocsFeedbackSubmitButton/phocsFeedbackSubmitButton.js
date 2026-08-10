import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class PhocsFeedbackSubmitButton extends NavigationMixin(OmniscriptBaseMixin(LightningElement)) {
    @track errorMessage = '';
    @track showCancelModal = false;

    handleCancel() {
        this.showCancelModal = true;
    }

    handleCancelNo() {
        this.showCancelModal = false;
    }

    handleCancelYes() {
        this.showCancelModal = false;

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'requestandcomplaintpage__c'
            }
        });
    }

    handleNext() {
        this.errorMessage = '';

        const email = this.omniJsonData?.SubmitComplaint?.ComplainantDetails?.EmailID;
        const phone = this.omniJsonData?.SubmitComplaint?.ComplainantDetails?.MobileNumber;

        if ((!email || email.trim() === '') &&
            (!phone || phone.trim() === '')) {

            this.errorMessage = 'Enter either a phone number or an email address to submit the request';
            return;
        }

        this.omniNextStep();
    }
}