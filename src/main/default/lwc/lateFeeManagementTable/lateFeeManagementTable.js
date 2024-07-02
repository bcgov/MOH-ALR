import { LightningElement, api, track, wire } from 'lwc';
import getLateFeeMap from '@salesforce/apex/LateFeeManagementTableController.getLateFeeRecs';
import sendLateFeeRenewals from '@salesforce/apex/MassEmailController.doSendLateFee';
import updateLateFeeRecords from "@salesforce/apex/LateFeeManagementTableController.updateLateFeeRecs";
import { refreshApex } from '@salesforce/apex';
import { loadStyle } from 'lightning/platformResourceLoader';
import cssrenewalBlaTable from '@salesforce/resourceUrl/cssrenewalBlaTable';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import BusinessLicenseApplication_OBJECT from '@salesforce/schema/BusinessLicenseApplication';
import LATE_FEE_STATUS__C_FIELD from '@salesforce/schema/BusinessLicenseApplication.Late_Fee_Status__c';
import LightningConfirm from "lightning/confirm";
import ascendingIcon from '@salesforce/resourceUrl/ascendingIcon';
import descendingIcon from '@salesforce/resourceUrl/descendingIcon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY_BEFORE_REFRESH = 2000;

const tableColumns = [
    {label: 'Application Id', fieldName: 'appId', type: 'url',sortable: true,
        typeAttributes: {label : { fieldName: 'Name' }, target: '_parent' }},
    {label: 'License Type', fieldName: 'LicenseTypeId', type: 'url',sortable: true,
        typeAttributes: {label : { fieldName: 'LicenseTypeName' }, target: '_parent'}},
    {label: 'Renewal Year', fieldName: 'RenewalYear__c', type: 'text',sortable: true},
    {label: 'Residence Name', fieldName: 'AccId', type: 'url',sortable: true,
        typeAttributes: {label : {fieldName: 'AccName' }, target: '_parent'}},
    {label: 'Parent Account', fieldName: 'ParentId', type: 'url',sortable: true,
        typeAttributes: {label : {fieldName: 'ParentName' }, target: '_parent'}},
    {label: 'Health Authority', fieldName: 'HealthAuthorityName', type: 'text',sortable: true},
    {label: 'Residence Status', fieldName: 'AccountStatus', type: 'text',sortable: true},
    {label: 'Application Status', fieldName: 'Status', type: 'text',sortable: true},
    {label: 'Renewal Detail', fieldName: 'RenewalDetail', type: 'text',sortable: true },
    {label: 'Late Fee Status', fieldName: 'Late_Fee_Status__c', type: 'picklistColumn', editable: true, sortable: true,
    typeAttributes: {
        placeholder: '--None--', options: { fieldName: 'pickListOptions' }, 
        value: { fieldName: 'Late_Fee_Status__c' },
        context: { fieldName: 'Id' },
        }
    },
    {label: 'Exclusion Reason', fieldName: 'ExclusionReason__c', type: 'text', editable: true,sortable: true,
        cellAttributes: {alignment :'left'}}
];
export default class LateFeeManagementTable extends LightningElement {
    
    @api recordId;
    @track error;
    @track columns = tableColumns;
    @track blaList;
    @track isdata=getLateFeeMap.length===0?false:true;
    draftValues = [];
    @track data = [];
    @track pickListOptions;
    @track recordTypeId;
    @track hasLoaded = false; 
    @track renderFlow = false;
    _wiredResult;
    searchKey = '';
    @track sortedBy;
    @track sortedDirection = 'asc';

    ascendingIconUrl = ascendingIcon;
    descendingIconUrl = descendingIcon;

    @wire(getObjectInfo, { objectApiName: BusinessLicenseApplication_OBJECT })
    objectInfo;

    //fetch picklist options
    @wire(getPicklistValues, {
        recordTypeId: "$objectInfo.data.defaultRecordTypeId",
        fieldApiName: LATE_FEE_STATUS__C_FIELD
    })
    wirePickListScope({ error, data }) {
        if (data) {
            this.pickListOptions = JSON.parse(JSON.stringify(data.values));
        } else if (error) {
            console.log(error);
        }
    }
    renderedCallback(){
        Promise.all([
            loadStyle( this, cssrenewalBlaTable)
        ]).then(() => {
            console.log(' Files Loaded ');
        }).catch(error =>{
            console.log( error.body.message );
        });
    }
    @wire(getLateFeeMap)
    wiredCallback(result){
        this._wiredResult = result;
        if(result.data){
            const data = result.data;
            let blaParsedData = JSON.parse(JSON.stringify(data));
            blaParsedData.forEach(bla => {
                if(bla.Name){
                    bla.appId = '/'+bla.Id;
                    bla.RenewalDetail =bla.RenewalDetail__c;
                    bla.pickListOptions = this.pickListOptions;
                }
                if(bla.Account.Id){
                    bla.AccName = bla.Account.Name;
                    bla.AccId = '/'+bla.Account.Id;
                    bla.ParentName = bla.Account.Parent.Name;
                    bla.ParentId = '/'+bla.Account.ParentId;
                    bla.HealthAuthorityName = bla.Account.HealthAuthority__c;
                    bla.AccountStatus = bla.Account.Status__c;    
                }
                if(bla.LicenseTypeId){
                    bla.LicenseTypeName = bla.LicenseType.Name;
                    bla.LicenseTypeId = '/'+bla.LicenseTypeId;
                }
            });
            this.blaList = blaParsedData;
            this.isdata = this.blaList && this.blaList.length > 0; 
            this.hasLoaded = true; 
            this.error = undefined;
        }
        else if(result.error){
            this.error = result.error;
            this.blaList = undefined;
        }
    }
    async handleSave(event){
        try{
            if(event.detail.draftValues){
                this.hasLoaded = false;
                const saveDraftValues = event.detail.draftValues;
                await updateLateFeeRecords( { data: saveDraftValues})
                .then(result => {
                    if(result){
                        this.refreshData(); 
                        }
                    else {
                        var tempBlaList = this.blaList;
                        this.blaList = [];
                        this.blaList = tempBlaList;
                        this.hasLoaded = true;
                    }
                    this.draftValues = [];
                })
                .catch(error => {
                });
            }
        }
        catch(error){
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
        };
    }
    refreshData(){
        return refreshApex(this._wiredResult);
    }
     async handleSendLateFees(){
        
        try{
            this.hasLoaded = false;
            await sendLateFeeRenewals();
            await this.refreshData();
            this.handleConfirmSendLateFee();
        }catch(error){
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
        }
    }
    
    handleConfirmSendLateFee(){
        const event = new ShowToastEvent({
            title: "Success",
            message: "Late Fees Sent Successfully",
            variant: "success"
        });
        this.dispatchEvent(event);
        setTimeout(() => {
            location.reload();
        }, DELAY_BEFORE_REFRESH);
    }

    handleGenerateLateFees(event){
            this.renderFlow = true;
    }
    
    handleConfirmGenerateLateFee(){
      const event = new ShowToastEvent({
            title: "Success",
            message: "Late Fees Generated Successfully",
            variant: "success"
        });
      setTimeout(() => {
            location.reload();
        }, DELAY_BEFORE_REFRESH);
    }

    async handleStatusChange(event){
      if (event.detail.status === 'FINISHED_SCREEN') {
          this.handleConfirmGenerateLateFee();
            await this.refreshData();
            refreshApex(this._wiredResult);
            this.renderFlow = false;
            }
      else{
        console.log('Flow execution encountered an unexpected status.');
        }
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value.toLowerCase();
    }
    get filteredBlaList() {
        if (this.blaList && this.searchKey) {
            return this.blaList.filter(item =>
                item.AccName.toLowerCase().includes(this.searchKey) ||
                item.Name.toLowerCase().includes(this.searchKey) ||
                item.LicenseType.Name.toLowerCase().includes(this.searchKey) ||
                item.RenewalYear__c.toLowerCase().includes(this.searchKey) ||
                item.Account.Parent.Name.toLowerCase().includes(this.searchKey) ||
                item.AccountStatus.toLowerCase().includes(this.searchKey) ||
                item.Status.toLowerCase().includes(this.searchKey) ||
                item.Account.HealthAuthority__c.toLowerCase().includes(this.searchKey) ||
                item.Late_Fee_Status__c.toLowerCase().includes(this.searchKey) ||
                item.RenewalDetail.toLowerCase().includes(this.searchKey)
            );
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