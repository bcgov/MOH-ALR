import { LightningElement, api } from 'lwc';
import { subscribe, onError } from 'lightning/empApi';

export default class pHOCSAutoRefreshRecordPage extends LightningElement {
    @api recordId;
    channelName = '/event/PHOCSWaterRightsRefreshRecord__e';
    subscription = null;

    connectedCallback() {
        this.subscribeToPlatformEvent();
        this.registerErrorHandler();
    }

    subscribeToPlatformEvent() {
        const callback = (response) => {
            const eventRecordId = response?.data?.payload?.RecordId__c;

            if (eventRecordId === this.recordId) {
                // ✅ Get refresh count from browser
                let refreshCount = parseInt(sessionStorage.getItem('refreshCount_' + this.recordId)) || 0;

                console.log('🔄 Current refresh count: ' + refreshCount);

                // ✅ Refresh only twice
                if (refreshCount < 5) {
                    refreshCount++;
                    sessionStorage.setItem('refreshCount_' + this.recordId, refreshCount);

                    console.log('✅ Refreshing (count: ' + refreshCount + ')');

                    // ✅ Hard refresh the entire Lightning page
                    window.location.reload();
                } else {
                    console.log('✅ Refresh limit reached — no more refresh');
                }
            }
        };

        subscribe(this.channelName, -1, callback).then(resp => {
            this.subscription = resp;
        });
    }

    registerErrorHandler() {
        onError(error => {
            console.error('EMP API error: ', JSON.stringify(error));
        });
    }
}