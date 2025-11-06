import { LightningElement, api, wire, track } from 'lwc';
import getDocumentsList from '@salesforce/apex/PhocsRecordFileManager.getDocumentsList';

export default class PhocsRecordFileManager extends LightningElement {
    @api recordId;
    @track documentsList = [];
    @track columns;

    isUploading = false;

    connectedCallback() {
        this.columns = [
            { label: 'Name', fieldName: 'fileName', type: 'text' },
            { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } }
        ];
    }

    getRowActions(row, doneCallback) {
        let actions = [
            { label: 'Preview', name: 'preview' },  // 👈 Added Preview action
            { label: 'Download', name: 'download' }
        ];
        doneCallback(actions);
    }

    @wire(getDocumentsList, { parentRecordId: '$recordId' })
    wiredResult({ data, error }) {
        if (data) {
            this.documentsList = data;
        }
        if (error) {
            console.error(error);
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'download':
                this.downloadDocument(row);
                break;
            case 'preview':
                this.previewDocument(row);
                break;
            default:
        }
    }

    downloadDocument(row) {
        if (!row.contentDocumentId) return;
        window.open(row.downloadUrl, '_blank');
    }

    previewDocument(row) {
        if (!row.contentDocumentId) return;
        window.open(row.previewUrl, '_blank'); // 👈 Opens preview in new tab
    }
}