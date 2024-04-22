import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import { api } from 'lwc';

export default class accountContactRelationship extends NavigationMixin(LightningElement) {
    @api recordId;
    navigateToOmniScript() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/lightning/page/omnistudio/omniscript?omniscript__type=EHIS&omniscript__subType=AccountContactRelation&omniscript__language=English&omniscript__theme=lightning&omniscript__tabIcon=custom:custom18&omniscript__tabLabel=Contact&c__ContextId=${this.recordId}'
            }
        });
    }
}