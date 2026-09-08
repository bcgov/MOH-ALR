// refreshPageDataAction.js
import { LightningElement, api } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

export default class RefreshPageDataAction extends LightningElement {
  @api recordId;
 
  @api
  async invoke() {
   
    if (this.recordId) {
      getRecordNotifyChange([{ recordId: this.recordId }]);
    } 

    // Fire standard refresh event for the page / components
    this.dispatchEvent(new RefreshEvent());

    setTimeout(() => { window.location.reload(); }, 100);

  }
}