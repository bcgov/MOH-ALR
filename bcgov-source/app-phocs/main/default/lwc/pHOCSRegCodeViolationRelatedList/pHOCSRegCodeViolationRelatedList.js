import { LightningElement, api, track } from 'lwc';
import getRelatedViolations from '@salesforce/apex/RegulatoryCodeViolationRelatedController.getRelatedViolations';

export default class PHOCSRegCodeViolationRelatedList extends LightningElement {
    @api recordId;
    @track violations = [];

   columns = [
    {
        label: 'Name',
        fieldName: 'assessmentIndicatorName',
        type: 'text'
    },
    {
        label: 'Regulatory Code',
        fieldName: 'regulatoryCodeName',
        type: 'text'
    },
    {
        label: 'Regulatory Code Description',
        fieldName: 'regulatoryCodeDescription',
        type: 'text'
    }
];

    get hasRecords() {
        return this.violations.length > 0;
    }

    get recordCount() {
        return this.violations.length;
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        if (!this.recordId) return;

        try {
            const data = await getRelatedViolations({
                recordId: this.recordId
            });

            this.violations = (data || []).map(row => ({
    Id: row.Id,
    Name: row.Name,
    recordUrl: '/' + row.Id,
    regulatoryCodeName: row.RegulatoryCode?.Name || '',
    regulatoryCodeDescription: row.RegulatoryCode?.Subject || '',
    assessmentIndicatorName: row.InspectionAssmntInd?.AssessmentIndDefinition?.Name || ''
}));

        } catch (error) {
            console.error('Error loading related violations', error);
            this.violations = [];
        }
    }
}