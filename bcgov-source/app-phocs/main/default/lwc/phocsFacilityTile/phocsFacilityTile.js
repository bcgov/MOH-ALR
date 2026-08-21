import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getfacilities from '@salesforce/apex/PhocsFacilityTileController.getfacilities';
import getPortalContactDetails from '@salesforce/apex/PHOCSPortalContactController.getPortalContactDetails';
import tileBanner from '@salesforce/resourceUrl/tile';
export default class PhocsFacilityTile extends NavigationMixin(LightningElement) {
    bannerUrl = tileBanner;

    accounts = [];

    contactId;

    @wire(getfacilities)
    wiredAccounts({ data, error }) {

        if (data) {
            this.accounts = data.map(acc => {

                let address = [
                    acc.Physical_Address__Street__s,
                    acc.Physical_Address__City__s,
                    acc.Physical_Address__StateCode__s,
                    acc.Physical_Address__PostalCode__s,
                    acc.Physical_Address__CountryCode__s
                ]
                    .filter(Boolean)
                    .join(', ');

                return {
                    Id: acc.Id,
                    Name: acc.Name,
                    fullAddress: address,
                    status: acc.Status__c,
                    statusClass: acc.Status__c === 'Open'
                        ? 'status-pill open'
                        : 'status-pill pending',
                    tileClass:
                        acc.Status__c === 'Pending'
                            ? 'tile pending-tile'
                            : 'tile'
                };
            });

        } else if (error) {
            console.error(error);
        }
    }

    navigateToFacility(event) {
        const recordId = event.currentTarget.dataset.id;

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'FacilityDetail__c'
            },
            state: {
                recordId: recordId
            }
        });
    }

    get hasAccounts() {
        return this.accounts && this.accounts.length > 0;
    }

    connectedCallback() {
        console.log('connectedCallback fired');

        getPortalContactDetails()
            .then(result => {
                this.contactId = result;
                console.log('Contact Id:', this.contactId);

            })
            .catch(error => {
                console.error(error);
            });
    }

    handleCreateFacilityRequest() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                //url: '/facility-request-form'
                url: '/facility-request-form?ContextId=' + this.contactId
            }
        });
    }

    regiteranotherfacility() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                //url: '/facility-request-form'
                url: '/facility-request-form?ContextId=' + this.contactId
            }
        });
    }

}