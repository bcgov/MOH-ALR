import { LightningElement, api, track, wire } from 'lwc';
import getUnitBasedOnResidence from '@salesforce/apex/ManageUnitsController.getUnitBasedOnResidence';
import updateUnits from "@salesforce/apex/ManageUnitsController.updateUnits";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import TYPE_FIELD from '@salesforce/schema/Asset.Type__c';
import CAPACITY_FIELD from '@salesforce/schema/Asset.Capacity__c';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import ASSET_OBJECT from "@salesforce/schema/Asset";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const columns = [
    {
        label: 'Type',
        fieldName: 'Type__c',
        type: 'text',
    },
    {
        label: 'Quantity',
        fieldName: 'Quantity',
        type: 'number',
        cellAttributes: {
            alignment: 'center',
        },
        editable: false
    },
    {
        label: 'Updated Quantity',
        fieldName: 'Quantity',
        type: 'number',
        cellAttributes: {
            alignment: 'center',
        },
        editable: true
    },
    {
        label: 'Capacity',
        fieldName: 'Capacity__c',
        type: 'number',
        cellAttributes: {
            alignment: 'center',
        },
    }
];
export default class ManageUnits extends LightningElement {

    @api recordId;
    draftValues = [];
    datatableHeight;
    column = columns;
    isLoading = false;
    noRecord = false;
    @track recordList;
    initialRecords;
    capacity;
    type;
    @track objectInfo;
    @track recordTypeId;

    @wire(getObjectInfo, { objectApiName: ASSET_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (error) {
            // handle Error
        } else if (data) {
            const rtis = data.recordTypeInfos;
            this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name === 'Units Record Type');
        }
    };

    @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: TYPE_FIELD })
    typeOptions;
    @wire(getPicklistValues, { recordTypeId: "$recordTypeId", fieldApiName: CAPACITY_FIELD })
    capacityOptions;

    connectedCallback() {

        if (this.recordId) {
            this.isLoading = true;
            this.fetchTableData();

        }
    }

    fetchTableData() {
        getUnitBasedOnResidence({ recordId: this.recordId }).then(result => {
            this.recordList = JSON.parse(result);
            this.initialRecords = this.recordList;
            console.log('this.recordList::' + this.recordList);
            this.isLoading = false;
            this.noRecord = this.recordList.length === 0 ? true : false;
            this.datatableHeight = this.noRecord ? 'height:50px;' : 'height:420px;';
        }).catch((error) => {
            this.isLoading = false;
            this.showToastMessage("Error", error.body.message, "error");
        });
    }

    async handleSave(event) {
        const updatedFields = event.detail.draftValues;
        let isValidInput = true;
        console.log('updatedFields--');
        console.log(JSON.stringify(event.detail.draftValues));
        try {
            // Pass edited fields to the updateUnits Apex controller
            updatedFields.forEach((element) => {
                if (element.Quantity === '') {
                    isValidInput = false;
                    return;
                }
            });
            if (isValidInput) {
                await updateUnits({ data: updatedFields });
                this.showToastMessage("Success", 'Unit(s) has been successfully updated.', "success");
                // Clear all draft values in the datatable
                this.isLoading = true;
                await this.fetchTableData();
                this.draftValues = [];
            } else {
                this.showToastMessage("Error", 'Updated Quantity cannot be equal,null, negative or greater than the existing quantity.', "error");
            }
        } catch (error) {
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
            this.showToastMessage('Error', message, 'error');
        };
    }
    handleTypeChange(event) {
        this.type = event.target.value;
    }
    handleCapacityChange(event) {
        this.capacity = event.target.value;
    }
    handleClearSearch() {
        this.isLoading = true;
        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            each.value = '';
        });
        this.capacity = '';
        this.type = '';
        this.fetchTableData();

    }
    handleSearch() {
        let filteredList;
        let records = this.initialRecords;
        console.log('type--' + this.type);
        console.log('capacity--' + this.capacity);
        if (this.type && this.capacity) {
            this.isLoading = true;
            filteredList = records.filter(item => item.Type__c === this.type && item.Capacity__c === this.capacity);
        } else if (this.type && (this.capacity === '' || this.capacity == undefined)) {
            this.isLoading = true;
            filteredList = records.filter(item => item.Type__c === this.type);
        } else if (this.capacity && (this.type === '' || this.type == undefined)) {
            this.isLoading = true;
            filteredList = records.filter(item => item.Capacity__c === this.capacity);
        } else {
            this.isLoading = true;
            filteredList = this.initialRecords;
        }
        this.isLoading = false;
        this.recordList = filteredList;

    }

    /**START HERE-->Show toast to display the messages*/
    showToastMessage(title, eventMessage, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: eventMessage,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
    /**END HERE */
}