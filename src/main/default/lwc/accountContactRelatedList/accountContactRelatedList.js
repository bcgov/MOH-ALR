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

    relatedContacts = [];
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
            const data = result.data;
            this.relatedContacts  = data.map(item => ({
                Id: item.relation.Id,
                Contact: {
                    Id: item.relation.Contact ? item.relation.Contact.Id : null,
                    Name: item.relation.Contact ? item.relation.Contact.Name : null,
                    Phone: item.relation.Contact ? item.relation.Contact.Phone : null,
                    Email: item.relation.Contact ? item.relation.Contact.Email : null
                },
                relation: {
                    isActive: item.relation.isActive,
                    PrimaryContact__c: item.relation.PrimaryContact__c,
                    Roles: item.relation.Roles
                }
            }));
        } else if (result.error) {
            console.error('Error fetching related contacts:', error);
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
        console.log(this.recordId);
        const contextId = this.recordId;
        const Url = '/lightning/page/omnistudio/omniscript?omniscript__type=EHIS&omniscript__subType=AccountContactRelation&omniscript__language=English&omniscript__theme=lightning&omniscript__tabIcon=custom:custom18&omniscript__tabLabel=Contact&c__ObjectId={!contextId}';
        console.log('Constructed URL:', Url);
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
            relationshipApiName: 'AccountContactRelations', // Specify the relationship name
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
}