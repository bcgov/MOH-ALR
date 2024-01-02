import { LightningElement, track, wire } from 'lwc';
import getBlaMap from '@salesforce/apex/RenewalBlaTableController.getBlaRecs';
import sendRenewals from "@salesforce/apex/MassEmailController.doSendRenewals";
import updateBlaRecs from "@salesforce/apex/RenewalBlaTableController.updateBlaRecs";
import { refreshApex } from "@salesforce/apex";

const tableColumns = [
{label: 'Application Id', fieldName: 'appId', type: 'url',
typeAttributes: {label: { fieldName: 'Name' }, target: '_parent'}},
{label: 'Application Type', fieldName: 'ApplicationType', type: 'text'},
{label: 'Renewal Year', fieldName: 'RenewalYear__c', type: 'text'},
{label: 'Residence Name2', fieldName: 'AccId', type: 'url',
    typeAttributes: {label: { fieldName: 'AccName' }, target: '_parent'}},
{label: 'Parent Account', fieldName: 'ParentId', type: 'url',
    typeAttributes: {label: { fieldName: 'ParentName' }, target: '_parent'}},
{label: 'Health Authority', fieldName: 'HealthAuthorityName', type: 'text'},
{label: 'Class Type', fieldName: 'LicenseTypeId', type: 'url',
  typeAttributes: {label: { fieldName: 'LicenseTypeName'}, target: '_parent'}},
{label: 'Status', fieldName: 'AccountStatus', type: 'text'},
{label: 'Application Status', fieldName: 'Status', type: 'text', editable: true},
{label: 'Exclusion Reason', fieldName: 'ExclusionReason__c', type: 'text', editable: true
 , cellAttributes: { alignment: 'left' }}
];

export default class RenewalBlaTable extends LightningElement {

    @track error;
    @track columns = tableColumns;
    @track blaList;
    draftValues = [];
    //wired property
    _wiredResult;

    //wire method to fetch bla records
    @wire(getBlaMap)
    wiredCallback(result) {
        this._wiredResult = result;
        if(result.data) {
            const data = result.data;
            let blaParsedData = JSON.parse(JSON.stringify(data));
            blaParsedData.forEach(bla => {
                console.log('dcs  data '+bla);
                if(bla.Name) {
                    bla.appId = '/'+bla.Id;
                }
                if(bla.Account.Id) {
                    console.log('dcs  inside '+bla);
                    bla.AccName = bla.Account.Name;
                    bla.AccId = '/'+bla.Account.Id;
                    bla.ParentName = bla.Account.Parent.Name;
                    bla.ParentId = '/'+bla.Account.ParentId;
                    bla.HealthAuthorityName = bla.Account.HealthAuthority__c;
                    bla.AccountStatus = bla.Account.Status__c;
                }
                if(bla.LicenseTypeId) {
                    bla.LicenseTypeName = bla.LicenseType.Name;
                    bla.LicenseTypeId = '/'+bla.LicenseTypeId;
                }
            });
            console.log('vsfdx'+blaParsedData);
            this.blaList = blaParsedData;
            this.error = undefined;
        } else if(result.error) {
            this.error = result.error;
            this.blaList = undefined;
        }
    }

    //on click of save
    async handleSave(event) {
        const saveDraftValues = event.detail.draftValues;
        console.log('cdscd s'+saveDraftValues+' '+event.detail.draftValues);
        console.log('cdscd s'+JSON.stringify(saveDraftValues)+' '+JSON.stringify(event.detail.draftValues));
        try {
            // Pass edited fields to the Apex controller
            await updateBlaRecs({ data: saveDraftValues });
            //refresh the table with updated data
            await this.refreshData();
            this.draftValues = [];
        } catch (error) {
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
            //this.showToastMessage('Error', message, 'error');
        };
    }

    // in order to refresh wired property
    refreshData() {
        return refreshApex(this._wiredResult);
    }

    //send renewals on click
    handleSendRenewals(event) {
        sendRenewals();
    }
}