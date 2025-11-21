import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import getChecklistItems from '@salesforce/apex/PhocsBLADocumentChecklistManager.getChecklistItems';
import uploadFileToChecklist from '@salesforce/apex/PhocsBLADocumentChecklistManager.uploadFileToChecklist';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class PhocsBLADocumentsManager extends NavigationMixin(LightningElement) {
    @api businessLicenseApplicationId;
    @track docCheckListItems =[]
    @track columns;

    isUploading = false;
    wiredChecklistItemsResult;

    connectedCallback() {
        this.columns = [
            { label: 'Name', fieldName: 'name', type: 'text'},
            { label: 'Required', fieldName: 'isRequired', type: 'text'},
            { label: 'Status', fieldName: 'status', type: 'text' },
            { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
            { type: 'action', typeAttributes: { rowActions: this.getRowActions }}
        ];
    }

    getRowActions(row, doneCallback) {
        let actions = [];
        if (row.hasFileUploaded){
            actions.push({ label: 'Download', name: 'download'});
            if(row.allowDocumentsUpload){
                actions.push({ label: 'Upload New Version', name: 'reupload'});
            }
        } else if(row.allowDocumentsUpload){
            actions.push({ label: 'Upload', name: 'upload' });
        }
        doneCallback(actions);
    }
   
    updateDocCheckListItem(updatedDocCheckListItem){
        let dclIndex = this.docCheckListItems.findIndex(item => item.docCheckListItemId === updatedDocCheckListItem.docCheckListItemId);
        let tempList = [...this.docCheckListItems];
        tempList[dclIndex] = {
            ...tempList[dclIndex],
            ...updatedDocCheckListItem
        };
        this.docCheckListItems = tempList;
        this.isUploading = false;
        console.log(this.docCheckListItems[dclIndex]);
    }

    @wire(getChecklistItems, {businessLicenseApplicationId: '$businessLicenseApplicationId'})
    wiredResult({data, error}){
        this.wiredChecklistItemsResult = data;
        console.log('getChecklistItems'); 
        if(data){ 
           this.docCheckListItems = data;
        }
        if(error){ 
            console.log(error)
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'upload':
                this.uploadDocument(row);
            break;
            case 'download':
                this.downloadDocument(row);
            break;
            case 'reupload':
                this.reuploadDocument(row);
            break;           
            default:
        }
    }

    viewDocument(row) {
        console.log('Viewing document for:', row);
        if (!row.contentDocumentId) {
            console.error('No ContentDocumentId found for this row.');
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                recordIds: [row.contentDocumentId],
                selectedRecordId: row.contentDocumentId
            }
        });
    }

    downloadDocument(row){
        console.log('Downloading document for:', row);
        if (!row.contentDocumentId) {
            console.error('No ContentDocumentId found for this row.');
            return;
        }
        window.open(row.downloadUrl, '_blank');
    }

    uploadDocument(row){
        console.log('Uploading document for:', row);
        this.handleFileUpload(row, false);
    }

    reuploadDocument(row){
          // reupload document code snippet
       console.log('reupload document for:', row);
       this.handleFileUpload(row, true);
    }

    handleFileUpload(row, replaceFile){
          // Simulate file picker programmatically
        const fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = '.pdf,.png,.jpg,.jpeg,.doc,.docx'; // Optional restrictions

        fileInput.onchange = async (event) => {
            const file = event.target.files[0];
            if (!file) {
                console.warn('No file selected');
                return;
            }

            // Read file as base64
            const reader = new FileReader();
            reader.onload = async () => {
                const base64 = reader.result.split(',')[1];
                this.isUploading = true;
                uploadFileToChecklist({
                    documentCheckListItemId: row.docCheckListItemId,
                    fileName: file.name,
                    base64Data: base64,
                    contentType: file.type,
                    replaceFile: replaceFile
                })
                .then((result) => {
                    console.log('Upload result:', result);
                    if(result.hasFileUploaded){
                        this.updateDocCheckListItem(result);
                    }
                })
                .catch((error) => {
                    this.isUploading = false;
                    console.error('Error uploading file:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error uploading file',
                            message: error.body?.message || error.message,
                            variant: 'error'
                        })
                    );
                });
            };
            reader.readAsDataURL(file);
        };
        fileInput.click();
    }

    previewHandler(event){
        console.log(event.target.dataset.id)
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: event.target.dataset.id
            }
        })
    }
}