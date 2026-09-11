import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import getViolations from '@salesforce/apex/PHOCSCCFLViolationAssessmentController.getViolations';

const SCOPE_OPTIONS = [{ label: 'Isolated', value: 'Isolated' }, { label: 'Pattern', value: 'Pattern' }, { label: 'Widespread', value: 'Widespread' }];
const SEVERITY_OPTIONS = [{ label: 'Potential for the imminent / immediate harm', value: 'Potential for the imminent / immediate harm' },
                          { label: 'Potential for significant harm', value: 'Potential for significant harm' },
                          { label: 'Potential for more than minimal harm', value: 'Potential for more than minimal harm' },
                          { label: 'Potential for minimal harm', value: 'Potential for minimal harm' }];
const MAX_VIOLATIONS_PER_CATEGORY = 3;

function withSelection(options, selectedValue) {
    return options.map(opt => ({ ...opt, selected: opt.value === selectedValue }));
}

export default class PhocsCCFLViolationAssessment extends OmniscriptBaseMixin(LightningElement) {
    _inspectionId;
    categories = [];
    violations = [];
    isLoading = false;
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
        if (value) {
            this.loadViolations();
        }
    }

    get hasViolations() {
        return this.violations.length > 0;
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
        if (!this._inspectionId) {
            return;
        }

        this.isLoading = true;
        this.stateRestored = false;
        this.showValidationError = false;
        this.hasSelectedViolation = false;
        this.isViolationSelectionValid = false;

        try {
            const records = await getViolations({ inspectionId: this._inspectionId });
            const savedViolations = this.getSavedViolations();
            const savedViolationMap = new Map();

            savedViolations.forEach(savedViolation => {
                if (savedViolation && savedViolation.violationId) {
                    savedViolationMap.set(String(savedViolation.violationId), savedViolation);
                }
            });

            const mapped = (records || []).map(record => {
                const recordId = String(record.id);
                const savedViolation = savedViolationMap.get(recordId);
                const selected = savedViolation != null;
                const scope = selected && savedViolation.scope ? savedViolation.scope : null;
                const severity = selected && savedViolation.severity ? savedViolation.severity : null;

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
                    scopeDisabled: !selected,
                    severityDisabled: !selected,
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
            this.hasSelectedViolation = false;
            this.isViolationSelectionValid = false;
            this.showValidationError = false;
            this.notifyOmniScript();
            this.dispatchEvent(new CustomEvent('error', { detail: error?.body?.message || 'Unable to retrieve regulatory code violations.' }));
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
        this.isViolationSelectionValid = this.hasSelectedViolation && !invalid;
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

            return {
                ...v,
                selected,
                scopeDisabled: !selected,
                severityDisabled: !selected,
                scope,
                severity,
                scopeSelectOptions: withSelection(SCOPE_OPTIONS, scope),
                severitySelectOptions: withSelection(SEVERITY_OPTIONS, severity)
            };
        });

        this.violations = this.applyCategoryLimits(updated);
        this.buildCategories();
        this.validateSelections();
    }

    handleValueChange(event) {
        const violationId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

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

        this.isViolationSelectionValid = this.hasSelectedViolation && !invalid;

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
            severity: violation.severity
        }));
    }

    notifyOmniScript() {
        this.omniApplyCallResp({
            hasSelectedViolation: this.hasSelectedViolation,
            isViolationSelectionValid: this.isViolationSelectionValid,
            selectedViolations: this.selectedViolations
        });

        this.omniValidate(this.isViolationSelectionValid);
    }
}