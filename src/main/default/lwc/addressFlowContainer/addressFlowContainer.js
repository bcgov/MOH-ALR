import { LightningElement, api } from 'lwc';

export default class AddressFlowContainer extends LightningElement {

    @api recordId;
    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

}