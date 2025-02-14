import { LightningElement, api, track, wire } from 'lwc';
import getBlaMap from '@salesforce/apex/RenewalBlaTableController.getBlaRecs';
import sendRenewals from "@salesforce/apex/MassEmailController.doSendRenewals";
import updateBlaRecs from "@salesforce/apex/RenewalBlaTableController.updateBlaRecs";
import { refreshApex } from "@salesforce/apex";
import { loadStyle } from 'lightning/platformResourceLoader';
import cssrenewalBlaTable from '@salesforce/resourceUrl/cssrenewalBlaTable';
import ascendingIcon from '@salesforce/resourceUrl/ascendingIcon';
import descendingIcon from '@salesforce/resourceUrl/descendingIcon';
import BusinessLicenseApplication_OBJECT from '@salesforce/schema/BusinessLicenseApplication';
import STATUS_FIELD from '@salesforce/schema/BusinessLicenseApplication.Status';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY_BEFORE_REFRESH = 4000;

const tableColumns = [
    { label: 'Application Id', fieldName: 'appId', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'Name' }, target: '_parent' }, 
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'License Type', fieldName: 'LicenseTypeId', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'LicenseTypeName' }, target: '_parent' },
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Renewal Year', fieldName: 'RenewalYear__c', type: 'text', sortable: true,
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Residence Name', fieldName: 'AccId', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'AccName' }, target: '_parent' },
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Parent Account', fieldName: 'ParentId', type: 'url', sortable: true,
        typeAttributes: { label: { fieldName: 'ParentName' }, target: '_parent' },
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Health Authority', fieldName: 'HealthAuthorityName', type: 'text', sortable: true,
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Residence Status', fieldName: 'AccountStatus', type: 'text', sortable: true,
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Application Status', fieldName: 'Status', type: 'picklistColumn', editable: true, sortable: true,
        typeAttributes: {
            placeholder: '--None--', options: { fieldName: 'pickListOptions' }, 
            value: { fieldName: 'Status' },
            context: { fieldName: 'Id' },
        },
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' },
    { label: 'Exclusion Reason', fieldName: 'ExclusionReason__c', type: 'text', editable: true, sortable: true,
        cellAttributes: { alignment: 'left' },
        sortIconName: 'utility:arrowup', sortIconAlternativeText: 'Sorted ascending' }
];

export default class RenewalBlaTable extends LightningElement {
    
    @api recordId;
    @track error;
    @track columns = tableColumns;
    @track blaList;
    @track isdata = getBlaMap.length === 0 ? false : true;
    @track data = [];
    @track pickListOptions;
    draftValues = [];
    @track recordTypeId;
    @track hasLoaded = false;
    _wiredResult;
    searchKey = '';
    @track sortedBy;
    @track sortedDirection = 'asc';

    ascendingIconUrl = ascendingIcon;
    descendingIconUrl = descendingIcon;

    @wire(getObjectInfo, { objectApiName: BusinessLicenseApplication_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            // Handle error
        } else if (data) {
            const rtis = data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name == 'Renewal');
        }
    }

    @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: STATUS_FIELD })
    wirePickListStatus({ error, data }) {
        if (data) {
            this.pickListOptions = JSON.parse(JSON.stringify(data.values));
        } else if (error) {
            console.log(error);
        }
    }

    renderedCallback() {
        Promise.all([
            loadStyle(this, cssrenewalBlaTable)
        ]).then(() => {
            console.log('Files loaded');
        }).catch(error => {
            console.log(error.body.message);
        });
    }

    @wire(getBlaMap, { pickList: '$pickListOptions' })
    wiredCallback(result) {
        this._wiredResult = result;
        if(result.data) {
            const data = result.data;
            let blaParsedData = JSON.parse(JSON.stringify(data));
            blaParsedData.forEach(bla => {
                if (bla.Name) {
                    bla.appId = '/' + bla.Id;
                    bla.pickListOptions = this.pickListOptions;
                }
                if (bla.Account.Id) {
                    bla.AccName = bla.Account.Name;
                    bla.AccId = '/' + bla.Account.Id;
                    bla.ParentName = bla.Account.Parent.Name;
                    bla.ParentId = '/' + bla.Account.ParentId;
                    bla.HealthAuthorityName = bla.Account.HealthAuthority__c;
                    bla.AccountStatus = bla.Account.Status__c;
                }
                if (bla.LicenseTypeId) {
                    bla.LicenseTypeName = bla.LicenseType.Name;
                    bla.LicenseTypeId = '/' + bla.LicenseTypeId;
                }
            });
            this.blaList = blaParsedData;
            this.isdata = this.blaList && this.blaList.length > 0;
            this.hasLoaded = true;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.blaList = undefined;
        }
    }

    async handleSave(event) {
        try {
            if (event.detail.draftValues) {
                this.hasLoaded = false;
                const saveDraftValues = event.detail.draftValues;
                await updateBlaRecs({ data: saveDraftValues })
                    .then(result => {
                        if (result) {
                            this.refreshData();
                        } else {
                            var tempBlaList = this.blaList;
                            this.blaList = [];
                            this.blaList = tempBlaList;
                            this.hasLoaded = true;
                        }
                        this.draftValues = [];
                    }).catch(error => {
                        console.log(error);
                    });
            }
        } catch (error) {
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
            console.log(message);
        }
    }

    refreshData() {
        return refreshApex(this._wiredResult);
    }

    async handleSendRenewals(event) {
    if (!this.isdata || !this.blaList || this.blaList.length === 0) {
        //Returning Blank
        return;
    }
    try {
        this.hasLoaded = false;
        await sendRenewals();
        await this.refreshData();
        this.handleConfirm();
    } catch (error) {
        let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
            error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
        console.log(message);
    }
}
    handleConfirm() {
        const event = new ShowToastEvent({
            title: "Success",
            message: "A Max of 100 Renewals can be sent at once - Click again to process any remaining",
            variant: "success"
        });
        this.dispatchEvent(event);
        setTimeout(() => {
            location.reload();
        }, DELAY_BEFORE_REFRESH);
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
    }

    get filteredBlaList() {
        if(this.blaList && this.searchKey) {
            return this.blaList.filter(item =>{
                     return (item.AccName && item.AccName.toLowerCase().includes(this.searchKey)) ||
                    (item.Name && item.Name.toLowerCase().includes(this.searchKey)) ||
                    (item.LicenseType && item.LicenseType.Name && item.LicenseType.Name.toLowerCase().includes(this.searchKey)) ||
                    (item.RenewalYear__c && item.RenewalYear__c.toLowerCase().includes(this.searchKey)) ||
                    (item.Account && item.Account.Parent && item.Account.Parent.Name && item.Account.Parent.Name.toLowerCase().includes(this.searchKey)) ||
                    (item.AccountStatus && item.AccountStatus.toLowerCase().includes(this.searchKey)) ||
                    (item.Status && item.Status.toLowerCase().includes(this.searchKey)) ||
                    (item.Account && item.Account.HealthAuthority__c && item.Account.HealthAuthority__c.toLowerCase().includes(this.searchKey))
            });
        }
        return this.blaList;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.blaList];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));

        this.blaList = cloneData;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        // Update sort icons for all columns
        this.columns = this.columns.map(column => {
            column.sortIconName = 'utility:arrowup';
            column.sortDirection = 'asc';
            if (column.fieldName === sortedBy) {
                column.sortDirection = sortDirection;
                column.sortIconName = sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
            }
            return column;
        });
    }

    sortBy(field, reverse) {
        const isDateField = field.includes('__c') && field.includes('Date');
        const key = (a) => {
            if (isDateField) {
                return new Date(a[field]) || '';
            }
            return typeof a[field] === 'string' ? a[field].toLowerCase() : a[field];
        };

        return (a, b) => {
            const A = key(a);
            const B = key(b);

            let comparison = 0;
            if (A > B) {
                comparison = 1;
            } else if (A < B) {
                comparison = -1;
            }
            return reverse * comparison;
        };
    }
}