import { LightningElement, api } from 'lwc';
import getRelatedViolations from '@salesforce/apex/PHOCSAsmntVioRelatedController.getRelatedViolations';

export default class PhocsAssessmentViolationRelatedList extends LightningElement {
    @api recordId;
    violations = [];
    isLoading = false;
    isRiskReAssessment = false;

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

    get displayColumns() {
        if (this.isRiskReAssessment) {
            return [
                ...this.columns,
                {
                    label: 'Comment',
                    fieldName: 'comment',
                    type: 'text',
                    wrapText: true
                }
            ];
        }

        return this.columns;
    }

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
            const data = await getRelatedViolations({
                assessmentId: this.recordId
            });

            this.isRiskReAssessment = data?.isRiskReAssessment || false;

            this.violations = (data?.violations || []).map(row => ({
                Id: row.id,
                Name: row.violationName,
                recordUrl: `/lightning/r/RegulatoryCodeViolation/${row.id}/view`,
                regulatoryCodeName: row.regulatoryCode || '',
                inspectionQuestion: row.inspectionQuestion || '',
                scope: row.scope || '',
                severity: row.severity || '',
                comment: row.comment || ''
            }));
        } catch (error) {
            console.error('Error loading related violations', error);
            this.violations = [];
            this.isRiskReAssessment = false;
        } finally {
            this.isLoading = false;
        }
    }
}