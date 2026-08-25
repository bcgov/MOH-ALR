import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getGenerationAccounts from '@salesforce/apex/PhocsBlaRenewalManagementController.getGenerationAccounts';
import generateRenewalRecords from '@salesforce/apex/PhocsBlaRenewalManagementController.generateRenewalRecords';

import getSendRenewals from '@salesforce/apex/PhocsBlaRenewalManagementController.getSendRenewals';
import sendSelectedRenewals from '@salesforce/apex/PhocsBlaRenewalManagementController.sendSelectedRenewals';

const PAGE_SIZE = 50;

export default class PHOCSBLARenewalManagement extends LightningElement {

    activeTab = 'generation';
    isLoading = false;

    // ============================================================
    // OPTIONS
    // ============================================================

    accountTypeOptions = [];
    premiseRoleOptions = [];

    // ============================================================
    // GENERATION
    // ============================================================

    @track generationFilters = {
        accountType: '',
        multiplePremise: false
    };

    generationAllData = [];
    generationPageData = [];

    generationCurrentPage = 1;
    generationSortedBy = 'parentAccountName';
    generationSortDirection = 'asc';

    // Contains ALL selected IDs, including records on pages
    // that aren't currently visible.
    generationSelectedIds = new Set();

    generationColumns = [
         {
            label: 'Parent Account',
            fieldName: 'parentAccountUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'parentAccountName'
                },
                target: '_self'
            }
        },
        {
            label: 'Account Name',
            fieldName: 'accountUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'accountName'
                },
                target: '_self'
            }
        },
        {
            label: 'Physical Address (ZIP/Postal Code)',
            fieldName: 'postalCode',
            type: 'text',
            sortable: true
        },
        {
            label: 'Category L1',
            fieldName: 'categoryL1',
            type: 'text',
            sortable: true
        },
        {
            label: 'Category L2',
            fieldName: 'categoryL2',
            type: 'text',
            sortable: true
        },
        {
            label: 'Operating Months',
            fieldName: 'operatingMonths',
            type: 'number',
            sortable: true
        },
        {
            label: 'Multiple Premise Facility?',
            fieldName: 'multiplePremise',
            type: 'boolean',
            sortable: true
        },
        {
            label: 'Premise Role',
            fieldName: 'premiseRole',
            type: 'text',
            sortable: true
        }
    ];

    // ============================================================
    // SEND
    // ============================================================

    @track sendFilters = {
        type: '',
        feeName: '',
        multiplePremise: false,
        premiseRole: ''
    };

    sendAllData = [];
    sendPageData = [];

    sendCurrentPage = 1;
    sendSortedBy = 'parentAccountName';
    sendSortDirection = 'asc';

    sendSelectedIds = new Set();

    sendColumns = [
        {
            label: 'Parent Account',
            fieldName: 'parentAccountUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'parentAccountName'
                },
                target: '_self'
            }
        },
        {
            label: 'Account Name',
            fieldName: 'accountUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'accountName'
                },
                target: '_self'
            }
        },
        {
            label: 'Physical Address (ZIP/Postal Code)',
            fieldName: 'postalCode',
            type: 'text',
            sortable: true
        },
        {
            label: 'BLA Id',
            fieldName: 'blaUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'blaId'
                },
                target: '_self'
            }
        },
        {
            label: 'Fee ID',
            fieldName: 'feeId',
            type: 'text',
            sortable: true
        },
        {
            label: 'Fee Name',
            fieldName: 'feeName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Fee Amount',
            fieldName: 'feeAmount',
            type: 'currency',
            sortable: true
        },
        {
            label: 'Multiple Premise Facility?',
            fieldName: 'multiplePremise',
            type: 'boolean',
            sortable: true
        },
        {
            label: 'Premise Role',
            fieldName: 'premiseRole',
            type: 'text',
            sortable: true
        }
    ];

    connectedCallback() {
        this.loadGeneration();
    }

    // ============================================================
    // GENERATION LOAD
    // ============================================================

    async loadGeneration() {
        this.isLoading = true;

        try {
            const result = await getGenerationAccounts({
                accountType: this.generationFilters.accountType,
                multiplePremise: this.generationFilters.multiplePremise
            });

            this.generationAllData = result.records || [];

            this.accountTypeOptions = [
                { label: 'All', value: '' },
                ...(result.accountTypeOptions || [])
            ];

            this.premiseRoleOptions = [
                { label: 'All', value: '' },
                ...(result.premiseRoleOptions || [])
            ];

            this.generationSelectedIds = new Set(
                this.generationAllData.map(row => row.Id)
            );

            this.generationCurrentPage = 1;

            this.sortGenerationData();
            this.refreshGenerationPage();
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    // ============================================================
    // GENERATION FILTERS
    // ============================================================

    handleGenerationTypeChange(event) {
        this.generationFilters.accountType = event.detail.value;
    }

    handleGenerationMultiplePremiseChange(event) {
        this.generationFilters.multiplePremise = event.target.checked;
    }

    searchGeneration() {
        this.loadGeneration();
    }

    resetGeneration() {
        this.generationFilters = {
            accountType: '',
            multiplePremise: false
        };

        this.loadGeneration();
    }

    // ============================================================
    // GENERATION SORTING
    // ============================================================

    handleGenerationSort(event) {
        this.generationSortedBy = event.detail.fieldName;
        this.generationSortDirection = event.detail.sortDirection;

        this.sortGenerationData();
        this.generationCurrentPage = 1;
        this.refreshGenerationPage();
    }

    sortGenerationData() {
        const field = this.generationSortedBy;
        const direction = this.generationSortDirection === 'asc' ? 1 : -1;

        this.generationAllData = [...this.generationAllData].sort(
            (a, b) => {
                let valueA = a[field];
                let valueB = b[field];

                if (valueA === null || valueA === undefined) {
                    valueA = '';
                }

                if (valueB === null || valueB === undefined) {
                    valueB = '';
                }

                if (typeof valueA === 'string') {
                    return valueA.localeCompare(
                        valueB,
                        undefined,
                        { numeric: true, sensitivity: 'base' }
                    ) * direction;
                }

                if (valueA > valueB) {
                    return direction;
                }

                if (valueA < valueB) {
                    return -direction;
                }

                return 0;
            }
        );
    }

    // ============================================================
    // GENERATION SELECTION
    // ============================================================
/*
    handleGenerationSelection(event) {
        const currentPageIds = new Set(
            this.generationPageData.map(row => row.Id)
        );

        const selectedOnCurrentPage = new Set(
            event.detail.selectedRows.map(row => row.Id)
        );

        // Remove current-page records from global selection first.
        currentPageIds.forEach(id => {
            this.generationSelectedIds.delete(id);
        });

        // Add back the records currently selected on this page.
        selectedOnCurrentPage.forEach(id => {
            this.generationSelectedIds.add(id);
        });
    } */
    handleGenerationSelection(event) {

    // Create a NEW Set from the existing selection.
    // Do not directly mutate this.generationSelectedIds.
    const updatedSelectedIds = new Set(
        this.generationSelectedIds
    );

    // IDs displayed on the current page
    const currentPageIds = new Set(
        this.generationPageData.map(row => row.Id)
    );

    // IDs still selected on the current page
    const selectedOnCurrentPage = new Set(
        event.detail.selectedRows.map(row => row.Id)
    );

    // Remove all current-page records from the global selection.
    currentPageIds.forEach(id => {
        updatedSelectedIds.delete(id);
    });

    // Add back only records that are still selected.
    selectedOnCurrentPage.forEach(id => {
        updatedSelectedIds.add(id);
    });

    // ⭐ IMPORTANT:
    // Assign a NEW Set so LWC detects the change and rerenders.
    this.generationSelectedIds = updatedSelectedIds;
}

    // ============================================================
    // GENERATION PAGINATION
    // ============================================================

    refreshGenerationPage() {
        const start = (this.generationCurrentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;

        this.generationPageData =
            this.generationAllData.slice(start, end);
    }

    generationNext() {
        if (!this.generationNextDisabled) {
            this.generationCurrentPage++;
            this.refreshGenerationPage();
        }
    }

    generationPrevious() {
        if (!this.generationPreviousDisabled) {
            this.generationCurrentPage--;
            this.refreshGenerationPage();
        }
    }

    // ============================================================
    // GENERATE RENEWALS
    // ============================================================

    async generateRenewals() {
        if (!this.generationSelectedIds.size) {
            this.showError({
            body: {
                message: 'Please select at least one account.'
            }
        });
        return;
        }

        this.isLoading = true;

        try {
            const response = await generateRenewalRecords({
                accountIds: Array.from(this.generationSelectedIds)
            });            

            // Reload both tabs so newly created RTF records
            // become available in Send Renewals.
            if (response?.success) {
            this.showSuccess(response.message);
            //this.showSuccess(' 1 Renewals Generated Successfully');
            // Reload from Salesforce database
            await this.loadGeneration();

            if (this.activeTab === 'send') {
                await this.loadSend();
            }
        } else {
            this.showError({
                body: {
                    message: response?.message ||
                        'Renewal generation failed.'
                }
            });
        }
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    // ============================================================
    // SEND LOAD
    // ============================================================

    async loadSend() {
        this.isLoading = true;

        try {
            const result = await getSendRenewals({
                type: this.sendFilters.type,
                feeName: this.sendFilters.feeName,
                multiplePremise: this.sendFilters.multiplePremise,
                premiseRole: this.sendFilters.premiseRole
            });

            this.sendAllData = result.records || [];

            this.accountTypeOptions = [
                { label: 'All', value: '' },
                ...(result.accountTypeOptions || [])
            ];

            this.premiseRoleOptions = [
                { label: 'All', value: '' },
                ...(result.premiseRoleOptions || [])
            ];

            this.sendSelectedIds = new Set(
                this.sendAllData.map(row => row.Id)
            );

            this.sendCurrentPage = 1;

            this.sortSendData();
            this.refreshSendPage();
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    handleSendTab() {
        this.activeTab = 'send';

        if (!this.sendAllData.length) {
            this.loadSend();
        }
    }

    handleGenerationTab() {
        this.activeTab = 'generation';
    }

    // ============================================================
    // SEND FILTERS
    // ============================================================

    handleSendTypeChange(event) {
        this.sendFilters.type = event.detail.value;
    }

    handleSendFeeNameChange(event) {
        this.sendFilters.feeName = event.target.value;
    }

    handleSendMultiplePremiseChange(event) {
        this.sendFilters.multiplePremise = event.target.checked;
    }

    handleSendPremiseRoleChange(event) {
        this.sendFilters.premiseRole = event.detail.value;
    }

    searchSend() {
        this.loadSend();
    }

    resetSend() {
        this.sendFilters = {
            type: '',
            feeName: '',
            multiplePremise: false,
            premiseRole: ''
        };

        this.loadSend();
    }

    // ============================================================
    // SEND SORTING
    // ============================================================

    handleSendSort(event) {
        this.sendSortedBy = event.detail.fieldName;
        this.sendSortDirection = event.detail.sortDirection;

        this.sortSendData();
        this.sendCurrentPage = 1;
        this.refreshSendPage();
    }

    sortSendData() {
        const field = this.sendSortedBy;
        const direction = this.sendSortDirection === 'asc' ? 1 : -1;

        this.sendAllData = [...this.sendAllData].sort((a, b) => {
            let valueA = a[field];
            let valueB = b[field];

            if (valueA === null || valueA === undefined) {
                valueA = '';
            }

            if (valueB === null || valueB === undefined) {
                valueB = '';
            }

            if (typeof valueA === 'string') {
                return valueA.localeCompare(
                    valueB,
                    undefined,
                    { numeric: true, sensitivity: 'base' }
                ) * direction;
            }

            if (valueA > valueB) {
                return direction;
            }

            if (valueA < valueB) {
                return -direction;
            }

            return 0;
        });
    }

    // ============================================================
    // SEND SELECTION
    // ============================================================

    handleSendSelection(event) {
        const currentPageIds = new Set(
            this.sendPageData.map(row => row.Id)
        );

        const selectedOnCurrentPage = new Set(
            event.detail.selectedRows.map(row => row.Id)
        );

        currentPageIds.forEach(id => {
            this.sendSelectedIds.delete(id);
        });

        selectedOnCurrentPage.forEach(id => {
            this.sendSelectedIds.add(id);
        });
    }

    // ============================================================
    // SEND PAGINATION
    // ============================================================

    refreshSendPage() {
        const start = (this.sendCurrentPage - 1) * PAGE_SIZE;
        const end = start + PAGE_SIZE;

        this.sendPageData =
            this.sendAllData.slice(start, end);
    }

    sendNext() {
        if (!this.sendNextDisabled) {
            this.sendCurrentPage++;
            this.refreshSendPage();
        }
    }

    sendPrevious() {
        if (!this.sendPreviousDisabled) {
            this.sendCurrentPage--;
            this.refreshSendPage();
        }
    }

    // ============================================================
    // SEND RENEWALS
    // ============================================================

    async sendRenewals() {
        if (!this.sendSelectedIds.size) {
            this.showError({
            body: {
                message: 'Please select at least one renewal.'
            }
        });
        return;
        }

        this.isLoading = true;

        try {
             const response = await sendSelectedRenewals({
                regulatoryTransactionFeeIds:
                    Array.from(this.sendSelectedIds)
            });           

            if (response?.success) {

                this.showSuccess(response.message);
                 //this.showSuccess('Renewal invoices have been generated successfully and contacts have been notified.');
                // Important:
                // Query Salesforce again after the update.
                await this.loadSend();

            } else {

                this.showError({
                    body: {
                        message: response?.message ||
                            'Unable to send renewals.'
                    }
                });
            }
        } catch (error) {
            this.showError(error);
        } finally {
            this.isLoading = false;
        }
    }

    // ============================================================
    // GENERATION GETTERS
    // ============================================================

    get generationHasRecords() {
        return this.generationAllData.length > 0;
    }

    get generationTotalCount() {
        return this.generationAllData.length;
    }

    get generationSelectedCount() {
        return this.generationSelectedIds.size;
    }

    get showGenerateButton() {
        return this.generationSelectedIds.size > 0;
    }

    get generationTotalPages() {
        return Math.max(
            1,
            Math.ceil(this.generationAllData.length / PAGE_SIZE)
        );
    }

    get generationPreviousDisabled() {
        return this.generationCurrentPage <= 1;
    }

    get generationNextDisabled() {
        return (
            this.generationCurrentPage >=
            this.generationTotalPages
        );
    }

    get generationSelectedRows() {
        return this.generationPageData
            .filter(row => this.generationSelectedIds.has(row.Id))
            .map(row => row.Id);
    }

    // ============================================================
    // SEND GETTERS
    // ============================================================

    get sendHasRecords() {
        return this.sendAllData.length > 0;
    }

    get sendTotalCount() {
        return this.sendAllData.length;
    }

    get sendSelectedCount() {
        return this.sendSelectedIds.size;
    }

    get showSendButton() {
        return this.sendSelectedIds.size > 0;
    }

    get sendTotalPages() {
        return Math.max(
            1,
            Math.ceil(this.sendAllData.length / PAGE_SIZE)
        );
    }

    get sendPreviousDisabled() {
        return this.sendCurrentPage <= 1;
    }

    get sendNextDisabled() {
        return this.sendCurrentPage >= this.sendTotalPages;
    }

    get sendSelectedRows() {
        return this.sendPageData
            .filter(row => this.sendSelectedIds.has(row.Id))
            .map(row => row.Id);
    }

    // ============================================================
    // TOASTS
    // ============================================================

    showSuccess(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message,
                variant: 'success'
            })
        );
    }

    showError(error) {
        let message = 'An unexpected error occurred.';

        if (error?.body?.message) {
            message = error.body.message;
        } else if (error?.message) {
            message = error.message;
        }

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message,
                variant: 'error'
            })
        );
    }
}