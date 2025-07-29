import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';

export default class TabRefresher extends LightningElement {
    subscription;

    connectedCallback() {
        this.subscribeToEvent();
    }

    subscribeToEvent() {
        const channelName = '/event/RefreshEvent__e';
        const messageCallback = (response) => {
            location.reload();
        };

        subscribe(channelName, -1, messageCallback).then(response => {
            this.subscription = response;
        }).catch(error => {
            console.error('Error subscribing to channel ', JSON.stringify(error));
        });
    }

    disconnectedCallback() {
        unsubscribe(this.subscription, response => {
        });
    }
}