import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from "omnistudio/omniscriptBaseMixin";

export default class BLFlowContainer extends OmniscriptBaseMixin(LightningElement) {

	@api recordId;
	@api errorMessage;
	@api newLicenseId;
	@api showError;
	@api newRegNumber;
	get inputVariables() {
		return [
			{
				name: 'recordId',
				type: 'String',
				value: this.recordId
			}
		];
	}
	handleStatusChange(event){   
		console.log("Inside event: "+ event.detail.status);
		if (event.detail.status === 'FINISHED_SCREEN') {  
			const outputVariables = event.detail.outputVariables;
      		for (let i = 0; i < outputVariables.length; i++) {
        		const outputVar = outputVariables[i];
				if (outputVar.name === "newLicenseId") {
					this.newLicenseId = outputVar.value;
          			//this.navigateToRecord(outputVar.value);
        		}if (outputVar.name === "errorMessage") {
					this.errorMessage = outputVar.value;
        		}if (outputVar.name === "showError") {
					this.showError = outputVar.value;
        		}
				if (outputVar.name === "newRegNumber") {
					this.newRegNumber = outputVar.value;
        		}
      		}
			
		}
		//window.location.reload();
		var data = {
			"output":{
				"showError":this.showError,
				"newLicenseId":this.newLicenseId,
				"errorMessage": this.errorMessage,
				"newRegNumber": this.newRegNumber
			}
		}
			
			this.omniApplyCallResp(data);
			this.omniUpdateDataJson(data);
	}

}