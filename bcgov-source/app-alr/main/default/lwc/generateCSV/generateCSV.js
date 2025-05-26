import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import generateCSV from '@salesforce/apex/FetchAndGenerateCSV.generateCSV';

export default class GenerateCSV extends LightningElement {
    @api recordId; // If you're using this component on a record page
    
    generateCSV() {
        generateCSV()
            .then(result => {
                // Handle the CSV content returned from Apex
                this.downloadCSV(result);
            })
            .catch(error => {
                // Handle errors, if any
                console.error('Error generating CSV:', error);
            });
    }

    downloadCSV(csvContent) {

        const currentDate = new Date().toISOString().slice(0, 10); // Get today's date in 'YYYY-MM-DD' format
        const fileName = `Web_Services_Residence_Data_Report_${currentDate}.csv`;

        const csvData = encodeURI('data:text/csv;charset=utf-8,' + csvContent);
        const element = document.createElement('a');
        element.setAttribute('href', csvData);
        element.setAttribute('download', fileName);
        element.style.display = 'none';
        document.body.appendChild(element);

        element.click();

        document.body.removeChild(element);
    }
}