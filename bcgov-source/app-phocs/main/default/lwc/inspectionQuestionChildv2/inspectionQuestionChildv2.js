import { LightningElement, api, track } from 'lwc';

export default class InspectionQuestionChildv2 extends LightningElement {
    @api questionText;
    @api fieldType;
    @api assTaskId;
    @api assessmentIndicatorDefinitionId;
    @api disabledQuestion = false;

    @track _checked = false;

    @api
    get checked() {
        return this._checked;
    }
    set checked(value) {
        this._checked = value === true;
    }

    get normalizedType() {
        return this.fieldType?.toLowerCase() || '';
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

    get checkboxContainerClass() {
        return this._checked
            ? 'checkbox-container checkbox-container--selected'
            : 'checkbox-container';
    }

    get isCompleted() {
        return this.disabledQuestion;
    }

    handleValueChange(event) {
        if (this.isCompleted) return;

        const isCheckbox = event.target.type === 'checkbox';
        const value = isCheckbox ? event.target.checked : event.target.value;

        if (isCheckbox) {
            this._checked = value;
        }

        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: {
                    childId: this.assessmentIndicatorDefinitionId,
                    taskId: this.assTaskId,
                    value,
                    isCheckbox
                },
                bubbles: true,
                composed: true
            })
        );
    }
}