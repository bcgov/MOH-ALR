/*
  @description       : created to show AssessmentRecords in the Omniscript : RiskAssessment
  @author            : Komal Gupta
  @user story        : ALR-861
*/

import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import AssessmentIndDefinedValue_OBJECT from '@salesforce/schema/AssessmentIndDefinedValue';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { OmniscriptActionCommonUtil } from "omnistudio/omniscriptActionUtils";

const columns = [
    { label: 'Question Title', fieldName: 'QuestionTitle', type: 'text', wrapText: true,
        cellAttributes: { class: 'wrap-text'} },
    { label: 'Assessment Question', fieldName: 'AssessmentQuestion', type: 'text', wrapText: true,
        cellAttributes: { class: 'wrap-text'} },
    { label: 'Score*', fieldName: 'Value', type: 'picklistColumn', editable: true, wrapText: true,
    typeAttributes: {
        placeholder: '--None--', options: { fieldName: 'allscore' }, 
        value: { fieldName: 'scoreValue' }, // default value for picklist, need to make it required
        context: { fieldName: 'Id' }
        }
    },
    { label: 'Comments*', fieldName: 'comments', type: 'text', editable: true }
];

export default class operationAssessmentRecords extends OmniscriptBaseMixin(NavigationMixin(LightningElement)) {
    @api recordId;
    @track error;
    showSpinner = false;
    columns = columns;
    @track rcvList;
    @track accountData;
    draftValues = [];
    @track data = [];
    @track rcvData;
    @track pickListOptions;
    @track severityOptions;
    @track hasLoaded = false;
    lastSavedData = [];
    _wiredResult;

    @wire(getObjectInfo, { objectApiName: AssessmentIndDefinedValue_OBJECT })
    objectInfo;

    _actionUtil;
     questions = [];
    showBlock = false
    connectedCallback() {
        this._actionUtil = new OmniscriptActionCommonUtil();
        const options = {};
        const params = {
            input: {},
            sClassName: 'omnistudio.IntegrationProcedureService',
            sMethodName: "inspection_AssessmentQuestions",
            options: JSON.stringify(options)
        };
        this._actionUtil
            .executeAction(params, null, this, null, null)
            .then((response) => {
                response.result.IPResult.assessments.CATAssessment.forEach(currentItem => {
                    var items = {};
                    let allscore = [];
                    items.QuestionTitle = currentItem.name;
                    items.AssessmentQuestion = currentItem.description;
                    items.Id = currentItem.Id;
                    response.result.IPResult.assessments.Scores.forEach(score => {
                        if(currentItem.Id == score.Id){
                            var scoreOption = {};
                            scoreOption.label = score.scores;
                            scoreOption.value = score.scores;
                            allscore.push(scoreOption);
                        }
                    })
                    items.allscore = allscore;
                    this.questions.push(items);
                });
                this.showBlock = true;
                this.hasLoaded = true;//to remove spinnner
            })
            .catch((error) => {
                console.error(error, "ERROR");
            });
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
        let draftValues = event.detail.draftValues;
        draftValues.forEach(ele=>{
            this.updateDraftValues(ele);
        })
        let myData = {
            "UpdatedJSONScore" : this.draftValues,
            "Anotherprop" : {
            "prop1" : "anothervalue"
            }
            }
            this.omniApplyCallResp(myData);
    }

    handleSave(event) {
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