import { LightningElement, track } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class PhocsRequestFormNextButton extends OmniscriptBaseMixin(LightningElement) {

    @track errorMessage = '';

    handleNext() {

        let facilities = this.omniJsonData?.FacilityRequestForm?.Facilities;

        if (!facilities) {
            facilities = [];
        } else if (!Array.isArray(facilities)) {
            facilities = [facilities];
        }

        const facilityNumbers = new Set();

        for (let facility of facilities) {

            const facilityNumber = facility.FacilityNumber;

            if (!facilityNumber) {
                continue;
            }

            if (facilityNumbers.has(facilityNumber)) {

                this.errorMessage =
                    `This facility has already been added to the request: ${facilityNumber}`;

                return;
            }

            facilityNumbers.add(facilityNumber);
        }

        this.errorMessage = '';

        // Navigate to next OmniScript step
        this.omniNextStep();
    }
}