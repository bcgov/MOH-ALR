import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import getViolations from '@salesforce/apex/PHOCSCCFLViolationAssessmentController.getReassessmentViolations';

const SCOPE_OPTIONS = [{ label: 'Isolated', value: 'Isolated' }, { label: 'Pattern', value: 'Pattern' }, { label: 'Widespread', value: 'Widespread' }];
const SEVERITY_OPTIONS = [{ label: 'Potential for the imminent / immediate harm', value: 'Potential for the imminent / immediate harm' },
    { label: 'Potential for significant harm', value: 'Potential for significant harm' },
    { label: 'Potential for more than minimal harm', value: 'Potential for more than minimal harm' },
    { label: 'Potential for minimal harm', value: 'Potential for minimal harm' }];
const COMMENTS_MAX_LENGTH = 255;
const MAX_VIOLATIONS_PER_CATEGORY = 3;

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

    maxPerCategory = MAX_VIOLATIONS_PER_CATEGORY;

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

            const mapped = records.map(record => {
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

            this.violations = this.applyCategoryLimits(mapped);
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

    // Recomputes, per category, whether the MAX_VIOLATIONS_PER_CATEGORY limit has been reached,
    // and disables the checkbox for any not-yet-selected violation in a category that has hit
    // the limit. Already-selected violations are never disabled, so the user can still uncheck
    // one to free up a slot.
    applyCategoryLimits(violations) {
        const countByCategory = new Map();
        violations.forEach(v => {
            if (v.selected) {
                countByCategory.set(v.category, (countByCategory.get(v.category) || 0) + 1);
            }
        });

        return violations.map(v => {
            const categoryCount = countByCategory.get(v.category) || 0;
            const limitReached = categoryCount >= MAX_VIOLATIONS_PER_CATEGORY;
            return { ...v, checkboxDisabled: !v.selected && limitReached };
        });
    }

    buildCategories() {
        const grouped = new Map();

        this.violations.forEach(violation => {
            if (!grouped.has(violation.category)) {
                grouped.set(violation.category, []);
            }

            grouped.get(violation.category).push(violation);
        });

        this.categories = Array.from(grouped.entries()).map(([name, categoryViolations]) => {
            const selectedCount = categoryViolations.filter(v => v.selected).length;
            return {
                name,
                violations: categoryViolations,
                isOpen: this.openCategoryNames.has(name),
                iconName: this.openCategoryNames.has(name) ? 'utility:chevrondown' : 'utility:chevronright',
                selectedCount,
                limitReached: selectedCount >= MAX_VIOLATIONS_PER_CATEGORY,
                hasAdditionalViolations: categoryViolations.length > MAX_VIOLATIONS_PER_CATEGORY,
                selectionCountLabel: `${selectedCount} selected`
            };
        });
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
        const violation = this.violations.find(v => v.id === violationId);

        if (selected && violation) {
            const selectedInCategory = this.violations.filter(v => v.category === violation.category && v.selected).length;

            if (selectedInCategory >= MAX_VIOLATIONS_PER_CATEGORY) {
                // Defensive fallback - the checkbox should already be disabled once the limit is
                // reached, but revert the click and warn the user just in case it wasn't.
                event.target.checked = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Selection limit reached',
                        message: `You can select up to ${MAX_VIOLATIONS_PER_CATEGORY} violations in the "${violation.category}" category.`,
                        variant: 'error'
                    })
                );
                return;
            }
        }

        const updated = this.violations.map(v => {
            if (v.id !== violationId) {
                return v;
            }

            const scope = selected ? v.scope : null;
            const severity = selected ? v.severity : null;
            const comments = selected ? v.comments : null;

            return {
                ...v,
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

        this.violations = this.applyCategoryLimits(updated);
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