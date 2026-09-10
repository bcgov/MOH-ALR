import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getGenerationAccounts from '@salesforce/apex/PhocsBlaRenewalManagementController.getGenerationAccounts';
import generateRenewalRecords from '@salesforce/apex/PhocsBlaRenewalManagementController.generateRenewalRecords';

import getSendRenewals from '@salesforce/apex/PhocsBlaRenewalManagementController.getSendRenewals';
import sendSelectedRenewals from '@salesforce/apex/PhocsBlaRenewalManagementController.sendSelectedRenewals';

import getPaymentReminders from '@salesforce/apex/PhocsBlaRenewalManagementController.getPaymentReminders';
import sendPaymentRemindersServer from '@salesforce/apex/PhocsBlaRenewalManagementController.sendPaymentReminders';

import getLateFeeManagementRecords from '@salesforce/apex/PhocsBlaRenewalManagementController.getLateFeeManagementRecords';
import sendLateFeesServer from '@salesforce/apex/PhocsBlaRenewalManagementController.sendLateFees';

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
            fieldName: 'feeUrl',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: {
                    fieldName: 'feeId'
                },
                target: '_self'
            }
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

    // ============================================================
// PAYMENT REMINDERS
// ============================================================

@track paymentFilters = {
    type: '',
    feeName: '',
    feeType: ''
};

paymentPageData = [];
paymentCurrentPage = 1;
paymentTotalCount = 0;

paymentSortedBy = 'accountName';
paymentSortDirection = 'asc';

paymentSelectedIds = new Set();

/*
 * Important:
 *
 * We don't maintain every selected ID in the browser.
 *
 * All records are selected by default, so we maintain only the
 * IDs explicitly deselected by the user.
 *
 * This allows 50,000+ eligible records to remain selectable
 * without putting 50,000 IDs into browser memory.
 */
paymentDeselectedIds = new Set();

feeTypeOptions = [];

showPaymentConfirmation = false;

paymentColumns = [
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
        label: 'BLA ID',
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
        fieldName: 'feeUrl',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'feeId'
            },
            target: '_self'
        }
    },
    {
        label: 'Fee Name',
        fieldName: 'feeName',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'feeNameLabel'
            },
            target: '_self'
        }
    },
    {
        label: 'Fee Amount',
        fieldName: 'feeAmount',
        type: 'currency',
        sortable: true
    },
    {
        label: 'Due Date',
        fieldName: 'dueDate',
        type: 'date',
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }
    },
    {
        label: 'Operating Months',
        fieldName: 'operatingMonths',
        type: 'number',
        sortable: true
    },
    {
        label: 'Multi Premise Facility?',
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
// LATE FEE MANAGEMENT
// ============================================================

@track lateFeeFilters = {
    type: '',
    feeName: '',
    feeType: ''
};
//@track lateFeeSelectedCount = []; // added

lateFeePageData = [];
lateFeeCurrentPage = 1;
lateFeeTotalCount = 0;


lateFeeSortedBy = 'accountName';
lateFeeSortDirection = 'asc';

lateFeeDeselectedIds = new Set();

lateFeeTypeOptions = [];
lateFeeFeeTypeOptions = [];

lateFeeLoaded = false;

showLateFeeConfirmation = false;
lateFeeAmount = null;

lateFeeColumns = [
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
        fieldName: 'accountName',
        type: 'text',
        sortable: true
    },
    {
        label: 'Physical Address (ZIP/Postal Code)',
        fieldName: 'postalCode',
        type: 'text',
        sortable: true
    },
    {
        label: 'BLA ID',
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
        fieldName: 'feeUrl',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'feeId'
            },
            target: '_self'
        }
    },
    {
        label: 'Fee Name',
        fieldName: 'feeName',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'feeNameLabel'
            },
            target: '_self'
        }
    },
    {
        label: 'Fee Amount',
        fieldName: 'feeAmount',
        type: 'currency',
        sortable: true
    },
    {
        label: 'Due Date',
        fieldName: 'dueDate',
        type: 'date',
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }
    },
    {
        label: 'Operating Months',
        fieldName: 'operatingMonths',
        type: 'number',
        sortable: true
    },
    {
        label: 'Multi Premise Facility?',
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

    // IMPORTANT:
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

    //========================================================
    //========================================================
    async loadPaymentReminders() {
    this.isLoading = true;

    try {
        const result = await getPaymentReminders({
            type: this.paymentFilters.type,
            feeName: this.paymentFilters.feeName,
            feeType: this.paymentFilters.feeType,
            pageNumber: this.paymentCurrentPage,
            pageSize: PAGE_SIZE,
            sortBy: this.paymentSortedBy,
            sortDirection: this.paymentSortDirection
        });

        this.paymentPageData = result.records || [];
        this.paymentTotalCount = result.totalCount || 0;

        this.accountTypeOptions = [
            { label: 'All', value: '' },
            ...(result.accountTypeOptions || [])
        ];

        this.feeTypeOptions = [
            { label: 'All', value: '' },
            ...(result.feeTypeOptions || [])
        ];

    } catch (error) {
        this.showError(error);
    } finally {
        this.isLoading = false;
    }
}

handlePaymentRemindersTab() {
    this.activeTab = 'paymentReminders';

    if (!this.paymentPageData.length && !this.paymentLoaded) {
        this.paymentLoaded = true;
        this.paymentCurrentPage = 1;
        this.resetPaymentSelection();
        this.loadPaymentReminders();
    }
}

handlePaymentTypeChange(event) {
    this.paymentFilters.type = event.detail.value;
}

handlePaymentFeeNameChange(event) {
    this.paymentFilters.feeName = event.target.value;
}

handlePaymentFeeTypeChange(event) {
    this.paymentFilters.feeType = event.detail.value;
}

searchPaymentReminders() {
    /*
     * A new search represents a new result set.
     * Therefore all matching records start selected.
     */
    this.paymentCurrentPage = 1;
    this.resetPaymentSelection();
    this.loadPaymentReminders();
}

resetPaymentReminders() {
    this.paymentFilters = {
        type: '',
        feeName: '',
        feeType: ''
    };

    this.paymentCurrentPage = 1;
    this.resetPaymentSelection();
    this.loadPaymentReminders();
}

handlePaymentSort(event) {
    this.paymentSortedBy = event.detail.fieldName;
    this.paymentSortDirection = event.detail.sortDirection;
    this.paymentCurrentPage = 1;

    /*
     * Sorting does not change the result set, so selection remains
     * unchanged.
     */
    this.loadPaymentReminders();
}

handlePaymentSelection(event) {

    const updatedDeselectedIds =
        new Set(this.paymentDeselectedIds);

    const selectedOnCurrentPage = new Set(
        event.detail.selectedRows.map(row => row.Id)
    );

    // Only update records belonging to the current page.
    this.paymentPageData.forEach(row => {

        if (selectedOnCurrentPage.has(row.Id)) {

            // User selected this record.
            updatedDeselectedIds.delete(row.Id);

        } else {

            // User deselected this record.
            updatedDeselectedIds.add(row.Id);
        }
    });

    // IMPORTANT: assign a new Set so LWC rerenders.
    this.paymentDeselectedIds = updatedDeselectedIds;
}

resetPaymentSelection() {
    this.paymentDeselectedIds = new Set();
}

paymentNext() {
    if (!this.paymentNextDisabled) {
        this.paymentCurrentPage++;
        this.loadPaymentReminders();
    }
}

paymentPrevious() {
    if (!this.paymentPreviousDisabled) {
        this.paymentCurrentPage--;
        this.loadPaymentReminders();
    }
}

resetPaymentSelection() {
    this.paymentDeselectedIds = new Set();
}

openPaymentReminderConfirmation() {
    if (this.paymentSelectedCount > 0) {
        this.showPaymentConfirmation = true;
    }
}

closePaymentReminderConfirmation() {
    this.showPaymentConfirmation = false;
}

async sendPaymentReminders() {

    if (this.paymentSelectedCount === 0) {
        this.showError({
            body: {
                message: 'Please select at least one record.'
            }
        });
        return;
    }

    this.isLoading = true;

    try {

        const response = await sendPaymentRemindersServer({
            type: this.paymentFilters.type,
            feeName: this.paymentFilters.feeName,
            feeType: this.paymentFilters.feeType,
            deselectedFeeIds:
                Array.from(this.paymentDeselectedIds)
        });

        if (response?.success) {

            this.showPaymentConfirmation = false;

            this.showSuccess(
                'Emails will be sent to contact(s) on selected facilities'
            );

            /*
             * Reload after the operation so the table reflects the
             * current Salesforce state.
             */
            this.resetPaymentSelection();
            this.paymentCurrentPage = 1;

            await this.loadPaymentReminders();

        } else {

            this.showError({
                body: {
                    message:
                        response?.message ||
                        'Unable to send payment reminders.'
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
// PAYMENT REMINDER GETTERS
// ============================================================

get paymentLoaded() {
    return this._paymentLoaded === true;
}

set paymentLoaded(value) {
    this._paymentLoaded = value;
}

get paymentHasRecords() {
    return this.paymentTotalCount > 0;
}

get paymentTotalPages() {
    return Math.max(
        1,
        Math.ceil(this.paymentTotalCount / PAGE_SIZE)
    );
}

get paymentPreviousDisabled() {
    return this.paymentCurrentPage <= 1;
}

get paymentNextDisabled() {
    return (
        this.paymentCurrentPage >=
        this.paymentTotalPages
    );
}

// ============================================================
// PAYMENT REMINDER GETTERS
// ============================================================

get paymentSelectedCount() {
    return Math.max(
        0,
        this.paymentTotalCount -
        this.paymentDeselectedIds.size
    );
}

get showPaymentReminderButton() {
    return this.paymentSelectedCount > 0;
}

get paymentSelectedRows() {
    return this.paymentPageData
        .filter(row =>
            !this.paymentDeselectedIds.has(row.Id)
        )
        .map(row => row.Id);
}
// Late fee management
async loadLateFeeManagement() {
    this.isLoading = true;    
    try {
        const result = await getLateFeeManagementRecords({
            type: this.lateFeeFilters.type,
            feeName: this.lateFeeFilters.feeName,
            feeType: this.lateFeeFilters.feeType,
            pageNumber: this.lateFeeCurrentPage,
            pageSize: PAGE_SIZE,
            sortBy: this.lateFeeSortedBy,
            sortDirection: this.lateFeeSortDirection
        });

        this.lateFeePageData = result.records || [];
        this.lateFeeTotalCount = result.totalCount || 0;

        this.lateFeeTypeOptions = [
            { label: 'All', value: '' },
            ...(result.typeOptions || [])
        ];

        this.lateFeeFeeTypeOptions = [
            { label: 'All', value: '' },
            ...(result.feeTypeOptions || [])
        ];

    } catch (error) {
        //alert(JSON.stringify(error));
        this.showError(error);
    } finally {
        this.isLoading = false;
    }
}
handleLateFeeManagementTab() {
    this.activeTab = 'lateFees';

    if (!this.lateFeeLoaded) {
        this.lateFeeLoaded = true;
        this.lateFeeCurrentPage = 1;
        this.resetLateFeeSelection();

        this.loadLateFeeManagement();
    }
}
handleLateFeeTypeChange(event) {
    this.lateFeeFilters.type = event.detail.value;
}

handleLateFeeFeeNameChange(event) {
    this.lateFeeFilters.feeName = event.target.value;
}

handleLateFeeFeeTypeChange(event) {
    this.lateFeeFilters.feeType = event.detail.value;
}

searchLateFees() {
    this.lateFeeCurrentPage = 1;

    // A search creates a new result set.
    this.resetLateFeeSelection();

    this.loadLateFeeManagement();
}

resetLateFees() {
    this.lateFeeFilters = {
        type: '',
        feeName: '',
        feeType: ''
    };

    this.lateFeeCurrentPage = 1;
    this.resetLateFeeSelection();

    this.loadLateFeeManagement();
}
handleLateFeeSort(event) {
    this.lateFeeSortedBy = event.detail.fieldName;
    this.lateFeeSortDirection = event.detail.sortDirection;

    this.lateFeeCurrentPage = 1;

    // Sorting doesn't change which records are eligible.
    // Therefore selection remains unchanged.
    this.loadLateFeeManagement();
}
handleLateFeeSelection(event) {
    //const selectedRows = event.detail.selectedRows; // added
    const updatedDeselectedIds =
        new Set(this.lateFeeDeselectedIds);

    const selectedOnCurrentPage = new Set(
        event.detail.selectedRows.map(row => row.Id)
    );

    this.lateFeePageData.forEach(row => {
        if (selectedOnCurrentPage.has(row.Id)) {
            updatedDeselectedIds.delete(row.Id);
        } else {
            updatedDeselectedIds.add(row.Id);
        }
    });

    // Always assign a new Set.
    this.lateFeeDeselectedIds = updatedDeselectedIds;
}
lateFeeNext() {
    if (!this.lateFeeNextDisabled) {
        this.lateFeeCurrentPage++;
        this.loadLateFeeManagement();
    }
}

lateFeePrevious() {
    if (!this.lateFeePreviousDisabled) {
        this.lateFeeCurrentPage--;
        this.loadLateFeeManagement();
    }
}

resetLateFeeSelection() {
    this.lateFeeDeselectedIds = new Set();
}
get lateFeeHasRecords() {
    return this.lateFeeTotalCount > 0;
}

get lateFeeTotalPages() {
    return Math.max(
        1,
        Math.ceil(this.lateFeeTotalCount / PAGE_SIZE)
    );
}

get lateFeePreviousDisabled() {
    return this.lateFeeCurrentPage <= 1;
}

get lateFeeNextDisabled() {
    return (
        this.lateFeeCurrentPage >=
        this.lateFeeTotalPages
    );
}

get lateFeeSelectedCount() {
    
    return Math.max(
        0,
        this.lateFeeTotalCount -
        this.lateFeeDeselectedIds.size
    );
}

get showSendLateFeeButton() {
    return this.lateFeeSelectedCount > 0;
}

get lateFeeSelectedRows() {
    return this.lateFeePageData
        .filter(
            row => !this.lateFeeDeselectedIds.has(row.Id)
        )
        .map(row => row.Id);
}
handleLateFeeAmountChange(event) {
    const value = event.target.value;

    this.lateFeeAmount =
        value === '' ? null : Number(value);
}
isLateFeeAmountValid() {
    return (
        this.lateFeeAmount !== null &&
        Number.isFinite(this.lateFeeAmount) &&
        this.lateFeeAmount > 0
    );
}
isLateFeeModalOpen = false;
// Logic triggered when clicking 'Send Late Fees'
handleSendLateFees() {
    // Open the popup modal
    this.openLateFeeConfirmation();
}
openLateFeeConfirmation() {
    if (this.lateFeeSelectedCount === 0) {
        this.showError({
            body: {
                message: 'Please select at least one record.'
            }
        });
        return;
    }

    this.lateFeeAmount = null;
    this.showLateFeeConfirmation = true;
}
closeLateFeeConfirmation() {
    this.showLateFeeConfirmation = false;
    this.lateFeeAmount = null;
}
async sendLateFees() {

    if (this.lateFeeSelectedCount === 0) {
        this.showError({
            body: {
                message: 'Please select at least one record.'
            }
        });
        return;
    }

    if (!this.isLateFeeAmountValid()) {
        this.showError({
            body: {
                message:
                    'Late Fee Amount must be greater than 0.00$'
            }
        });
        return;
    }

    this.isLoading = true;

    try {
        const response = await sendLateFeesServer({
            type: this.lateFeeFilters.type,
            feeName: this.lateFeeFilters.feeName,
            feeType: this.lateFeeFilters.feeType,
            deselectedFeeIds:
                Array.from(this.lateFeeDeselectedIds),
            lateFeeAmount: this.lateFeeAmount
        });

        if (response?.success) {

            this.showLateFeeConfirmation = false;

            this.showSuccess(
                'Late fees have been generated and emails will be sent to contact(s) on the selected facilities'
            );

            this.lateFeeAmount = null;
            this.resetLateFeeSelection();
            this.lateFeeCurrentPage = 1;

            await this.loadLateFeeManagement();

        } else {
            this.showError({
                body: {
                    message:
                        response?.message ||
                        'Unable to generate late fees.'
                }
            });
        }

    } catch (error) {
        this.showError(error);
    } finally {
        this.isLoading = false;
    }
}



}