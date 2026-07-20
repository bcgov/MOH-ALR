import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEligibleRegulatoryCodes from '@salesforce/apex/PHOCSBLARegulatoryCodeController.getEligibleRegulatoryCodes';
import saveRegulatoryCodes from '@salesforce/apex/PHOCSBLARegulatoryCodeController.saveRegulatoryCodes';
const PAGE_SIZE = 20;
const ALL_AUTHORITIES = 'ALL';
const COLUMNS = [
    {
        label: 'Legislation ',
        fieldName: 'regulatoryAuthority',
        type: 'text',
        sortable: true,
        wrapText: true,
        initialWidth: 240
    },
    {
        label: 'Section Reference',
        fieldName: 'regulatoryCode',
        type: 'text',
        sortable: true,
        wrapText: true,
        initialWidth: 180
    },
    {
        label: 'Section Title',
        fieldName: 'subject',
        type: 'text',
        sortable: true,
        wrapText: true,
        initialWidth: 300
    },
    {
        label: 'Legislative Requirement',
        fieldName: 'description',
        type: 'text',
        sortable: true,
        wrapText: true
    }
];

export default class PhocsAddRegulatoryCode extends LightningElement {

    @api recordId;

    columns = COLUMNS;
    isModalOpen = false;
    isLoading = false;
    accountType;
    allRecords = [];
    filteredRecords = [];
    authorityOptions = [
        {
            label: 'All',
            value: ALL_AUTHORITIES
        }
    ];

    selectedAuthority = ALL_AUTHORITIES;
    searchTerm = '';
    currentPage = 1;
    pageSize = PAGE_SIZE;
    sortBy = 'regulatoryAuthority';
    sortDirection = 'asc';
    selectedRegulatoryCodeIds = new Set();


    /**
     * Opens the modal and retrieves eligible records.
     */
    async handleOpenModal() {
        this.isModalOpen = true;
        this.resetComponentState();
        await this.loadRegulatoryCodes();
    }


    /**
     * Retrieves Regulatory Codes from Apex.
     */
    async loadRegulatoryCodes() {
        this.isLoading = true;
        try {
            const response = await getEligibleRegulatoryCodes({ businessLicenseApplicationId: this.recordId });
            this.accountType = response.accountType;
            this.allRecords = response.regulatoryCodes ? [...response.regulatoryCodes] : [];

            this.authorityOptions = [
                {
                    label: 'All',
                    value: ALL_AUTHORITIES
                },
                ...(response.regulatoryAuthorities || [])
                    .map(
                        authority => ({
                            label: authority,
                            value: authority
                        })
                    )
            ];

            this.applyFilters();

        } catch (error) {
            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );

            this.isModalOpen = false;

        } finally {
            this.isLoading = false;
        }
    }


    /**
     * Closes the modal.
     */
    handleCloseModal() {
        this.isModalOpen = false;
        this.resetComponentState();
    }


    /**
     * Resets all modal values.
     */
    resetComponentState() {
        this.accountType = null;
        this.allRecords = [];
        this.filteredRecords = [];
        this.authorityOptions = [
            {
                label: 'All',
                value: ALL_AUTHORITIES
            }

        ];

        this.selectedAuthority = ALL_AUTHORITIES;
        this.searchTerm = '';
        this.currentPage = 1;
        this.sortBy = 'regulatoryAuthority';
        this.sortDirection = 'asc';
        this.selectedRegulatoryCodeIds = new Set();
    }


    /**
     * Search Regulatory Code and Description.
     */
    handleSearchChange(event) {
        this.searchTerm =  event.target.value || '';
        this.currentPage = 1;
        this.applyFilters();
    }


    /**
     * Filters records by Regulatory Authority.
     */
    handleAuthorityChange(event) {
        this.selectedAuthority = event.detail.value;

        this.currentPage = 1;

        this.applyFilters();
    }


    /**
     * Applies search, Regulatory Authority filter,
     * and the current sorting.
     */
    applyFilters() {

        const normalizedSearchTerm =
            this.searchTerm
                .trim()
                .toLowerCase();


        let records =
            this.allRecords.filter(
                record => {

                    const regulatoryCode =
                        (
                            record.regulatoryCode ||
                            ''
                        ).toLowerCase();


                    const description =
                        (
                            record.description ||
                            ''
                        ).toLowerCase();


                    const matchesSearch =
                        !normalizedSearchTerm ||

                        regulatoryCode.includes(
                            normalizedSearchTerm
                        ) ||

                        description.includes(
                            normalizedSearchTerm
                        );


                    const matchesAuthority =

                        this.selectedAuthority ===
                            ALL_AUTHORITIES ||

                        record.regulatoryAuthority ===
                            this.selectedAuthority;


                    return (
                        matchesSearch &&
                        matchesAuthority
                    );
                }
            );


        records =
            this.sortRecords(
                records,
                this.sortBy,
                this.sortDirection
            );


        this.filteredRecords =
            records;


        this.ensureValidCurrentPage();
    }


    /**
     * Handles lightning-datatable column sorting.
     */
    handleSort(event) {

        this.sortBy =
            event.detail.fieldName;

        this.sortDirection =
            event.detail.sortDirection;

        this.filteredRecords =
            this.sortRecords(

                [...this.filteredRecords],

                this.sortBy,

                this.sortDirection

            );
    }


    /**
     * Sorts records without changing the original array.
     */
    sortRecords(
        records,
        fieldName,
        direction
    ) {

        const multiplier =
            direction === 'asc'
                ? 1
                : -1;


        return [...records].sort(
            (recordOne, recordTwo) => {

                const firstValue =
                    (
                        recordOne[fieldName] ||
                        ''
                    )
                    .toString()
                    .toLowerCase();


                const secondValue =
                    (
                        recordTwo[fieldName] ||
                        ''
                    )
                    .toString()
                    .toLowerCase();


                return (
                    firstValue.localeCompare(
                        secondValue
                    ) *
                    multiplier
                );
            }
        );
    }


    /**
     * Maintains selections across all pages.
     */
    handleRowSelection(event) {

        const selectedRows =
            event.detail.selectedRows;


        const selectedIdsOnCurrentPage =
            new Set(

                selectedRows.map(
                    row =>
                        row.regulatoryCodeId
                )

            );


        /*
         * Remove the current page Ids from the global selection.
         *
         * This removes records unchecked by the user.
         */
        this.paginatedRecords.forEach(
            record => {

                this.selectedRegulatoryCodeIds
                    .delete(
                        record.regulatoryCodeId
                    );

            }
        );


        /*
         * Add the records currently selected on this page.
         */
        selectedIdsOnCurrentPage.forEach(
            regulatoryCodeId => {

                this.selectedRegulatoryCodeIds
                    .add(
                        regulatoryCodeId
                    );

            }
        );


        /*
         * Create a new Set so LWC reevaluates getters.
         */
        this.selectedRegulatoryCodeIds =
            new Set(
                this.selectedRegulatoryCodeIds
            );
    }


    /**
     * Goes to the previous page.
     */
    handlePrevious() {

        if (this.currentPage > 1) {

            this.currentPage--;

        }
    }


    /**
     * Goes to the next page.
     */
    handleNext() {

        if (
            this.currentPage <
            this.totalPages
        ) {

            this.currentPage++;

        }
    }


    /**
     * Ensures the current page exists after filtering.
     */
    ensureValidCurrentPage() {

        if (
            this.currentPage >
            this.totalPages
        ) {

            this.currentPage =
                this.totalPages;

        }


        if (
            this.currentPage < 1
        ) {

            this.currentPage = 1;

        }
    }


    /**
     * Creates the selected junction records.
     */
    async handleSave() {

        if (
            this.selectedRegulatoryCodeIds
                .size === 0
        ) {

            this.showToast(
                'No Regulatory Codes Selected',
                'Select at least one Regulatory Code.',
                'warning'
            );

            return;
        }


        this.isLoading = true;


        try {

            const response =
                await saveRegulatoryCodes({

                    businessLicenseApplicationId:
                        this.recordId,

                    regulatoryCodeIds:
                        Array.from(
                            this
                                .selectedRegulatoryCodeIds
                        )

                });


            const toastVariant =
                response.failureCount > 0
                    ? 'warning'
                    : 'success';


            let toastMessage =
                response.message;


            if (
                response.errors &&
                response.errors.length > 0
            ) {

                toastMessage +=

                    ' ' +

                    response.errors.join(
                        ' '
                    );

            }


            this.showToast(
                response.failureCount > 0
                    ? 'Save Completed with Errors'
                    : 'Success',

                toastMessage,

                toastVariant
            );


            /*
             * Close only when at least one record was saved
             * or all selected records were duplicates.
             */
            if (
                response.successCount > 0 ||

                response.skippedDuplicateCount > 0
            ) {

                this.isModalOpen = false;

                this.resetComponentState();


                /*
                 * Refresh the Business License Application page
                 * so the related list displays the new records.
                 */
                setTimeout(
                    () => {

                        window.location.reload();

                    },
                    500
                );

            }

        } catch (error) {

            this.showToast(
                'Error',
                this.getErrorMessage(error),
                'error'
            );

        } finally {

            this.isLoading = false;

        }
    }


    /**
     * Returns the records for the current page.
     */
    get paginatedRecords() {

        const startIndex =

            (
                this.currentPage - 1
            ) *

            this.pageSize;


        const endIndex =

            startIndex +

            this.pageSize;


        return this.filteredRecords.slice(

            startIndex,

            endIndex

        );
    }


    /**
     * Returns selections applicable to the current page.
     */
    get selectedRowsOnCurrentPage() {

        return this.paginatedRecords

            .filter(
                record =>

                    this
                        .selectedRegulatoryCodeIds
                        .has(
                            record.regulatoryCodeId
                        )
            )

            .map(
                record =>
                    record.regulatoryCodeId
            );
    }


    get totalPages() {

        return Math.max(

            1,

            Math.ceil(

                this.filteredRecords.length /

                this.pageSize

            )

        );
    }


    get hasRecords() {

        return (
            this.filteredRecords.length > 0
        );
    }


    get disablePrevious() {

        return (
            this.currentPage <= 1
        );
    }


    get disableNext() {

        return (

            this.currentPage >=

            this.totalPages

        );
    }


    get disableSave() {

        return (

            this.isLoading ||

            this.selectedRegulatoryCodeIds
                .size === 0

        );
    }


    get filteredRecordCount() {

        return this.filteredRecords.length;
    }


    get selectedRecordCount() {

        return this
            .selectedRegulatoryCodeIds
            .size;
    }


    /**
     * Displays a Lightning toast.
     */
    showToast(
        title,
        message,
        variant
    ) {

        this.dispatchEvent(

            new ShowToastEvent({

                title,

                message,

                variant

            })

        );
    }


    /**
     * Retrieves an Apex/LDS error message.
     */
    getErrorMessage(error) {

        if (
            error?.body?.message
        ) {

            return error.body.message;

        }


        if (
            Array.isArray(
                error?.body
            )
        ) {

            return error.body

                .map(
                    currentError =>
                        currentError.message
                )

                .join(
                    ', '
                );
        }


        if (
            error?.message
        ) {

            return error.message;

        }


        return (
            'An unexpected error occurred.'
        );
    }
}