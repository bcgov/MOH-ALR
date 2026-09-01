import { LightningElement } from 'lwc';

export default class FaqPage extends LightningElement {

    scrollToTop() {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
}