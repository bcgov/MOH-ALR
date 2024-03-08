import { LightningElement, track, wire } from 'lwc';
import getLateFeeMap from '@salesforce/apex/LateFeeManagementTableController.getLateFeeRecs';
//import sendLateFeeRenewals from '@salesforce/apex/MassEmailController.doSendLateFee';
import updateLateFeeRecords from "@salesforce/apex/LateFeeManagementTableController.updateLateFeeRecs";
import { refreshApex } from '@salesforce/apex';
import { loadStyle } from 'lightning/platformResourceLoader';
import cssrenewalBlaTable from '@salesforce/resourceUrl/cssrenewalBlaTable';

const tableColumns = [
    {label: 'Application Id', fieldName: 'appId', type: 'url',
        typeAttributes: {label : { fieldName: 'Name' }, target: '_parent' }},
    {label: 'License Type', fieldName: 'LicenseTypeId', type: 'url',
        typeAttributes: {label : { fieldName: 'LicenseTypeName' }, target: '_parent'}},
    {label: 'Renewal Year', fieldName: 'RenewalYear__c', type: 'text'},
    {label: 'Residence Name', fieldName: 'AccId', type: 'url',
        typeAttributes: {label : {fieldName: 'AccName' }, target: '_parent'}},
    {label: 'Parent Account', fieldName: 'ParentId', type: 'url',
        typeAttributes: {label : {fieldName: 'ParentName' }, target: '_parent'}},
    {label: 'Health Authority', fieldName: 'HealthAuthorityName', type: 'text'},
    {label: 'Residence Status', fieldName: 'AccountStatus', type: 'text'},
    {label: 'Applcation Status', fieldName: 'Status', type: 'text'},
    {label: 'Renewal Details', fieldName: 'RenewalDetails', type: 'text' },
    {label: 'Late Fee Status', fieldName: 'Late_Fee_Status__c', type: 'text', editable: true},
    {label: 'Exclusion Reason', fieldName: 'ExclusionReason__c', type: 'text', editable: true,
        cellAttributes: {alignment :'left'}}


];

export default class LateFeeManagementTable extends LightningElement {

    @track error;
    @track columns = tableColumns;
    @track blaList;
    draftValues = [];
    @track hasLoaded = false; //Spinner Attribute
    
    //Wired Property
    _wiredResult;

    renderedCallback(){
        Promise.all([
            loadStyle( this, cssrenewalBlaTable)
        ]).then(() => {
            console.log(' Files Loaded ');
        }).catch(error =>{
            console.log( error.body.message );
        });
    }

    // wire method to fetch Late Fee BLA Records
    @wire(getLateFeeMap)
    wiredCallback(result){
        this._wiredResult = result;
        if(result.data){
            const data = result.data;
            let blaParsedData = JSON.parse(JSON.stringify(data));
            blaParsedData.forEach(bla => {
                if(bla.Name){
                    bla.appId = '/'+bla.Id;
                    bla.RenewalDetails =bla.RenewalError__c;
                   // bla.LateFeeStatus = bla.Late_Fee_Status__c;
                }
                if(bla.Account.Id){
                    bla.AccName = bla.Account.Name;
                    bla.AccId = '/'+bla.Account.Id;
                    bla.ParentName = bla.Account.Parent.Name;
                    bla.ParentId = '/'+bla.Account.ParentId;
                    bla.HealthAuthorityName = bla.Account.HealthAuthority__c;
                    bla.AccountStatus = bla.Account.Status__c;
                    
                    
                }
                if(bla.LicenseTypeId){
                    bla.LicenseTypeName = bla.LicenseType.Name;
                    bla.LicenseTypeId = '/'+bla.LicenseTypeId;
                }

            });
            this.blaList = blaParsedData;
            this.hasLoaded = true; //to remove spinner
            this.error = undefined;
        }
        else if(result.error){
            this.error = result.error;
            this.blaList = undefined;
        }
    }

    // on click save

    async handleSave(event){
        try{
            if(event.detail.draftValues){
                this.hasLoaded = false;
                const saveDraftValues = event.detail.draftValues;
                // Pass edited fields to Apex Controller
                await updateLateFeeRecords( { data: saveDraftValues})
                .then(result => {
                    if(result){
                        // refresh the table with updated data
                        this.refreshData(); 
                        }
                    else {
                         // if no update done manual refresh data table
                        var tempBlaList = this.blaList;
                        this.blaList = [];
                        this.blaList = tempBlaList;
                        this.hasLoaded = true;
                    }
                    this.draftValues = [];
                })
                .catch(error => {
                });

            }

        }
        catch(error){
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;

        };
    }

    // to refresh wired property
    refreshData(){
        return refreshApex(this._wiredResult);
    }

    // To send renewals on click
    /* async handleSendLateFees(){
        
        try{
            this.hasLoaded = false;
            await sendLateFeeRenewals();
            await this.refreshData();
        }catch(error){
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
        }

    }*/
    // To Generate Late Fee renewals on click
    handleGenerateLateFees(event){
            //Once set to true the flow will run
            this.renderFlow = true;
    }

    handleStatusChange(event){
      if (event.detail.status === 'FINISHED_SCREEN') {
          // make sure that you refresh your component to show latest data
            refreshApex(this._wiredResult);
          // this fires a success toast after the execution of the flow
          //  this.fireSuccessToast(); 

          //Hide the Flow again
            this.renderFlow = false;

            }
      else{
        console.log('Flow execution encountered an unexpected status.');
        }
    }

     

}