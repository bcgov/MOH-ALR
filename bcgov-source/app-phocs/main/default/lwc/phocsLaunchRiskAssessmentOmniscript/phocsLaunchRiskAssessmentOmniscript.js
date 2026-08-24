import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOmniScriptConfiguration from '@salesforce/apex/PHOCSRiskAssessmentLaunchController.getOmniScriptConfiguration';

const OMNISCRIPT_PAGE_PATH = '/lightning/page/omnistudio/omniscript';
const THEME = 'lightning';
const TAB_ICON = 'custom:custom18';
const TAB_LABEL = 'Risk Assessment Tool';

export default class PhocsLaunchRiskAssessmentOmniscript extends NavigationMixin(LightningElement) {
    @api recordId;

    hasLaunched = false;

    @wire(CurrentPageReference)
    wiredPageReference(pageRef) {
        // Fallback for contexts where the platform does not auto-populate @api recordId.
        if (!this.recordId && pageRef) {
            this.recordId =
                pageRef.state?.recordId ||
                pageRef.attributes?.recordId ||
                pageRef.state?.c__recordId;
        }
        this.launch();
    }

    connectedCallback() {
        this.launch();
    }

    launch() {
        if (this.hasLaunched || !this.recordId) {
            return;
        }
        this.hasLaunched = true;

        getOmniScriptConfiguration({ accountId: this.recordId })
            .then((config) => {
                // standard__webPage routes through Lightning's SPA navigation instead of a
                // hard browser reload, so the sub-tab picks up the tabIcon/tabLabel properly
                // instead of getting stuck on "Loading...".
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: this.buildLaunchUrl(config)
                    }
                });
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                this.showError(error);
                this.dispatchEvent(new CloseActionScreenEvent());
            });
    }

    buildLaunchUrl(config) {
        const params = new URLSearchParams();
        params.set('omniscript__type', config.type);
        if (config.subtype) {
            params.set('omniscript__subType', config.subtype);
        }
        params.set('omniscript__language', config.language);
        params.set('omniscript__theme', THEME);
        params.set('omniscript__tabIcon', TAB_ICON);
        params.set('omniscript__tabLabel', TAB_LABEL);
        params.set('c__ContextId', this.recordId);
        return `${OMNISCRIPT_PAGE_PATH}?${params.toString()}`;
    }

    showError(error) {
        let message = 'Unable to launch the Risk Assessment Tool.';
        if (error?.body?.message) {
            message = error.body.message;
        }
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }
}