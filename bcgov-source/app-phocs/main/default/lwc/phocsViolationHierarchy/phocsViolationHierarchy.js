import { LightningElement, api, track } from 'lwc';
import getViolationHierarchy from '@salesforce/apex/RegulatoryCodeViolationRelatedController.getViolationHierarchy';

export default class PhocsViolationHierarchy extends LightningElement {
    @api recordId;
    @track violations = [];

    activeSections = [];

    columns = [
        {
            label: 'Observations',
            fieldName: 'assessmentIndicatorName',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Regulatory Code',
            fieldName: 'regulatoryCodeName',
            type: 'text',
            wrapText: true
        },
        {
            label: 'Regulatory Code Description',
            fieldName: 'regulatoryCodeDescription',
            type: 'text',
            wrapText: true
        }
    ];

    get hasRecords() {
        return this.violations.length > 0;
    }

    connectedCallback() {
        this.loadHierarchy();
    }

    async loadHierarchy() {

        if (!this.recordId) {
            return;
        }

        try {
            const data = await getViolationHierarchy({
                recordId: this.recordId
            });

            this.violations = (data || []).map(item => {
                return {
                    ...item,
                    accordionLabel: `Inspection ${item.inspectionName}`,
                    hasComments: item.cannedComments && item.cannedComments.length > 0,
                    rowId: item.violationId
                };
            });

        } catch (error) {
            console.error('Error loading violation hierarchy', error);
            this.violations = [];
        }
    }
}