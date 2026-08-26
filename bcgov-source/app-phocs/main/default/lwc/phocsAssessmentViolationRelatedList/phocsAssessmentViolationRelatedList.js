import { LightningElement, api } from 'lwc';
import getRelatedViolations from '@salesforce/apex/PHOCSAsmntVioRelatedController.getRelatedViolations';

export default class PhocsAssessmentViolationRelatedList extends LightningElement {
    @api recordId;
    violations = [];
    isLoading = false;

    columns = [
        {
            label: 'Name',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            },
            wrapText: true
        },
        {
            label: 'Regulatory Code',
            fieldName: 'regulatoryCodeName',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Inspection Question',
            fieldName: 'inspectionQuestion',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Scope',
            fieldName: 'scope',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Severity',
            fieldName: 'severity',
            type: 'text',
            wrapText: true
        }
    ];

    get hasRecords() {
        return this.violations.length > 0;
    }

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;

        try {
            const data = await getRelatedViolations({ assessmentId: this.recordId });

            this.violations = (data || []).map(row => ({
                Id: row.Id,
                Name: row.Name,
                recordUrl: `/lightning/r/RegulatoryCodeViolation/${row.Id}/view`,
                regulatoryCodeName: row.RegulatoryCode?.Name || '',
                inspectionQuestion: row.InspectionAssmntInd?.AssessmentIndDefinition?.Name || '',
                scope: row.Scope__c || '',
                severity: row.Severity__c || ''
            }));
        } catch (error) {
            console.error('Error loading related violations', error);
            this.violations = [];
        } finally {
            this.isLoading = false;
        }
    }
}