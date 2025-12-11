import { LightningElement, api } from 'lwc';

export default class InspectionQuestionChild extends LightningElement {
    @api questionText;
    @api fieldType;
    @api assTaskId;
    @api assessmentIndicatorDefinitionId;
    @api checked = false;

    get normalizedType() {
        return this.fieldType ? this.fieldType.toLowerCase() : '';
    }

    get isText() {
        return ['text', 'string'].includes(this.normalizedType);
    }
    get isCheckbox() {
        return ['checkbox', 'boolean'].includes(this.normalizedType);
    }
    get isNumber() {
        return ['number', 'integer', 'decimal'].includes(this.normalizedType);
    }
    get isDate() {
        return ['date', 'datetime'].includes(this.normalizedType);
    }

    handlecheckboxchange(event){
        let value;
        if(this.isCheckbox){
            value = event.target.checked;
        } else {
            value = event.target.value;
        }
       

        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: {
                childId: this.assessmentIndicatorDefinitionId,
                taskId: this.assTaskId,
                value: value,
                isCheckbox: this.isCheckbox   
                }
            })
        );
    }
    
}