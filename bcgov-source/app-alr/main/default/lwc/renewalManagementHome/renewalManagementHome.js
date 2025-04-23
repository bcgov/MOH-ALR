import { LightningElement } from 'lwc';
import srcsize from '@salesforce/client/formFactor';
export default class RenewalManagementHome extends LightningElement {

    get smallscreen()
    {
        return srcsize =="Small";
    }
    
}