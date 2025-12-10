import { LightningElement, api } from 'lwc';

export default class InspectionQuestionChild extends LightningElement {
    @api questionText;
    @api fieldType;
    @api assTaskId;
    @api assessmentIndicatorDefinitionId;

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

    handleValueChange(event) {
        let value;
        if (this.isCheckbox) {
            value = event.target.checked;
        } else {
            value = event.target.value;
        }

        const detail = {
            value: String(value),
            parentId: this.template.host.dataset.parentId,
            childId: this.assessmentIndicatorDefinitionId
        };
        this.dispatchEvent(new CustomEvent('valuechange', { detail }));
    }

    
}