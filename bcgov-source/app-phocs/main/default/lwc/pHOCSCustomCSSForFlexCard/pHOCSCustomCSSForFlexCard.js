import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import MY_CUSTOM_STYLES from '@salesforce/resourceUrl/phocs_flexCard_Global_CSS'; // Replace 'PHOCS_flexCard_Global_CSS' with your static resource name
export default class PHOCSCustomCSSForFlexCard extends LightningElement {
    connectedCallback() {
        Promise.all([
            loadStyle(this, MY_CUSTOM_STYLES + '/PHOCS_flexCard_Global_CSS.css') // Path within the static resource
        ])
        .then(() => {
            console.log('CSS loaded successfully');
        })
        .catch(error => {
            console.error('Error loading CSS:', error);
        });
    }
}