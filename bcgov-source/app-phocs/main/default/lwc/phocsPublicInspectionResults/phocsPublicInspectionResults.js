import { LightningElement, api } from 'lwc';

export default class PhocsPublicInspectionResults extends LightningElement {
    @api records;

    sortField = 'question';
    sortDirection = 'asc';

    get rows() {
        const mappedRows = (this.records || []).map(row => {
            const lines = (row.QuestionandComments || '')
                .split('\n')
                .map(line => line.trim())
                .filter(line => line);

            return {
                ...row,
                question: lines.length ? lines[0] : '',
                comments: lines.length > 1 ? lines.slice(1) : []
            };
        });

        if (!this.sortField) {
            return mappedRows;
        }

        const sortMultiplier = this.sortDirection === 'asc' ? 1 : -1;

        return [...mappedRows].sort((left, right) => {
            return this.compareValues(left[this.sortField], right[this.sortField]) * sortMultiplier;
        });
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get questionAriaSort() {
        return this.getAriaSort('question');
    }

    get statusAriaSort() {
        return this.getAriaSort('Status');
    }

    get questionSortIcon() {
        return this.getSortIcon('question');
    }

    get statusSortIcon() {
        return this.getSortIcon('Status');
    }

    get questionSortAlternativeText() {
        return this.getSortAlternativeText('question', 'Inspection Questions and Comments');
    }

    get statusSortAlternativeText() {
        return this.getSortAlternativeText('Status', 'Compliance Status');
    }

    handleSort(event) {
        const field = event.currentTarget.dataset.field;

        if (this.sortField === field) {
            this.sortDirection = this.sortDirection === 'asc' ? 'desc' : 'asc';
            return;
        }

        this.sortField = field;
        this.sortDirection = 'asc';
    }

    compareValues(left, right) {
        const leftValue = this.normalizeValue(left);
        const rightValue = this.normalizeValue(right);

        if (leftValue > rightValue) {
            return 1;
        }

        if (leftValue < rightValue) {
            return -1;
        }

        return 0;
    }

    normalizeValue(value) {
        return (value || '').toString().trim().toLocaleLowerCase();
    }

    getAriaSort(field) {
        if (this.sortField !== field) {
            return 'none';
        }

        return this.sortDirection === 'asc' ? 'ascending' : 'descending';
    }

    getSortIcon(field) {
        if (this.sortField !== field) {
            return 'utility:arrowup';
        }

        return this.sortDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown';
    }

    getSortAlternativeText(field, label) {
        if (this.sortField !== field) {
            return `${label}: not sorted`;
        }

        return `${label}: sorted ${this.sortDirection === 'asc' ? 'ascending' : 'descending'}`;
    }
}
