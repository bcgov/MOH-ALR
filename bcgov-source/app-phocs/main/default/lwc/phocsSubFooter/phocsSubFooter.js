// accountHealthAuthorityCard.js
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation'

// Account fields
import NAME_FIELD from '@salesforce/schema/Account.HealthAuthority__c';
import TYPE_FIELD from '@salesforce/schema/Account.Type';
//import AUTHORITY_FIELD from '@salesforce/schema/Account.Health_Authority__c';

// Static Resources
import vchLogo from '@salesforce/resourceUrl/SubFooter_VancouverCoastalHealth';
import fraserLogo from '@salesforce/resourceUrl/SubFooter_FraserHealth';
import islandLogo from '@salesforce/resourceUrl/SubFooter_IslandHealth';
import InterierLogo from '@salesforce/resourceUrl/SubFooter_InterierHealth';
import northernLogo from '@salesforce/resourceUrl/SubFooter_NorthernHealth';
import vchWebLink from '@salesforce/label/c.SubFooter_WebLink_VCH';
import fraserWebLink from '@salesforce/label/c.SubFooter_WebLink_Fraser';
import interierLink from '@salesforce/label/c.SubFooter_WebLink_Interier';
import islandWebLink from '@salesforce/label/c.SubFooter_WebLink_Island';
import northernWebLink from '@salesforce/label/c.SubFooter_WebLink_Northern';
import fraserContactLink from '@salesforce/label/c.SubFooter_ContactLink_Fraser';
import interierContactLink from '@salesforce/label/c.SubFooter_ContactLink_Interier';
import islandContactLink from '@salesforce/label/c.SubFooter_ContactLink_Island';
import northernContactLink from '@salesforce/label/c.SubFooter_ContactLink_Northern';
import vchContactLink from '@salesforce/label/c.SubFooter_ContactLink_VCH';


//import defaultLogo from '@salesforce/resourceUrl/defaultHealthLogo';
 
const FIELDS = [
    NAME_FIELD,
    TYPE_FIELD
    
];

export default class AccountHealthAuthorityCard extends LightningElement {
    @api recordId;
    account;
    logoUrl;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
            console.log('recID'+ this.recordId);

        if (data) {
            this.account = data;
            console.log('-----test-----'+this.account);
            const authority =
                data.fields.HealthAuthority__c?.value;
            console.log('name-------->'+authority);
            this.setLogo(authority);
        } else if (error) {
            console.error('Error loading Account', error);
        }
    }
     @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            // Checks standard Salesforce page recordId first, then defaults to custom query attributes
            this.recordId = currentPageReference.attributes.recordId 
                || currentPageReference.state.recordId 
                || currentPageReference.state.c__recordId; // Common OmniStudio URL syntax
            
            console.log('Caught Record ID from URL:', this.recordId);
        }
    }

    setLogo(authority) {
        switch (authority) {
            case 'Vancouver Coastal Health - VCH':
                this.logoUrl = vchLogo;
                 this.websiteUrl = vchWebLink;
                this.contactUrl = vchContactLink;
                break;

            case 'Fraser Health - FH':
                this.logoUrl = fraserLogo;
                  this.websiteUrl = fraserWebLink;
                this.contactUrl = fraserContactLink;
                break;

            case 'Island Health - Island':
                this.logoUrl = islandLogo;
                  this.websiteUrl = islandWebLink;
                this.contactUrl = islandContactLink;
                break;

            case 'Interior Health - IH':
                this.logoUrl = InterierLogo;
                  this.websiteUrl = interierWebLink;
                this.contactUrl = interierContactLink;
                break;

             case 'Northern Health - NH':
                this.logoUrl = northernLogo;
                  this.websiteUrl = northernWebLink;
                this.contactUrl = northernContactLink;
               
                break;

            default:
                this.logoUrl = defaultLogo;
        }
    }

}