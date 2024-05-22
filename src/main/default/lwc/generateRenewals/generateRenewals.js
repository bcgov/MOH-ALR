import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccounts from '@salesforce/apex/RenewalManagementController.fetchAccounts';
import enqueueJob from '@salesforce/apex/RenewalManagementControllerBatch.enqueueJob';
import { NavigationMixin } from 'lightning/navigation';

const tableColumns = [
    { label: 'Residence ID', fieldName: 'RegId__c', type: 'text' },
    { label: 'Account Name', fieldName: 'accountUrl', type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
    { label: 'Parent Account', fieldName: 'parentAccountUrl', type: 'url',
        typeAttributes: { label: { fieldName: 'parentAccountName' }, target: '_blank' } },
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'Health Authority', fieldName: 'HealthAuthority__c', type: 'text' },
    { label: 'License Type', fieldName: 'licenseTypeUrl', type: 'url',
        typeAttributes: { label: { fieldName: 'LicenseTypeName' }, target: '_blank' } }
];

export default class GenerateRenewals extends NavigationMixin(LightningElement) {
    @track error;
    columns = tableColumns;
    accounts;
    @track accList = [];
    @track isdata = false;
    @track draftValues = [];
    @track hasLoaded = false;
    @track renderFlow = false;
    
    _wiredResult;

    @wire(getAccounts)
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data.map(account => {
                return {
                    ...account,
                    accountUrl: `/lightning/r/Account/${account.Id}/view`,
                    parentAccountUrl: account.ParentId ? `/lightning/r/Account/${account.ParentId}/view` : null,
                    parentAccountName: account.Parent ? account.Parent.Name : '',
                    licenseTypeUrl: account.LicenseType__c ? `/lightning/r/LicenseType/${account.LicenseType__c}/view` : null,
                    LicenseTypeName: account.LicenseType__r ? account.LicenseType__r.Name : ''
                };
            });
            this.error = undefined;
            this.hasLoaded = true;
            this.isdata = this.accounts.length > 0;
        } else if (error) {
            this.error = error;
            this.accounts = undefined;
            this.hasLoaded = false;
        }
    }

    refreshData() {
        return refreshApex(this._wiredResult);
    }

    handleGenerateRenewals() {
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        if (selectedRows.length > 0) {
            console.log('flow is called');
            this.accountIds = selectedRows.map(row => row.Id);
            console.log('flowVariables', JSON.stringify(this.accountIds));
            enqueueJob({ recordIds: this.accountIds })
                .then(result => {
                    console.log('recordIds is called');
                })
                .catch(error => {
                    console.log('Error');
                });
        } else {
            console.log('recordIds is not called');
        }
    }

    async handleStatusChange(event) {
        if (event.detail.status) {
            await this.refreshData();
        } else {
            console.log('Flow execution encountered an unexpected status.');
        }
    }
}