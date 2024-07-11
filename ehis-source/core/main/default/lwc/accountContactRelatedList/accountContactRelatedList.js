/**
* @Name              : AccountContactRelatedList
* @Description       : This LWC component has been created to show the related contact on the account.
* @Author            : Suman Dey (Accenture)
* @StoryNo           : ALR-666
* Modification done as part of EHIS-228 Story by Chaitai Gatkine (Accenture) Dated: 21-June-2024.
**/

import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import ALR_Primary_Contact from '@salesforce/label/c.ALR_Primary_Contact';
import ALR_Roles from '@salesforce/label/c.ALR_Roles';
import ALR_Phone from '@salesforce/label/c.ALR_Phone';
import ALR_Email from '@salesforce/label/c.ALR_Email';
import { NavigationMixin } from 'lightning/navigation';
import getAllRelatedContacts from '@salesforce/apex/AccountContactRelationController.getAllRelatedContacts';

export default class RelatedContactsLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    @api contextId;
    relatedContacts = [];
    accountRecordTypeName = '';
    dropdownVisible = false;

    get label() {
        return {
            PrimaryContact: ALR_Primary_Contact,
            Roles: ALR_Roles,
            Phone: ALR_Phone,
            Email: ALR_Email
        };
    }

    @wire(getAllRelatedContacts, { accountId: '$recordId' })
    wiredRelatedContacts(result) {
        this._wiredResult = result;
        if (result.data) {
            this.relatedContacts = result.data.relations.map(item => ({
                Id: item.Id,
                Contact: {
                    Id: item.Contact ? item.Contact.Id : null,
                    Name: item.Contact ? item.Contact.Name : null,
                    Phone: item.Contact ? item.Contact.Phone : null,
                    Email: item.Contact ? item.Contact.Email : null
                },
                relation: {
                    isActive: item.IsActive,
                    PrimaryContact__c: item.PrimaryContact__c,
                    Roles: item.Roles
                }
            }));
            this.accountRecordTypeName = result.data.accountRecordTypeName;
        } else if (result.error) {
            console.error('Error fetching related contacts:', result.error);
        }
    }

    toggleDropdown(event) {
        const contactId = event.currentTarget.dataset.contactId;
        const index = this.relatedContacts.findIndex(contact => contact.Id === contactId);
        if (index !== -1) {
            this.relatedContacts = this.relatedContacts.map((contact, idx) => {
                if (idx === index) {
                    return { ...contact, dropdownVisible: !contact.dropdownVisible };
                }
                return contact;
            });
        }
    }

    callOmniScript() {
        const Url = `/lightning/page/omnistudio/omniscript?omniscript__type=EHIS&omniscript__subType=AccountContactRelation&omniscript__language=English&omniscript__theme=lightning&omniscript__tabIcon=custom:custom18&omniscript__tabLabel=Contact&c__ContextId=${encodeURIComponent(this.recordId)}`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: Url
            }
        });
    }

    navigateToAccountContactRelation(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: 'AccountContactRelations',
                actionName: 'view'
            }
        });
    }

    navigateToContact(event) {
        const contactId = event.target.dataset.contactId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: contactId,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }

    handleViewRelationship(event) {
        event.stopPropagation();
        const relationId = event.target.dataset.relationId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: relationId,
                objectApiName: 'AccountContactRelation',
                actionName: 'view'
            }
        });
        this.dropdownVisible = false;
    }

    handleEditRelationship(event) {
        event.stopPropagation();
        const relationId = event.target.dataset.relationId;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: relationId,
                objectApiName: 'AccountContactRelation',
                actionName: 'edit'
            }
        });
        this.dropdownVisible = false;
    }

    handleRefresh() {
        refreshApex(this._wiredResult);
    }

    get dropdownClass() {
        return this.dropdownVisible ? 'slds-dropdown slds-dropdown_left slds-dropdown_small slds-dropdown_menu show' : 'slds-dropdown slds-dropdown_left slds-dropdown_small slds-dropdown_menu';
    }

    get isBusinessEntityOrWaterSourceIntake() {
        return this.accountRecordTypeName === 'Business Entity' || this.accountRecordTypeName === 'Water Source Intake' || this.accountRecordTypeName === 'Water System' || this.accountRecordTypeName === 'HA Hierarchy';
    }
}