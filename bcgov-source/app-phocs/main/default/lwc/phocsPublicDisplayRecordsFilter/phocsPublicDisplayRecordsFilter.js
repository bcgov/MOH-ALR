import { LightningElement, api, track } from 'lwc';
import pubsub from 'omnistudio/pubsub'; 
export default class GenericFilter extends LightningElement {

    // Full data from FlexCard
    @api data = [];
    // Config for filters (dynamic)
    @api filterConfig = [   { "label": "Health Authority", "field": "HealthAuthority__c", "value": "All" },   { "label": "City", "field": "PhysicalAddressCity" , "value": "All" } ];
    @track originalData = [];
    // Filtered result
    @track filteredData = [];

    // Store selected values
    @track selectedFilters = {};
    @api selectedValue;
    

    // Initialize
 connectedCallback() {
        console.log('RAW DATA FROM FLEXCARD:', this.data);
        console.log('IS ARRAY:', Array.isArray(this.data));
        console.log('FLEXCARD DATA --->', JSON.stringify(this.data));

        console.log('IS array filterConfig:', Array.isArray(this.data));
        console.log('IS array filterConfig:', this.filterConfig);
        this.originalData = Array.isArray(this.data)? [...this.data]: [];

        this.filteredData = [...this.originalData];
        console.log('filteredData --->',this.filteredData);
        //
        const savedFilters = JSON.parse(sessionStorage.getItem('filters')) || {};

        this.filterConfig = this.filterConfig.map(f => {
        return {
        ...f,
        value: savedFilters[f.field] || 'ALL'
        };
        });
        //
        this.initialize();

}
    // Re-run if data changes
    @api
    refreshData(newData) {
        console.log('refreshData.....');
        this.data = newData;
        this.initialize();
    }

    initialize() {
    console.log('Initializing.......');
    this.data = Array.isArray(this.data) ? this.data : [];
    console.log('data after initializing.....',this.data);
    this.filteredData = [...this.data];
    console.log('filteredData after initializing.....',this.filteredData);
    this.prepareFilterOptions();
}
    // Prepare dropdown options dynamically
    prepareFilterOptions() {
        this.filterConfig = this.filterConfig.map(filter => {

            let values = this.data.map(item => item[filter.field]);
            // Remove null/undefined + duplicates
            let uniqueValues = [...new Set(values.filter(val => val))];

            return {
                ...filter,
                options: uniqueValues.map(val => ({
                    label: val,
                    value: val
                }))
            };
        });
         console.log('IS array filterConfig:', this.filterConfig);

    }

    // Handle dropdown change
    handleChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        console.log('handleChange field-->',field);
        console.log('handleChange values-->',value);
        // Save per field
        let filters = JSON.parse(sessionStorage.getItem('filters')) || {};
        filters[field] = value;
        sessionStorage.setItem('filters', JSON.stringify(filters));
        this.selectedFilters[field] = value;
        this.selectedValue = this.selectedFilters[field];
        console.log('handleChange selectedFilters selectedFilters[field]-->',this.selectedFilters[field]);
                console.log('handleChange selectedValue-->',this.selectedValue);
        //

        // store multiple filters
        this.selectedFilters = {
        ...this.selectedFilters,
        [field]: value
        };

        console.log('All Filters:', JSON.stringify(this.selectedFilters));
        // update UI value so it stays selected
        this.filterConfig = this.filterConfig.map(item => {
        if (item.name === field) {
            return { ...item, value: value };
        }
        return item;
        });
        //
        this.applyFilters();
    }

    // Apply filtering logic
    applyFilters() {
        console.log('inside applyfilters');
   this.filteredData = this.originalData.filter(item => {

    return Object.keys(this.selectedFilters).every(field => {

        const filterValue = this.selectedFilters[field];

        if (!filterValue) return true;

        const itemValue = item[field];

        return itemValue &&
            itemValue.toString().toLowerCase() === filterValue.toLowerCase();
    });
});

    this.sendDataToFlexCard();
}

    // Reset filters
    handleReset() {
        this.selectedFilters = {};
        this.filteredData = [...this.data];

        // Reset UI fields
        const inputs = this.template.querySelectorAll('lightning-combobox');
        inputs.forEach(input => {
            input.value = null;
        });
        sessionStorage.removeItem('filters');

        this.filterConfig = this.filterConfig.map(f => ({
        ...f,
        value: 'ALL'
        }));
        this.sendDataToFlexCardReset();
    }

    // Send filtered data back
    sendDataToFlexCard() {
        console.log('inside sendDataToFlexCard',this.filteredData);
        pubsub.fire('flexCardFilterChannel', 'filterChangeEvent', {
        filterData: this.selectedValue
    });
    }
     sendDataToFlexCardReset() {
        console.log('inside sendDataToFlexCardReset',this.filteredData);
        pubsub.fire('flexCardFilterChannelReset', 'filterChangeEventReset', {
        filterData: this.selectedValue
    });
    }
}