import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import getViolations from '@salesforce/apex/PHOCSCCFLViolationAssessmentController.getReassessmentViolations';

const SCOPE_OPTIONS = [{ label: 'Isolated', value: 'Isolated' }, { label: 'Pattern', value: 'Pattern' }, { label: 'Widespread', value: 'Widespread' }];
const SEVERITY_OPTIONS = [{ label: 'Potential for the imminent / immediate harm', value: 'Potential for the imminent / immediate harm' },
    { label: 'Potential for significant harm', value: 'Potential for significant harm' },
    { label: 'Potential for more than minimal harm', value: 'Potential for more than minimal harm' },
    { label: 'Potential for minimal harm', value: 'Potential for minimal harm' }];
const COMMENTS_MAX_LENGTH = 255;

function withSelection(options, selectedValue) {
    return options.map(opt => ({ ...opt, selected: opt.value === selectedValue }));
}

export default class PhocsCCFLViolationReAssessment extends OmniscriptBaseMixin(LightningElement) {
    _inspectionId;
    _facilityId;
    categories = [];
    violations = [];
    isLoading = false;
    hasCompletedAssessment = true;
    completedAssessmentId = null;
    showValidationError = false;
    hasSelectedViolation = false;
    isViolationSelectionValid = false;
    openCategoryNames = new Set();
    stateRestored = false;

    @api
    get inspectionId() {
        return this._inspectionId;
    }

    set inspectionId(value) {
        if (value === this._inspectionId) {
            return;
        }

        this._inspectionId = value;
        this.loadViolationsWhenReady();
    }

    @api
    get facilityId() {
        return this._facilityId;
    }

    set facilityId(value) {
        if (value === this._facilityId) {
            return;
        }

        this._facilityId = value;
        this.loadViolationsWhenReady();
    }

    loadViolationsWhenReady() {
        if (this._inspectionId && this._facilityId) {
            this.loadViolations();
        }
    }

    get hasViolations() {
        return this.hasCompletedAssessment && this.violations.length > 0;
    }

    get showNoCompletedAssessmentMessage() {
        return !this.isLoading && !this.hasCompletedAssessment;
    }

    get showNoViolationsMessage() {
        return !this.isLoading && this.hasCompletedAssessment && this.violations.length === 0;
    }

    get selectedCount() {
        return this.violations.filter(v => v.selected).length;
    }

    get selectedCountLabel() {
        return `${this.selectedCount} selected`;
    }

    get totalCountLabel() {
        return `Total Violation${this.violations.length === 1 ? '' : 's'}: ${this.violations.length}`;
    }

    async loadViolations() {
        if (!this._inspectionId || !this._facilityId) {
            return;
        }

        this.isLoading = true;
        this.stateRestored = false;
        this.showValidationError = false;
        this.hasSelectedViolation = false;
        this.isViolationSelectionValid = false;

        try {
            const response = await getViolations({
                inspectionId: this._inspectionId,
                facilityId: this._facilityId
            });

            this.hasCompletedAssessment = !!(response && response.hasCompletedAssessment);
            this.completedAssessmentId = response && response.completedAssessmentId ? response.completedAssessmentId : null;

            if (!this.hasCompletedAssessment) {
                this.violations = [];
                this.categories = [];
                this.notifyOmniScript();
                return;
            }

            const records = (response && response.violations) || [];
            const savedViolations = this.getSavedViolations();
            const savedViolationMap = new Map();

            savedViolations.forEach(savedViolation => {
                if (savedViolation && savedViolation.violationId) {
                    savedViolationMap.set(String(savedViolation.violationId), savedViolation);
                }
            });

            this.violations = records.map(record => {
                const recordId = String(record.id);
                const savedViolation = savedViolationMap.get(recordId);

                const selected = savedViolation != null ? true : !!record.selected;
                const scope = selected ? (savedViolation?.scope || record.scope || null) : null;
                const severity = selected ? (savedViolation?.severity || record.severity || null) : null;
                const comments = selected ? (savedViolation?.comments || null) : null;

                return {
                    id: record.id,
                    violationName: record.violationName,
                    recordUrl: `/lightning/r/RegulatoryCodeViolation/${record.id}/view`,
                    category: record.category,
                    regulatoryCode: record.regulatoryCode,
                    inspectionQuestion: record.inspectionQuestion,
                    selected,
                    scope,
                    severity,
                    comments,
                    scopeDisabled: !selected,
                    severityDisabled: !selected,
                    commentsDisabled: !selected,
                    scopeSelectOptions: withSelection(SCOPE_OPTIONS, scope),
                    severitySelectOptions: withSelection(SEVERITY_OPTIONS, severity)
                };
            });

            this.openCategoryNames = new Set(this.violations.map(v => v.category));
            this.buildCategories();
            this.restoreValidationState();
            this.stateRestored = true;
        } catch (error) {
            this.violations = [];
            this.categories = [];
            this.hasCompletedAssessment = false;
            this.completedAssessmentId = null;
            this.hasSelectedViolation = false;
            this.isViolationSelectionValid = false;
            this.showValidationError = false;
            this.notifyOmniScript();

            this.dispatchEvent(new CustomEvent('error', {
                detail: error?.body?.message || 'Unable to retrieve regulatory code violations.'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    getSavedViolations() {
        const omniData = this.omniJsonData || {};
        const savedViolations = omniData.selectedViolations;
        return Array.isArray(savedViolations) ? savedViolations : [];
    }

    restoreValidationState() {
        const selected = this.violations.filter(violation => violation.selected);
        this.hasSelectedViolation = selected.length > 0;
        const invalid = selected.some(violation => !violation.scope || !violation.severity);
        this.isViolationSelectionValid = !invalid;
        this.showValidationError = this.hasSelectedViolation && invalid;
        this.notifyOmniScript();
    }

    buildCategories() {
        const grouped = new Map();

        this.violations.forEach(violation => {
            if (!grouped.has(violation.category)) {
                grouped.set(violation.category, []);
            }

            grouped.get(violation.category).push(violation);
        });

        this.categories = Array.from(grouped.entries()).map(([name, violations]) => ({
            name,
            violations,
            isOpen: this.openCategoryNames.has(name),
            iconName: this.openCategoryNames.has(name) ? 'utility:chevrondown' : 'utility:chevronright'
        }));
    }

    handleToggleCategory(event) {
        const name = event.currentTarget.dataset.name;

        if (this.openCategoryNames.has(name)) {
            this.openCategoryNames.delete(name);
        } else {
            this.openCategoryNames.add(name);
        }

        this.buildCategories();
    }

    handleSelectionChange(event) {
        const violationId = event.target.dataset.id;
        const selected = event.target.checked;

        this.violations = this.violations.map(violation => {
            if (violation.id !== violationId) {
                return violation;
            }

            const scope = selected ? violation.scope : null;
            const severity = selected ? violation.severity : null;
            const comments = selected ? violation.comments : null;

            return {
                ...violation,
                selected,
                scopeDisabled: !selected,
                severityDisabled: !selected,
                commentsDisabled: !selected,
                scope,
                severity,
                comments,
                scopeSelectOptions: withSelection(SCOPE_OPTIONS, scope),
                severitySelectOptions: withSelection(SEVERITY_OPTIONS, severity)
            };
        });

        this.buildCategories();
        this.validateSelections();

        if (!selected) {
            setTimeout(() => {
                this.clearViolationValidation(violationId);
            }, 0);
        }
    }

    clearViolationValidation(violationId) {
        const elements = this.template.querySelectorAll(`[data-id="${violationId}"]`);

        elements.forEach(element => {
            if (typeof element.setCustomValidity === 'function') {
                element.setCustomValidity('');
            }

            if (typeof element.reportValidity === 'function') {
                element.reportValidity();
            }
        });
    }

    handleValueChange(event) {
        const violationId = event.target.dataset.id;
        const field = event.target.dataset.field;
        let value = event.target.value;

        if (field === 'comments' && value && value.length > COMMENTS_MAX_LENGTH) {
            value = value.substring(0, COMMENTS_MAX_LENGTH);
        }

        this.violations = this.violations.map(violation => {
            if (violation.id !== violationId) {
                return violation;
            }

            const updated = { ...violation, [field]: value };

            if (field === 'scope') {
                updated.scopeSelectOptions = withSelection(SCOPE_OPTIONS, value);
            } else if (field === 'severity') {
                updated.severitySelectOptions = withSelection(SEVERITY_OPTIONS, value);
            }

            return updated;
        });

        this.buildCategories();
        this.validateSelections();
    }

    validateSelections() {
        const selected = this.violations.filter(violation => violation.selected);

        this.hasSelectedViolation = selected.length > 0;

        const invalid = selected.some(violation => !violation.scope || !violation.severity);

        this.isViolationSelectionValid = !invalid;
        this.showValidationError = this.hasSelectedViolation && invalid;

        this.notifyOmniScript();
    }

    get selectedViolations() {
        return this.violations.filter(violation => violation.selected).map(violation => ({
            violationId: violation.id,
            category: violation.category,
            regulatoryCode: violation.regulatoryCode,
            inspectionQuestion: violation.inspectionQuestion,
            scope: violation.scope,
            severity: violation.severity,
            comments: violation.comments
        }));
    }

    notifyOmniScript() {
        const selectedViolations = this.selectedViolations;
        this.hasSelectedViolation = selectedViolations.length > 0;

        this.omniApplyCallResp({
            hasCompletedAssessment: this.hasCompletedAssessment,
            completedAssessmentId: this.completedAssessmentId,
            hasSelectedViolation: this.hasSelectedViolation,
            isViolationSelectionValid: this.isViolationSelectionValid,
            selectedViolations: selectedViolations
        });

        this.omniValidate(this.isViolationSelectionValid);
    }
}