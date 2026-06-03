import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import hasReportingUserPermission from '@salesforce/customPermission/PHOCSReportingUser';

import getRelatedViolations from '@salesforce/apex/EnforcementActionViolationRelController.getRelatedViolations';

export default class PHOCSEnforcementActionViolationRelatedList extends NavigationMixin(LightningElement) {
    @api recordId;
    @track violations = [];
    @track isTableVisible = true;

    get isReadOnly() {
        return hasReportingUserPermission;
    }

    get columns() {
        const rowActions = [{ label: 'View', name: 'view' }];

        if (!this.isReadOnly) {
            rowActions.push(
                { label: 'Edit', name: 'edit' },
                { label: 'Remove', name: 'delete' }
            );
        }

        return [
            {
                label: 'Violation ID',
                fieldName: 'violationUrl',
                type: 'url',
                initialWidth: 150,
                typeAttributes: {
                    label: { fieldName: 'violationName' },
                    target: '_self'
                }
            },
            {
                label: 'Inspection',
                fieldName: 'inspectionUrl',
                type: 'url',
                initialWidth: 140,
                typeAttributes: {
                    label: { fieldName: 'inspectionName' },
                    target: '_self'
                }
            },
            {
                label: 'Assessment Indicator Definition',
                fieldName: 'assessmentIndicatorName',
                type: 'text',
                wrapText: true
            },
            {
                label: 'Status',
                fieldName: 'status',
                type: 'text',
                initialWidth: 110
            },
            {
                label: 'Compliance Due Date',
                fieldName: 'complianceDueDate',
                type: 'date',
                initialWidth: 170,
                typeAttributes: {
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit'
                }
            },
            {
                label: 'Days Open',
                fieldName: 'daysOpen',
                type: 'number',
                initialWidth: 100
            },
            {
                type: 'action',
                fixedWidth: 70,
                typeAttributes: {
                    rowActions: rowActions,
                    menuAlignment: 'auto'
                }
            }
        ];
    }

    connectedCallback() {
        this.loadData();
    }

    get hasRecords() {
        return this.violations && this.violations.length > 0;
    }

    get recordCount() {
        return this.violations ? this.violations.length : 0;
    }

    async loadData() {
        if (!this.recordId) return;

        try {
            const data = await getRelatedViolations({ recordId: this.recordId });

            this.violations = (data || [])
                .filter(row => row.RegulatoryCodeViolation__r)
                .map(row => {
                    const violation = row.RegulatoryCodeViolation__r;
                    return {
                        Id: row.Id,
                        violationName: violation.Name || '',
                        violationUrl: violation.Id ? '/' + violation.Id : '',
                        inspectionName: violation?.Inspection?.Name || '',
                        inspectionUrl: violation?.InspectionId ? '/' + violation.InspectionId : '',
                        assessmentIndicatorName:
                            violation?.InspectionAssmntInd?.AssessmentIndDefinition?.Name || '',
                        status: violation.Status || '',
                        complianceDueDate: violation.ComplianceDueDate || null,
                        daysOpen: violation.DaysOpen
                    };
                });

            this.isTableVisible = false;
            setTimeout(() => { this.isTableVisible = true; }, 0);

        } catch (error) {
            console.error('Load Error:', error);
            this.violations = [];
            this.showToast('Error', 'Unable to load related violations.', 'error');
        }
    }

    handleRefresh() {
        this.loadData();
    }

    handleNew() {
        const defaultValues = encodeDefaultFieldValues({
            ViolationEnforcementAction__c: this.recordId
        });

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'EnforcementActionViolation__c',
                actionName: 'new'
            },
            state: { defaultFieldValues: defaultValues }
        });
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view':
                this.handleView(row);
                break;
            case 'edit':
                this.handleEdit(row);
                break;
            case 'delete':
                this.handleDelete(row);
                break;
            default:
        }
    }

    handleView(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                objectApiName: 'EnforcementActionViolation__c',
                actionName: 'view'
            }
        });
    }

    handleEdit(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                objectApiName: 'EnforcementActionViolation__c',
                actionName: 'edit'
            }
        });
    }

    async handleDelete(row) {
        try {
            await deleteRecord(row.Id);
            this.showToast('Success', 'Violation deleted successfully.', 'success');
            await this.loadData();
        } catch (error) {
            console.error('Delete Error:', error);
            this.showToast(
                'Error',
                error?.body?.message || 'Unable to delete record.',
                'error'
            );
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}