import { LightningElement, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import fetchAccounts from '@salesforce/apex/RenewalManagementController.fetchAccounts';
import enqueueJob  from '@salesforce/apex/RenewalManagementControllerBatch.enqueueJob';


const tableColumns = [
    { label: 'Account Name', fieldName: 'Name', type: 'text' },
    {label: 'Parent Account', fieldName: 'ParentId', type: 'text',
    typeAttributes: {label: { fieldName: 'ParentName' }, target: '_parent'}},
    { label: 'Status', fieldName: 'Status__c', type: 'text' },
    { label: 'License Type', fieldName: 'LicenseType__c', type: 'text',
        typeAttributes: {label: { fieldName: 'LicenseTypeName'}, target: '_parent'}},
    { label: 'Health Authority', fieldName: 'HealthAuthority__c', type: 'text' }
];

export default class GenerateRenewals extends LightningElement {
    @track error;
    @track columns = tableColumns;
    @track accList = [];
    @track isdata = false;
    @track draftValues = [];
    @track hasLoaded = false;
    @track renderFlow = false;
    _wiredResult;

    @wire(fetchAccounts)
    wiredFetchAccounts(result) {
        this._wiredResult = result;
        if (result.data) {
            const data = result.data;
            let accParsedData = JSON.parse(JSON.stringify(data));
            accParsedData.forEach(acc => {
                if(acc.Name) {
                   acc.ParentName = acc.Parent.Name;
                    acc.ParentId = '/'+acc.ParentId;
                }
                if(acc.LicenseTypeId) {
                    acc.LicenseTypeName = acc.LicenseType.Name;
                    acc.LicenseType__c = '/'+acc.LicenseType__c;
                }
                });
            this.accList = result.data;
            this.isdata = this.accList.length > 0;
            this.hasLoaded = true;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.accList = undefined;
            this.hasLoaded = true;
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
        //alert(this.accountIds);
        //let flowVariables=this.accountIds;
        console.log('flowVariables', JSON.stringify(this.accountIds));
        enqueueJob({ recordIds: this.accountIds })
            .then(result => {
                console.log('recordIds is called');
            })
            .catch(error => {
                console.log('Error');
            });
    }

     else {
        console.log('recordIds is not called');
    }
    }
    
    async handleStatusChange(event) {
        if (event.detail.status) {
            await this.refreshData();
            //this.renderFlow = false;
        } else {
            console.log('Flow execution encountered an unexpected status.');
        }
    }
}