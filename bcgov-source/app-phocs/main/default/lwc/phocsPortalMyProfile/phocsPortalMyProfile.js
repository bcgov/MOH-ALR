import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import TITLE_FIELD from '@salesforce/schema/User.Title';
import COMPANY_FIELD from '@salesforce/schema/User.CompanyName';
import EMAIL_FIELD from '@salesforce/schema/User.Email';
import MOBILE_FIELD from '@salesforce/schema/User.MobilePhone';
import PHONE_FIELD from '@salesforce/schema/User.Phone';
import STREET from '@salesforce/schema/User.Street';
import CITY from '@salesforce/schema/User.City';
import STATE from '@salesforce/schema/User.State';
import POSTALCODE from '@salesforce/schema/User.PostalCode';
import COUNTRY from '@salesforce/schema/User.Country';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = [
    NAME_FIELD, TITLE_FIELD, COMPANY_FIELD,
    EMAIL_FIELD, MOBILE_FIELD,PHONE_FIELD,STREET,CITY,STATE,POSTALCODE,COUNTRY
];
     
export default class PhocsPortalMyProfile extends LightningElement {
    userId =  USER_ID;
    name;
    title;
    company;
    email;
    phone;
    mobile;
    street;
    city;
    state;
    postalCode;
    country;
    address;

    isViewMode = true;

    @wire(getRecord, { recordId: '$userId', fields: FIELDS })
    wiredRecord({ data, error }) {
          if (data) {
            this.name = data.fields.Name?.value;
            this.title = data.fields.Title?.value;
            this.company = data.fields.CompanyName?.value;
            this.email = data.fields.Email?.value;
            this.phone = data.fields.Phone?.value;
            this.mobile = data.fields.MobilePhone?.value;
            this.street = data.fields.Street?.value;
            this.city = data.fields.City?.value;
            this.state = data.fields.State?.value;
            this.country = data.fields.Country?.value;
            this.postalCode = data.fields.PostalCode?.value;

            this.address = [this.street, this.city, this.state, this.country, this.postalCode].filter(Boolean).join(', ');

        } else if (error) {
            console.error('Error loading user:', error);
        }
    }

   handleEditClick() {
        this.isViewMode = false;
    }

    handleCancel() {
        this.isViewMode = true;
    }

    handleSuccess() {
        this.isViewMode = true;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Your profile has been updated successfully.',
                variant: 'success'
            })
        );
    }

    handleError(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: event.detail.message,
                variant: 'error'
            })
        );
    }

    handleSubmit(event) {
        console.log('Submitting form fields:', event.detail.fields);
    }
}