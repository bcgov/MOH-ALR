import { LightningElement, api, wire, track } from 'lwc';
import getDocumentsList from '@salesforce/apex/PhocsRecordFileManager.getDocumentsList';

export default class PhocsRecordFileManager extends LightningElement {
    @api recordId;
    @track documentsList =[]
    @track columns;

    isUploading = false;

    connectedCallback() {
        this.columns = [
            { label: 'Name', fieldName: 'fileName', type: 'text'},
            { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions }}
        ];
    }
    getRowActions(row, doneCallback) {
        let actions = [];
        actions.push({ label: 'Download', name: 'download'});
        doneCallback(actions);
    }  

    @wire(getDocumentsList, {parentRecordId: '$recordId'})
    wiredResult({data, error}){
        console.log('getDocumentsList'); 
        if(data){ 
           this.documentsList = data;
        }
        if(error){ 
            console.log(error)
        }
    }
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'download':
                this.downloadDocument(row);
            break;   
            default:
        }
    }
    downloadDocument(row){
        console.log('Downloading document for:', row);
        if (!row.contentDocumentId) {
            console.error('No ContentDocumentId found for this row.');
            return;
        }
        window.open(row.downloadUrl, '_blank');
    }
}
