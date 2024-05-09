import { LightningElement, api, track, wire } from 'lwc';
import getBlaMap from '@salesforce/apex/RenewalBlaTableController.getBlaRecs';
import sendRenewals from "@salesforce/apex/MassEmailController.doSendRenewals";
import updateBlaRecs from "@salesforce/apex/RenewalBlaTableController.updateBlaRecs";
import { refreshApex } from "@salesforce/apex";
import { loadStyle } from 'lightning/platformResourceLoader';
import cssrenewalBlaTable from '@salesforce/resourceUrl/cssrenewalBlaTable';
import BusinessLicenseApplication_OBJECT from '@salesforce/schema/BusinessLicenseApplication';
import STATUS_FIELD from '@salesforce/schema/BusinessLicenseApplication.Status';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';

const tableColumns = [
{label: 'Application Id', fieldName: 'appId', type: 'url',
typeAttributes: {label: { fieldName: 'Name' }, target: '_parent'}},
{label: 'License Type', fieldName: 'LicenseTypeId', type: 'url',
  typeAttributes: {label: { fieldName: 'LicenseTypeName'}, target: '_parent'}},
{label: 'Renewal Year', fieldName: 'RenewalYear__c', type: 'text'},
{label: 'Residence Name', fieldName: 'AccId', type: 'url',
    typeAttributes: {label: { fieldName: 'AccName' }, target: '_parent'}},
{label: 'Parent Account', fieldName: 'ParentId', type: 'url',
    typeAttributes: {label: { fieldName: 'ParentName' }, target: '_parent'}},
{label: 'Health Authority', fieldName: 'HealthAuthorityName', type: 'text'},
{label: 'Residence Status', fieldName: 'AccountStatus', type: 'text'},
{label: 'Application Status', fieldName: 'Status', type: 'picklistColumn', editable: true, 
    typeAttributes: {
        placeholder: '--None--', options: { fieldName: 'pickListOptions' }, 
        value: { fieldName: 'Status' },
        context: { fieldName: 'Id' },
        }
    },
{label: 'Exclusion Reason', fieldName: 'ExclusionReason__c', type: 'text', editable: true
 , cellAttributes: { alignment: 'left'}}
];

export default class RenewalBlaTable extends LightningElement {
    
    @api recordId;
    @track error;
    @track columns = tableColumns;
    @track blaList;
    @track isdata=getBlaMap.length===0?false:true;
    @track data = [];
    @track pickListOptions;
    draftValues = [];
    @track recordTypeId;
    @track hasLoaded = false;
   _wiredResult;
    

    @wire(getObjectInfo, { objectApiName: BusinessLicenseApplication_OBJECT })
    wiredObjectInfo({ error, data }) {
    if (error) {
        
    } else if (data) {
        const rtis = data.recordTypeInfos;
        this.recordTypeId = Object.keys(rtis).find(rti => rtis[rti].name == 'Renewal');
    }
};

   
    @wire(getPicklistValues, {
        recordTypeId: "$recordTypeId",
        fieldApiName: STATUS_FIELD
    })
          wirePickListStatus({ error, data }) {
        if (data) {
            this.pickListOptions = JSON.parse(JSON.stringify(data.values));
            console.log(data);
        } else if (error) {
            console.log(error);
        }
    }

    renderedCallback() {
        
        Promise.all([
            loadStyle( this, cssrenewalBlaTable )
            ]).then(() => {
                console.log( 'Files loaded' );
            })
            .catch(error => {
                console.log( error.body.message );
        });

    }

    
    @wire(getBlaMap, { pickList: '$pickListOptions' } )
    wiredCallback(result) {
        this._wiredResult = result;
        if(result.data) {
            const data = result.data;
            let blaParsedData = JSON.parse(JSON.stringify(data));
            blaParsedData.forEach(bla => {
                if(bla.Name) {
                    bla.appId = '/'+bla.Id;
                    bla.pickListOptions = this.pickListOptions;
                }
                if(bla.Account.Id) {
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
            this.blaList = blaParsedData;
            this.isdata = this.blaList && this.blaList.length > 0; 
            this.hasLoaded = true;
            this.error = undefined;
        } else if(result.error) {
            this.error = result.error;
            this.blaList = undefined;
            
        }
       
    }

    async handleSave(event) {
        try {
            if(event.detail.draftValues) {
                this.hasLoaded = false;
                const saveDraftValues = event.detail.draftValues;
                await updateBlaRecs({ data: saveDraftValues })
                .then(result => {
                    if(result) {
                       this.refreshData();
                    }
                    else {
                        var tempBlaList = this.blaList;
                        this.blaList = [];
                        this.blaList = tempBlaList;
                        this.hasLoaded = true;
                    }
                     this.draftValues = [];
                })
                .catch(error =>  {
                });
            }
        } catch (error) {
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
        };
    }

    refreshData() {
        return refreshApex(this._wiredResult);
    }

    async handleSendRenewals(event) {
        try {
            this.hasLoaded = false;
            await sendRenewals();
            await this.refreshData();
        } catch (error) {
            let message = error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION') ?
                error.body.message.split('EXCEPTION, ')[1].split(': [')[0] : error.body.message;
                
        };
    }
}