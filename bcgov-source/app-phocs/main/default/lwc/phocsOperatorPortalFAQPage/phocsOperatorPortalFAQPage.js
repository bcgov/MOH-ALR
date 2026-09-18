import { LightningElement } from 'lwc';
export default class PhocsOperatorPortalFAQPage extends LightningElement {
     scrollToTop() {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}