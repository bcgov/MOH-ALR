import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getPageContext from '@salesforce/apex/PHOCSOperatorLabRequisitionController.getPageContext';
import getDetailPageContext from '@salesforce/apex/PHOCSOperatorLabRequisitionController.getDetailPageContext';

const NAME_COLUMN = {
    label: 'Lab Test Requisition Name',
    type: 'button',
    typeAttributes: {
        label: { fieldName: 'name' },
        name: 'view',
        variant: 'base'
    }
};

const RESULT_COLUMNS = [
    { label: 'Sample Test Type', fieldName: 'sampleTestType' },
    { label: 'Test', fieldName: 'testName' },
    { label: 'Result Value', fieldName: 'resultValue' },
    { label: 'Unit of Measure', fieldName: 'unitOfMeasure' },
    { label: 'Result Description', fieldName: 'resultDescription' },
    {
        label: 'Collection Date/Time',
        fieldName: 'collectionDateTime',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    }
];

const STANDARD_COLUMNS = [
    NAME_COLUMN,
    { label: 'Sample Type', fieldName: 'sampleType' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Site Descriptor', fieldName: 'siteDescriptor' },
    ...RESULT_COLUMNS
];

const DRINKING_WATER_COLUMNS = [
    { label: 'Location', fieldName: 'location' },
    {
        ...NAME_COLUMN
    },
    { label: 'Sample Type', fieldName: 'sampleType' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Site Treatment', fieldName: 'siteTreatment' },
    { label: 'Site Descriptor', fieldName: 'siteDescriptor' },
    ...RESULT_COLUMNS
];

export default class PhocsOperatorLabRequisitions extends NavigationMixin(LightningElement) {
    @api recordId;
    @api displayMode = 'list';

    columns = STANDARD_COLUMNS;
    activeSections = ['requisition', 'sample', 'site', 'sampler'];
    context;
    rows = [];
    loading = true;
    formLoading = false;
    showForm = false;
    selectedId;
    selectedStatus;
    selectedName;
    selectedEditable = false;
    sampleType;
    drinkingWaterComponentId;
    componentSearchTerm = '';
    componentOptionsOpen = false;
    validationMessage;
    conditionalRenderFrame;

    connectedCallback() {
        this.loadContext();
    }

    @api
    refresh() {
        return this.loadContext();
    }

    async loadContext() {
        this.loading = true;
        try {
            this.context = this.isDetailMode
                ? await getDetailPageContext({ requisitionId: this.recordId })
                : await getPageContext({ facilityId: this.recordId });
            this.columns = this.context.drinkingWaterFacility ? DRINKING_WATER_COLUMNS : STANDARD_COLUMNS;
            this.rows = this.context.requisitions || [];
            if (this.isDetailMode) {
                const requisition = this.rows.find((row) => row.id === this.recordId);
                if (!requisition) {
                    throw new Error('The requisition is not available.');
                }
                this.selectedId = requisition.id;
                this.selectedName = requisition.name;
                this.selectedStatus = requisition.status;
                this.selectedEditable = requisition.editable;
                this.sampleType = requisition.sampleType;
                this.drinkingWaterComponentId = requisition.drinkingWaterComponentId;
                this.componentSearchTerm = requisition.location || '';
            }
        } catch (error) {
            this.showError(error);
        } finally {
            this.loading = false;
        }
    }

    get eligible() {
        return this.context?.eligible;
    }

    get isDetailMode() {
        return this.displayMode === 'detail';
    }

    get showList() {
        return !this.loading && this.eligible && !this.isDetailMode;
    }

    get showDetailPage() {
        return !this.loading && this.isDetailMode && Boolean(this.context) && Boolean(this.selectedId);
    }

    get facilityId() {
        return this.context?.facilityId || this.recordId;
    }

    get facilityName() {
        return this.context?.facilityName || '';
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get isCreate() {
        return !this.selectedId;
    }

    get modalTitle() {
        return this.isCreate ? 'New Requisition' : 'Edit Requisition';
    }

    get isDrinkingWaterSample() {
        return this.sampleType === 'Drinking Water' || this.sampleType === 'Drinking Water Sample';
    }

    get isSewageSample() {
        return this.sampleType === 'Sewage';
    }

    get showDrinkingWaterFacilityFields() {
        return this.context?.drinkingWaterFacility;
    }

    get filteredComponentOptions() {
        const searchTerm = this.componentSearchTerm.trim().toLowerCase();
        const options = this.context?.drinkingWaterComponents || [];
        return searchTerm
            ? options.filter((option) => option.label.toLowerCase().includes(searchTerm))
            : options;
    }

    get showComponentOptions() {
        return this.componentOptionsOpen && this.filteredComponentOptions.length > 0;
    }

    handleNew() {
        this.selectedId = null;
        this.selectedStatus = 'Draft';
        this.selectedEditable = false;
        this.sampleType = null;
        this.drinkingWaterComponentId = null;
        this.componentSearchTerm = '';
        this.validationMessage = null;
        this.formLoading = true;
        this.showForm = true;
    }

    handleRowAction(event) {
        const row = event.detail.row;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'PHOCSRequisitionDetail__c' },
            state: { recordId: row.id }
        });
    }

    handleEditFromDetails() {
        this.formLoading = true;
        this.showForm = true;
    }

    handleBackToFacility() {
        this.navigateToFacility();
    }

    handleFacilityNameClick() {
        this.navigateToFacility();
    }

    navigateToFacility() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: { name: 'FacilityDetail__c' },
            state: { recordId: this.facilityId }
        });
    }

    handleSampleTypeChange(event) {
        this.formLoading = true;
        this.sampleType = event.detail.value;
        this.finishConditionalRendering();
    }

    handleFormLoad() {
        this.formLoading = false;
    }

    finishConditionalRendering() {
        if (this.conditionalRenderFrame) {
            window.cancelAnimationFrame(this.conditionalRenderFrame);
        }
        this.conditionalRenderFrame = window.requestAnimationFrame(() => {
            this.conditionalRenderFrame = window.requestAnimationFrame(() => {
                this.formLoading = false;
                this.conditionalRenderFrame = null;
            });
        });
    }

    handleComponentFocus() {
        this.componentOptionsOpen = true;
    }

    handleComponentSearch(event) {
        this.componentSearchTerm = event.target.value;
        this.drinkingWaterComponentId = null;
        this.componentOptionsOpen = true;
    }

    handleComponentSelect(event) {
        this.drinkingWaterComponentId = event.currentTarget.dataset.value;
        this.componentSearchTerm = event.currentTarget.dataset.label;
        this.componentOptionsOpen = false;
        const input = this.template.querySelector('.component-picker lightning-input');
        input?.setCustomValidity('');
        input?.reportValidity();
    }

    handleComponentBlur() {
        window.setTimeout(() => {
            this.componentOptionsOpen = false;
        }, 200);
    }

    handleSubmit(event) {
        event.preventDefault();
        const fields = { ...event.detail.fields };
        fields.FacilityName__c = this.facilityId;
        fields.RecordTypeId = this.context.waterRequisitionRecordTypeId;
        fields.ToLaboratory__c = 'BCCDC';
        fields.TestCategory__c = 'Bacteriological';
        fields.Drinking_Water_Component_Name__c = this.drinkingWaterComponentId;

        const validationMessage = this.getValidationMessage(fields);
        if (validationMessage) {
            this.validationMessage = validationMessage;
            if (this.context?.drinkingWaterFacility && !this.drinkingWaterComponentId) {
                const input = this.template.querySelector('.component-picker lightning-input');
                input?.setCustomValidity('Select an option from the list.');
                input?.reportValidity();
            }
            this.template.querySelectorAll('lightning-input-field').forEach((field) => field.reportValidity());
            return;
        }

        this.validationMessage = null;
        this.formLoading = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    getValidationMessage(fields) {
        const isBlank = (value) => value === null || value === undefined || String(value).trim() === '';

        if (this.context?.drinkingWaterFacility && isBlank(fields.Drinking_Water_Component_Name__c)) {
            return 'Select a sampling site associated with the facility.';
        }

        const commonRequiredFields = [
            ['Sample Type', fields.SampleType__c],
            ['To Laboratory', fields.ToLaboratory__c],
            ['Sample Test Type', fields.TestCategory__c],
            ['Sampler Name', fields.SamplerName__c],
            ['Site Descriptor', fields.Site_Descriptor__c]
        ];
        const missingCommonFields = commonRequiredFields
            .filter(([, value]) => isBlank(value))
            .map(([label]) => label);
        if (missingCommonFields.length) {
            return `Complete the following required fields: ${missingCommonFields.join(', ')}.`;
        }

        if (fields.SampleType__c === 'Drinking Water' || fields.SampleType__c === 'Drinking Water Sample') {
            const drinkingWaterFields = [
                ['Type', fields.Type__c],
                ['Specimen Source', fields.SpecimenSource__c],
                ['Submitted for DWPA', fields.SubmittedforDWPA__c],
                ['Boil Water Advisory', fields.BoilAdvisory__c],
                ['Site Treatment', fields.Site_Treatment__c]
            ];
            const missingDrinkingWaterFields = drinkingWaterFields
                .filter(([, value]) => isBlank(value))
                .map(([label]) => label);
            if (missingDrinkingWaterFields.length) {
                return `Complete the following Drinking Water fields: ${missingDrinkingWaterFields.join(', ')}.`;
            }
        }

        return null;
    }

    async handleSuccess() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: this.isCreate ? 'The requisition was created.' : 'The requisition was updated.',
            variant: 'success'
        }));
        this.closeModals();
        await this.loadContext();
    }

    handleError(event) {
        this.formLoading = false;
        this.showError(event.detail);
    }

    closeModals() {
        if (this.conditionalRenderFrame) {
            window.cancelAnimationFrame(this.conditionalRenderFrame);
            this.conditionalRenderFrame = null;
        }
        this.formLoading = false;
        this.showForm = false;
        if (!this.isDetailMode) {
            this.selectedId = null;
            this.selectedStatus = null;
            this.sampleType = null;
            this.drinkingWaterComponentId = null;
            this.componentSearchTerm = '';
        } else {
            const requisition = this.rows.find((row) => row.id === this.selectedId);
            this.drinkingWaterComponentId = requisition?.drinkingWaterComponentId;
            this.componentSearchTerm = requisition?.location || '';
        }
        this.componentOptionsOpen = false;
        this.validationMessage = null;
    }

    handleViewRequisitionForm() {
        this.openRequisitionForm('Word');
    }

    async openRequisitionForm(format) {
        const newTab = window.open('', '_blank');
        try {
            const url = await this[NavigationMixin.GenerateUrl]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'PHOCSViewRequisition__c'
                },
                state: {
                    c__TemplateType: 'MicrosoftWord',
                    c__ObjectId: this.selectedId,
                    c__ObjName: 'LabTestRequisition',
                    c__Format: format
                }
            });
            if (!url) {
                throw new Error('The View Requisition portal page is not available. Publish the Experience Cloud site and try again.');
            }
            newTab.location.href = url;
        } catch (error) {
            newTab?.close();
            this.showError(error);
        }
    }

    showError(error) {
        const message = error?.body?.message || error?.message || 'An unexpected error occurred.';
        this.dispatchEvent(new ShowToastEvent({ title: 'Error', message, variant: 'error' }));
    }
}
