import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccounts from '@salesforce/apex/RenewalManagementController.fetchAccounts';
import enqueueJob from '@salesforce/apex/RenewalManagementControllerBatch.enqueueJob';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ascendingIcon from '@salesforce/resourceUrl/ascendingIcon';
import descendingIcon from '@salesforce/resourceUrl/descendingIcon';

const DELAY_BEFORE_REFRESH = 2000;

const tableColumns = [
    { label: 'Residence ID', fieldName: 'RegId__c', type: 'text', sortable: true },
    { label: 'Account Name', fieldName: 'accountUrl', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'Name' }, target: '_self' } },
    { label: 'Parent Account', fieldName: 'parentAccountUrl', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'parentAccountName' }, target: '_self' } },
    { label: 'Status', fieldName: 'Status__c', type: 'text', sortable: true },
    { label: 'Health Authority', fieldName: 'HealthAuthority__c', type: 'text', sortable: true },
    { label: 'License Type', fieldName: 'licenseTypeUrl', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'LicenseTypeName' }, target: '_self' } }
];

export default class GenerateRenewals extends NavigationMixin(LightningElement) {
    @track accounts;
    @track filteredAccounts;
    @track columns = tableColumns;
    @track hasLoaded = false;
    @track isdata = false;
    @track searchKey = '';
    @track sortedBy;
    @track sortedDirection = 'asc';
    @track selectedRecordIds = new Set();

    ascendingIconUrl = ascendingIcon;
    descendingIconUrl = descendingIcon;

    wiredAccountsResult;

    @wire(getAccounts)
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        if (result.data) {
            this.accounts = result.data.map(account => ({
                ...account,
                accountUrl: `/lightning/r/Account/${account.Id}/view`,
                parentAccountUrl: account.ParentId ? `/lightning/r/Account/${account.ParentId}/view` : null,
                parentAccountName: account.Parent ? account.Parent.Name : '',
                licenseTypeUrl: account.LicenseType__c ? `/lightning/r/LicenseType/${account.LicenseType__c}/view` : null,
                LicenseTypeName: account.LicenseType__r ? account.LicenseType__r.Name : ''
            }));
            this.applyFilters();
            this.hasLoaded = true;
        } else if (result.error) {
            console.error('Error fetching accounts:', result.error);
            this.handleError();
        }
    }

    handleError() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'Failed to fetch account data.',
            variant: 'error'
        });
        this.dispatchEvent(event);
    }

    applyFilters() {
        if (this.accounts && this.searchKey) {
            this.filteredAccounts = this.accounts.filter(account =>
                Object.values(account).some(
                    value => typeof value === 'string' && value.toLowerCase().includes(this.searchKey.toLowerCase())
                )
            );
        } else {
            this.filteredAccounts = this.accounts;
        }
        this.isdata = this.filteredAccounts.length > 0;
        this.restoreSelection();
        console.log('filter', this.filteredAccounts);
    }

    handleGenerateRenewals() {
        const selectedRows = this.template.querySelector('lightning-datatable').getSelectedRows();
        if (selectedRows.length > 0) {
            const accountIds = selectedRows.map(row => row.Id);
            enqueueJob({ recordIds: accountIds })
                .then(data => {
                    this.handleConfirm();
                })
                .catch(error => {
                    console.error('Error enqueuing job:', error);
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to generate renewals.',
                        variant: 'error'
                    });
                    this.dispatchEvent(event);
                });
        } else {
            const event = new ShowToastEvent({
                title: 'Warning',
                message: 'Please select at least one account to generate renewals.',
                variant: 'warning'
            });
            this.dispatchEvent(event);
        }
    }

    handleConfirm() {
        const event = new ShowToastEvent({
            title: 'Success',
            message: 'Renewals Generated Successfully',
            variant: 'success'
        });
        this.dispatchEvent(event);
        setTimeout(() => {
            location.reload();
        }, DELAY_BEFORE_REFRESH);
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
        console.log('search',this.searchKey);
        this.applyFilters();
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;
        this.sortData(sortedBy, sortDirection);
    }

    sortData(field, direction) {
        let parseData = JSON.parse(JSON.stringify(this.filteredAccounts));
        const fieldValue = row => {
            return row[field] ? row[field].toLowerCase() : '';
        };
        const reverse = direction === 'asc' ? 1 : -1;
        parseData.sort((value1, value2) => {
            return reverse * ((fieldValue(value1) > fieldValue(value2)) - (fieldValue(value1) < fieldValue(value2)));
        });
        this.filteredAccounts = parseData;
        this.restoreSelection(); 
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        selectedRows.forEach(row => {
            this.selectedRecordIds.add(row.Id);
        });
        this.filteredAccounts.forEach(account => {
            if (!selectedRows.some(row => row.Id === account.Id)) {
                this.selectedRecordIds.delete(account.Id);
            }
        });
        this.restoreSelection();
    }

    restoreSelection() {
        if (this.template.querySelector('lightning-datatable')) {
            this.template.querySelector('lightning-datatable').selectedRows = Array.from(this.selectedRecordIds);
        }
    }
}