import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import STATUS_FIELD from '@salesforce/schema/Visit.Status';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Visit.Account.Type';
import ACCOUNT_RECORDTYPE_NAME_FIELD from '@salesforce/schema/Visit.Account.RecordTypeName__c';

import CREATED_BY_NAME_FIELD from '@salesforce/schema/Visit.CreatedBy.Name';
import CREATED_BY_ID_FIELD from '@salesforce/schema/Visit.CreatedById';
import CREATED_DATE_FIELD from '@salesforce/schema/Visit.CreatedDate';

import LAST_MODIFIED_BY_NAME_FIELD from '@salesforce/schema/Visit.LastModifiedBy.Name';
import LAST_MODIFIED_BY_ID_FIELD from '@salesforce/schema/Visit.LastModifiedById';
import LAST_MODIFIED_DATE_FIELD from '@salesforce/schema/Visit.LastModifiedDate';

const VISIBILITY_FIELDS = [
    STATUS_FIELD,
    ACCOUNT_TYPE_FIELD,
    ACCOUNT_RECORDTYPE_NAME_FIELD,
    CREATED_BY_NAME_FIELD,
    CREATED_BY_ID_FIELD,
    CREATED_DATE_FIELD,
    LAST_MODIFIED_BY_NAME_FIELD,
    LAST_MODIFIED_BY_ID_FIELD,
    LAST_MODIFIED_DATE_FIELD
];

export default class PhocsInspectionDetailsReadOnly extends LightningElement {
    @api recordId;

    inspectionInfoExpanded = true;
    webPostingExpanded = true;
    systemInfoExpanded = true;

    isLoading = true;
    hasError = false;
    errorMessage = '';

    visitRecord;

    @wire(getRecord, { recordId: '$recordId', fields: VISIBILITY_FIELDS })
    wiredVisit(result) {
        this.visitRecord = result;
    }

    handleLoad() {
        this.isLoading = false;
        this.hasError = false;
        this.errorMessage = '';
    }

    handleError(event) {
        this.isLoading = false;
        this.hasError = true;
        this.errorMessage =
            event?.detail?.message || 'Unable to load inspection details.';
    }

    handleToggleInspectionInfo() {
        this.inspectionInfoExpanded = !this.inspectionInfoExpanded;
    }

    handleToggleWebPosting() {
        this.webPostingExpanded = !this.webPostingExpanded;
    }

    handleToggleSystemInfo() {
        this.systemInfoExpanded = !this.systemInfoExpanded;
    }

    get inspectionInfoIcon() {
        return this.inspectionInfoExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get webPostingIcon() {
        return this.webPostingExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get systemInfoIcon() {
        return this.systemInfoExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get formClass() {
        return this.isLoading ? 'form-hidden' : '';
    }

    get isStatusCompleted() {
        return getFieldValue(this.visitRecord?.data, STATUS_FIELD) === 'Completed';
    }

    get isAccountTypeDairy() {
        return getFieldValue(this.visitRecord?.data, ACCOUNT_TYPE_FIELD) === 'Dairy';
    }

    get showWebPostingSection() {
        return getFieldValue(this.visitRecord?.data, ACCOUNT_RECORDTYPE_NAME_FIELD) !== 'PHOCSDairyFacility';
    }

    get createdByName() {
        return getFieldValue(this.visitRecord?.data, CREATED_BY_NAME_FIELD) || '';
    }

    get createdByUrl() {
        const id = getFieldValue(this.visitRecord?.data, CREATED_BY_ID_FIELD);
        return id ? `/lightning/r/User/${id}/view` : '#';
    }

    get createdDateFormatted() {
        return this.formatDateTime(
            getFieldValue(this.visitRecord?.data, CREATED_DATE_FIELD)
        );
    }

    get lastModifiedByName() {
        return getFieldValue(this.visitRecord?.data, LAST_MODIFIED_BY_NAME_FIELD) || '';
    }

    get lastModifiedByUrl() {
        const id = getFieldValue(this.visitRecord?.data, LAST_MODIFIED_BY_ID_FIELD);
        return id ? `/lightning/r/User/${id}/view` : '#';
    }

    get lastModifiedDateFormatted() {
        return this.formatDateTime(
            getFieldValue(this.visitRecord?.data, LAST_MODIFIED_DATE_FIELD)
        );
    }

    formatDateTime(value) {
        if (!value) {
            return '';
        }

        try {
            return new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: 'numeric',
                day: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                second: '2-digit',
                hour12: true
            }).format(new Date(value));
        } catch (e) {
            return value;
        }
    }
}