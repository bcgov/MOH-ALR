import { LightningElement, api, wire } from 'lwc';
import getRegulatoryViolations from '@salesforce/apex/PHOCSInspectionContraventionController.getRegulatoryViolations';
export default class PhocsContraventionsDetails extends LightningElement {
    _records = [];
    caseId;
    violations = [];
    error;

    @api
    get records() {
        return this._records;
    }

    set records(value) {
        this._records = value || [];

        if (this._records.length > 0) {
            this.caseId = this._records[0].Id;
        }
    }

    @wire(getRegulatoryViolations, { caseId: '$caseId' })
    wiredViolations({ data, error }) {

        if (data) {
            this.violations = data;
            this.error = undefined;
        } else if (error) {
            this.violations = [];
            this.error = error;
            console.error('Regulatory violation error:', error);
        }
    }

    get hasViolations() {
        return this.violations.length > 0;
    }


    set records(value) {


        this._records = value || [];

        if (this._records.length > 0) {
            this.caseId = this._records[0].Id;
        }
    }

}