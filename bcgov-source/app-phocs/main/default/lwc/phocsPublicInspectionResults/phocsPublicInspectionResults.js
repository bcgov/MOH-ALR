import { LightningElement, api } from 'lwc';

export default class PhocsPublicInspectionResults extends LightningElement {
    @api records;

    get rows() {
        return (this.records || []).map(row => {
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
    }

    get hasRows() {
        return this.rows.length > 0;
    }
}