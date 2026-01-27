import { LightningElement, api } from 'lwc';

export default class InspectionQuestionChildv3 extends LightningElement {
    @api questionText;
    @api fieldType;
    @api assTaskId;
    @api assessmentIndicatorDefinitionId;
    @api checked = false;
    @api disabledQuestion = false;

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
        return this.checked 
            ? 'checkbox-container checkbox-container--selected' 
            : 'checkbox-container';
    }

    get checkboxLabel() {
        return this.checked ? 'Selected' : 'Select';
    }

    get isCompleted() {
        return this.disabledQuestion;
    }

    handleValueChange(event) {
        if(this.isCompleted) {
            return;
        }
        const isCheckbox = event.target.type === 'checkbox';
        this.dispatchEvent(new CustomEvent('valuechange', {
            detail: {
                childId: this.assessmentIndicatorDefinitionId,
                taskId: this.assTaskId,
                value: isCheckbox ? event.target.checked : event.target.value,
                isCheckbox
            }
        }));
    }

    toggleCheckbox() {
        if (this.isCompleted) {
            return;
        }else{
            this.checked = !this.checked;

            this.dispatchEvent(new CustomEvent('valuechange', {
                detail: {
                    childId: this.assessmentIndicatorDefinitionId,
                    taskId: this.assTaskId,
                    value: this.checked,
                    isCheckbox: true
                }
            }));
        }

    }
}