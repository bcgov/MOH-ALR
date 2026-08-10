import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class PhocsAcknowledgeCompleteButton extends NavigationMixin(LightningElement) {

    handleSuccess() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }
}