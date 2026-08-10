import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class PhocsSubmitFeedbackOptions extends NavigationMixin(LightningElement) {


    selectedValue = '';

    options = [
        {
            label: 'Requesting information or clarification',
            value: 'Request'
        },
        {
            label: 'Reporting a concern or compliant',
            value: 'Complaint'
        }
    ];


    handleChange(event) {
        this.selectedValue = event.detail.value;


        switch (this.selectedValue) {
            case 'Request':
                this.navigateToPage('SubmitARequest__c');
                break;

            case 'Complaint':
                this.navigateToPage('SubmitAComplaint__c');
                break;

            default:
                break;
        }
    }


    navigateToPage(pageName) {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageName
            }
        });
    }
}