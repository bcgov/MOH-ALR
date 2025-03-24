/*
  @description       : created to show RegulatoryCodeViolations in the Omniscript : RiskAssessment
  @author            : Komal Gupta
  @user story        : ALR-860
*/

import { LightningElement, api, track, wire } from 'lwc';
import getRecords from '@salesforce/apex/calculateInspectionScore.getRecords';
import { refreshApex } from '@salesforce/apex';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import REGULATORYCODEVIOLATION_OBJECT from '@salesforce/schema/RegulatoryCodeViolation';
import SCOPE_FIELD from '@salesforce/schema/RegulatoryCodeViolation.Scope__c';
import SEVERITY_FIELD from '@salesforce/schema/RegulatoryCodeViolation.Severity__c';
import { updateRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

const STORAGE_KEY_SCOPE = 'selectedScopePicklistValues';
const STORAGE_KEY_SEVERITY = 'selectedSeverityPicklistValues';

const columns = [
    { label: 'Category', fieldName: 'Category', type: 'text', wrapText: true,
        cellAttributes: { class: 'wrap-text'} },
    { label: 'Code', fieldName: 'RegulatoryCode', type: 'text', wrapText: true,
        cellAttributes: { class: 'wrap-text'} },
    { label: 'Assessment Question', fieldName: 'AssessmentQuestion', type: 'text', wrapText: true,
        cellAttributes: { class: 'wrap-text'} },
        { label: 'Scope*', fieldName: 'Scope__c', type: 'picklistColumn', editable: true, wrapText: true,
        typeAttributes: {
            placeholder: '--None--', options: { fieldName: 'pickListOptions' }, 
            value: { fieldName: 'Scope__c' },
            context: { fieldName: 'Id' }
            }
        },
    { label: 'Severity*', fieldName: 'Severity__c', type: 'picklistColumn', editable: true, wrapText: true,
    typeAttributes: {
        placeholder: '--None--', options: { fieldName: 'severityOptions' }, 
        value: { fieldName: 'Severity__c' }, // default value for picklist,
        context: { fieldName: 'Id' }
        }
    },
    { label: 'Comments', fieldName: 'Description', type: 'text', editable: true }
];

export default class ShowRegulatoryViolationRecords extends OmniscriptBaseMixin(NavigationMixin(LightningElement)) {
    @api recordId;
    @api Questions1JSON;
    @track error;
    showSpinner = false;
    columns = columns;
    @track rcvList;
    @track omniQuestionsList;
    @track accountData;
    draftValues = [];
    @track data = [];
    @track rcvData;
    @track pickListOptions;
    @track severityOptions;
    @track hasLoaded = false;
    @track selectedOption;
    
    lastSavedData = [];
    _wiredResult;

    @wire(getObjectInfo, { objectApiName: REGULATORYCODEVIOLATION_OBJECT })
    objectInfo;

    //fetch picklist options
    @wire(getPicklistValues, {
        recordTypeId: "$objectInfo.data.defaultRecordTypeId",
        fieldApiName: SCOPE_FIELD
    })
    wirePickListScope({ error, data }) {
        if (data) {
            this.pickListOptions = JSON.parse(JSON.stringify(data.values));
        } else if (error) {
            console.log(error);
        }
    }

    //fetch severity options
    @wire(getPicklistValues, {
        recordTypeId: "$objectInfo.data.defaultRecordTypeId",
        fieldApiName: SEVERITY_FIELD
    })

    wirePickList({ error, data }) {
        if (data) {
            this.severityOptions = JSON.parse(JSON.stringify(data.values));
        } else if (error) {
            console.log(error);
        }
    }
    @wire(getRecords, { recordId: '$recordId', pickList: '$pickListOptions', pickList: '$severityOptions' } )
    wiredCallback(result) {
        this._wiredResult = result;
        if(this.Questions1JSON) {
            const data = this.Questions1JSON;  
            let rcvParsedData = JSON.parse(JSON.stringify(data));
            if(rcvParsedData.length > 0) {
                rcvParsedData.forEach(rcv => {
                    rcv.Category = rcv.Category;
                    rcv.RegulatoryCode = rcv.RegulatoryCode;
                    rcv.AssessmentQuestion = rcv.AssessmentQuestion;
                    rcv.pickListOptions = this.pickListOptions;
                    rcv.Scope__c = rcv.Scope;
                    rcv.severityOptions = this.severityOptions;
                    rcv.Severity__c = rcv.Severity;
                    rcv.Description = rcv.Description;
    
                });
                rcvParsedData.sort((a, b) => {
                    if (a.Category < b.Category) {
                        return -1;
                    } else if (a.Category > b.Category) {
                        return 1;
                    } else {
                        return 0;
                    }
                });

            }
            this.rcvList = rcvParsedData;
            if(this.rcvList != null){
                console.log('this.rcvList', this.rcvList);
            }
            this.hasLoaded = true;//to remove spinnner
            this.error = undefined;
        } else{
            console.log('Error Thrown', this.rcvList);
            this.hasLoaded = true;//to remove spinnner
            this.error = result.error;
        }
    }

    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.data));
 
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });
 
        //write changes back to original data
        this.data = [...copyData];
        console.log(this.data);
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = [...this.draftValues];
        //store changed value to do operations
        //on save. This will enable inline editing &
        //show standard cancel & save button
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });
 
        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        // Check if Scope__c field is empty in any draft value
        let draftValues = event.detail.draftValues;
            draftValues.forEach(ele=>{
                this.updateDraftValues(ele);
            })

        let myData = {
            "UpdateData" : this.rcvList,
            "Anotherprop" : this.draftValues
            }
            this.omniApplyCallResp(myData);
    }

    handleSave(event) {
        // Check if Scope__c field is empty in any draft value
        const isScopeEmpty = this.draftValues.some(item => !item.Scope__c);
        this.showSpinner = true;
        this.saveDraftValues = this.draftValues;
 
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
 
        // Updateing the records using the UiRecordAPi
        const promises = recordInputs.map(recordInput => updateRecord(recordInput));
        Promise.all(promises).then(res => {
            this.showToast('Success', 'Records Updated Successfully!', 'success', 'dismissable');
            this.draftValues = [];
            return this.refresh();
        }).catch(error => {
            console.log(error);
            this.showToast('Error', 'An Error Occured!!', 'error', 'dismissable');
        }).finally(() => {
            this.draftValues = [];
            this.showSpinner = false;
        });
        let myData = {
            "Step1" : this.rcvList,
            "Anotherprop" : {
            "prop1" : "anothervalue"
            }
            }
            
            this.omniApplyCallResp(myData);
    }

    handleCancel(event) {
        //remove draftValues & revert data changes
        this.data = JSON.parse(JSON.stringify(this.lastSavedData));
        this.draftValues = [];
    }

    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
    refresh() {
        return refreshApex(this._wiredResult);
    }
}