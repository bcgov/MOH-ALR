import { LightningElement, api } from 'lwc';
import getInspectionQuestions from '@salesforce/apex/InspectionQuestionsControllerV2.getInspectionQuestions';
import getRegulatoryCodesByIndicator from '@salesforce/apex/InspectionQuestionsControllerV2.getRegulatoryCodesByIndicator';
import saveAssessmentResponses from '@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses';
import linkFilesToAssessmentRecords from '@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.linkFilesToAssessmentRecords';
import createViolationsForInspection from '@salesforce/apex/InspectionViolationService.createViolationsForInspection';
import completeInspection from '@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.completeInspection';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInspection from '@salesforce/apex/PHOCSInspectionsHelper.getInspection';

const RESULT_COMPLIANT = 'Compliant';
const RESULT_NON_COMPLIANT = 'PHOCSNonCompliant';
const RESULT_NA = 'N/A (Not Applicable)';
const RESULT_NS = 'N/S (Not Assessed)';

const STATUS_CONFIG = {
    [RESULT_COMPLIANT]: { label: 'Compliant', icon: 'utility:success', iconClass: 'slds-icon-text-success', itemClass: 'review-item review-item--compliant', statusClass: 'review-status-compliant' },
    [RESULT_NON_COMPLIANT]: { label: 'Non-Compliant', icon: 'utility:error', iconClass: 'slds-icon-text-error', itemClass: 'review-item review-item--noncompliant', statusClass: 'review-status-noncompliant' },
    [RESULT_NA]: { label: RESULT_NA, icon: 'utility:dash', iconClass: 'slds-icon-text-default', itemClass: 'review-item review-item--neutral', statusClass: 'review-status-neutral' },
    [RESULT_NS]: { label: RESULT_NS, icon: 'utility:dash', iconClass: 'slds-icon-text-default', itemClass: 'review-item review-item--neutral', statusClass: 'review-status-neutral' },
    default: { label: 'Not Answered', icon: 'utility:warning', iconClass: 'slds-icon-text-warning', itemClass: 'review-item review-item--unanswered', statusClass: 'review-status-unanswered' }
};

export default class InspectionQuestionsParentv3 extends LightningElement {
    @api recordId;
    
    inspection = {};
    groupedQuestions = [];
    showQuestions = false;
    isLoading = false;
    showRegulatoryModal = false;
    regulatoryCodes = [];
    showReviewModal = false;
    reviewData = [];
    
    totalQuestions = 0;
    answeredQuestions = 0;
    compliantCount = 0;
    nonCompliantCount = 0;

    showEndInspectionModal = false;
    closingComments = '';
    closingCommentsMessage = '';
    closingCommentsMessageClass = '';

    regulatoryCodesCache = {};
    uploadedFilesMap = {};
    
    get isCompleted() {
        return this.inspection?.Status === 'Completed';
    }


    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg', '.doc', '.docx', '.xls', '.xlsx'];
    }

    get progressText() {
        return `${this.answeredQuestions} of ${this.totalQuestions} questions answered`;
    }

    get progressBarStyle() {
        const pct = this.totalQuestions > 0 ? Math.round((this.answeredQuestions / this.totalQuestions) * 100) : 0;
        return `width: ${pct}%`;
    }

    get hasRegulatoryCodes() {
        return this.regulatoryCodes?.length > 0;
    }

    get isSubmitDisabled() {
        return this.answeredQuestions === 0;
    }

    get unansweredCount() {
        return this.totalQuestions - this.answeredQuestions;
    }

    priorityOptions = [
        { label: 'Critical', value: 'Critical' },
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    connectedCallback() {
            this.getInspection();
            this.loadInspectionQuestions();
        }       
    

    

    // ========================================
    // HELPER METHODS
    // ========================================

    getButtonClass(buttonValue, selectedValue) {
        if (selectedValue !== buttonValue) return 'compliance-btn';
        const classMap = {
            [RESULT_COMPLIANT]: 'compliance-btn compliance-btn--selected-compliant',
            [RESULT_NON_COMPLIANT]: 'compliance-btn compliance-btn--selected-noncompliant',
            [RESULT_NA]: 'compliance-btn compliance-btn--selected-na',
            [RESULT_NS]: 'compliance-btn compliance-btn--selected-ns'
        };
        return classMap[buttonValue] || 'compliance-btn';
    }

    calculateSectionProgress(parentQuestions) {
        const total = parentQuestions.length;
        const answered = parentQuestions.filter(q => q.result).length;
        return { progressText: `(${answered}/${total})`, isComplete: answered === total, pendingCount: total - answered };
    }

   updateParentQuestion(parent, updates) {
    const result = updates.result ?? parent.result;

    return {
        ...parent,

         selectPriority:
            updates.selectPriority !== undefined
                ? updates.selectPriority
                : parent.selectPriority,

        preferredDateTime:
            updates.preferredDateTime !== undefined
                ? updates.preferredDateTime
                : parent.preferredDateTime,

        actionDescription:
            updates.actionDescription !== undefined
                ? updates.actionDescription
                : parent.actionDescription,

        correctedDuringInspection:
            updates.correctedDuringInspection !== undefined
                ? updates.correctedDuringInspection
                : parent.correctedDuringInspection,

        ...updates,
        
        
        compliantButtonClass: this.getButtonClass(RESULT_COMPLIANT, result),
        nonCompliantButtonClass: this.getButtonClass(RESULT_NON_COMPLIANT, result),
        naButtonClass: this.getButtonClass(RESULT_NA, result),
        nsButtonClass: this.getButtonClass(RESULT_NS, result),
        showChildren: result === RESULT_NON_COMPLIANT

        
        
    };
}


    updateGroupedQuestions(updateFn) {
        this.groupedQuestions = this.groupedQuestions.map(group => {
            const parentQuestions = group.parentQuestions.map(parent => updateFn(group, parent));
            const progress = this.calculateSectionProgress(parentQuestions);
            return { ...group, parentQuestions, ...progress };
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // ========================================
    // DATA LOADING
    // ========================================

    async getInspection(){
        try {
            this.inspection = await getInspection({ visitId: this.recordId });
        }catch(error){
            console.error('Error fetching inspection:', error);
        }
    }

    async loadInspectionQuestions() {
    this.isLoading = true;

    try {
        const result = await getInspectionQuestions({ visitId: this.recordId });

        let questionCount = 0;
        let answeredCount = 0;
        let compliant = 0;
        let nonCompliant = 0;

        this.groupedQuestions = result.map(group => {
            const parentQs = group.parentQuestions.map(parent => {
                questionCount++;

                //const currentResult = parent.Result || '';
                const currentResult = parent.Result ?? parent.result ?? '';
                const savedComment = parent.PHOCSInspectionComments || '';


                if (currentResult) {
                    answeredCount++;
                    if (currentResult === RESULT_COMPLIANT) compliant++;
                    else if (currentResult === RESULT_NON_COMPLIANT) nonCompliant++;
                }

                            

                return this.updateParentQuestion(parent, {
                    result: currentResult,
                    originalResult: parent.originalResult ?? currentResult,
                    comment: savedComment,
                    originalComment: parent.originalComment ?? savedComment,
                                        originalSelectPriority:
                            parent.originalSelectPriority !== undefined
                                ? parent.originalSelectPriority
                                : parent.selectPriority ?? null,

                        originalPreferredDateTime:
                            parent.originalPreferredDateTime !== undefined
                                ? parent.originalPreferredDateTime
                                : parent.preferredDateTime
                                    ? parent.preferredDateTime.slice(0, 16)
                                    : null,

                        originalActionDescription:
                            parent.originalActionDescription !== undefined
                                ? parent.originalActionDescription
                                : parent.actionDescription ?? '',

                        originalCorrectedDuringInspection:
                            parent.originalCorrectedDuringInspection !== undefined
                                ? parent.originalCorrectedDuringInspection
                                : parent.correctedDuringInspection ?? false,

                        // current editable values
                        selectPriority: parent.selectPriority ?? null,
                        preferredDateTime: parent.preferredDateTime
                            ? parent.preferredDateTime.slice(0, 16)
                            : null,
                        actionDescription: parent.actionDescription ?? '',
                        correctedDuringInspection: parent.correctedDuringInspection ?? false,
                    regcodvioId: parent.inspectionAssessmentIndId ?? null,
                    questionCardClass: parent.showCriticalIcon
                        ? 'question-card question-card--critical'
                        : 'question-card',
                    uploadedContentDocIds: [],
                    childQuestions: parent.childQuestions.map(child => ({
                        ...child,
                        responseValue: child.Result || '',
                        originalResponse: child.Result || '',
                        checkboxValue: child.PHOCSCheckboxResponse || false,
                        originalCheckboxValue: child.PHOCSCheckboxResponse || false
                    }))
                                
                });
            });

            const progress = this.calculateSectionProgress(parentQs);
            return {
                ...group,
                isExpanded: false,
                iconName: 'utility:chevronright',
                isSaving: false,
                hasSaved: false,
                parentQuestions: parentQs,
                ...progress
            };
        });

        this.totalQuestions = questionCount;
        this.answeredQuestions = answeredCount;
        this.compliantCount = compliant;
        this.nonCompliantCount = nonCompliant;


    } catch (err) {
        console.error('Error loading inspection questions', err);
        this.showToast(
            'Error',
            'Error loading inspection questions: ' +
                (err?.body?.message || err?.message),
            'error'
        );
    } finally {
        this.isLoading = false;
    }
}


    // ========================================
    // EVENT HANDLERS
    // ========================================

    handleStart() {
        this.showQuestions = true;
    }

    handleToggleSection(event) {
        const sectionId = event.currentTarget.dataset.id;
        this.groupedQuestions = this.groupedQuestions.map(group => {
            if (group.taskDefinitionId !== sectionId) return group;
            const expanded = !group.isExpanded;
            return { ...group, isExpanded: expanded, iconName: expanded ? 'utility:chevrondown' : 'utility:chevronright' };
        });
    }

    handleSectionKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleToggleSection(event);
        }
    }

    handleAssessmentChange(event) {
        const definitionId = event.target.dataset.definitionid;
        const value = event.target.dataset.value;
        let prevResult = '';

        this.updateGroupedQuestions((group, parent) => {
            if (parent.assessmentIndicatorDefinitionId !== definitionId) return parent;
            prevResult = parent.result;
            //return this.updateParentQuestion(parent, { result: value, resultChanged: true });
            return this.updateParentQuestion(parent, { result: value });
        });

        // Update counts
        if (!prevResult && value) {
            this.answeredQuestions++;
        } else if (prevResult && !value) {
            this.answeredQuestions--;
        }
        
        // Update compliant/nonCompliant counts
        if (prevResult === RESULT_COMPLIANT) this.compliantCount--;
        if (prevResult === RESULT_NON_COMPLIANT) this.nonCompliantCount--;
        if (value === RESULT_COMPLIANT) this.compliantCount++;
        if (value === RESULT_NON_COMPLIANT) this.nonCompliantCount++;
    }
            // ========================================
            // PRIORITY AND DUE DATE EVENT 
            // ========================================

        


            handleDatetimeChange(event) {
            const defId = event.target.dataset.definitionid;
            const taskId = event.target.dataset.taskid;
            const value = event.target.value;

            this.updateGroupedQuestions((group, parent) => {
                if (
                    parent.assessmentIndicatorDefinitionId !== defId ||
                    parent.assessmentTaskId !== taskId
                ) {
                    return parent;
                }

                return {
                    ...parent,
                    preferredDateTime: value
                };
            });
        }


        handlePriorityChange(event) {
            const defId = event.target.dataset.definitionid;
            const taskId = event.target.dataset.taskid;
            const value = event.target.value;

            this.updateGroupedQuestions((group, parent) => {
                if (
                    parent.assessmentIndicatorDefinitionId !== defId ||
                    parent.assessmentTaskId !== taskId
                ) {
                    return parent;
                }

                return {
                    ...parent,
                    selectPriority: value
                };
            });
        }


          // ========================================
          // Corrective Action Description EVENT 
          // ========================================

    handleCorrectiveActionDescriptionChange(event) {
    const defId = event.target.dataset.definitionid;
    const taskId = event.target.dataset.taskid;
    const value = event.target.value;

    this.updateGroupedQuestions((group, parent) => {
        if (
            parent.assessmentIndicatorDefinitionId !== defId ||
            parent.assessmentTaskId !== taskId
        ) {
            return parent;
        }

        return {
            ...parent,
            actionDescription: value
        };
    });
}


        
          // ========================================
          // Corrected During Inspection EVENT 
          // ========================================

            handleCorrectedDuringInspectionChange(event) {
            const defId = event.target.dataset.definitionid;
            const taskId = event.target.dataset.taskid;
            const value = event.target.checked;

            this.updateGroupedQuestions((group, parent) => {
                if (
                    parent.assessmentIndicatorDefinitionId !== defId ||
                    parent.assessmentTaskId !== taskId
                ) {
                    return parent;
                }

                return {
                    ...parent,
                    correctedDuringInspection: value
                };
            });
        }



    handleCommentChange(event) {
        const definitionId = event.target.dataset.definitionid;
        const newComment = event.target.value;

        this.updateGroupedQuestions((group, parent) => {
            if (parent.assessmentIndicatorDefinitionId !== definitionId) return parent;
            return { ...parent, comment: newComment, commentChange: true };
        });
    }

    handleChildValueChange(event) {
        const { childId, taskId, value, isCheckbox } = event.detail;

        this.updateGroupedQuestions((group, parent) => ({
            ...parent,
            childQuestions: parent.childQuestions.map(child => {
                if (child.assessmentIndicatorDefinitionId !== childId || child.assessmentTaskId !== taskId) return child;
                return { ...child, checkboxValue: isCheckbox ? value : child.checkboxValue, responseValue: !isCheckbox ? value : child.responseValue };
            })
        }));
    }

    // ========================================
    // REGULATORY CODES
    // ========================================

    async handleViewRegulatoryCodes(event) {
        const indicatorId = event.target.dataset.value;
        
        if (this.regulatoryCodesCache[indicatorId]) {
            this.regulatoryCodes = this.regulatoryCodesCache[indicatorId];
            this.showRegulatoryModal = true;
            return;
        }

        this.isLoading = true;
        try {
            const result = await getRegulatoryCodesByIndicator({ assessmentIndicatorDefinitionId: indicatorId });
            const formattedCodes = result.map(code => ({
                regulatoryCodeName: code.regulatoryCodeName,
                statusText: code.isActive ? 'Active' : 'Inactive',
                validityText: code.validityText || 'N/A'
            }));
            
            this.regulatoryCodesCache[indicatorId] = formattedCodes;
            this.regulatoryCodes = formattedCodes;
            this.showRegulatoryModal = true;
        } catch (error) {
            console.error(error);
            this.showToast('Error', 'Unable to fetch regulatory codes', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    closeRegulatoryModal() {
        this.showRegulatoryModal = false;
    }

    // ========================================
    // REVIEW SCREEN
    // ========================================

    handleShowReview() {
    this.reviewData = this.groupedQuestions.map(group => {
        const questions = group.parentQuestions.map(parent => {
            const config = STATUS_CONFIG[parent.result] || STATUS_CONFIG.default;
            const isNonCompliant = parent.result === RESULT_NON_COMPLIANT;

            return {
                questionId: parent.assessmentIndicatorDefinitionId,
                questionText: parent.questionText,
                result: parent.result || '',
                statusLabel: config.label,
                statusIcon: config.icon,
                statusClass: config.statusClass,
                statusIconClass: config.iconClass,
                reviewItemClass: config.itemClass,

                // Parent-level details
                hasComment: !!parent.comment,
                comment: parent.comment || '',

                isNonCompliant,
                priority: isNonCompliant ? parent.selectPriority || '' : null,
                complianceDueDate: isNonCompliant ? parent.preferredDateTime || null : null,
                correctiveActionDescription: isNonCompliant
                    ? parent.actionDescription || ''
                    : null,

                // ✅ ADD THIS: selected child questions
                childQuestionsForReview: isNonCompliant
                    ? (parent.childQuestions || []).map(child => ({
                        id: child.assessmentIndicatorDefinitionId,
                        questionText: child.questionText,
                        checked: child.checkboxValue === true
                    }))
                    : []
                };
            });

            const answeredCount = questions.filter(q => q.result).length;

            return {
                categoryId: group.taskDefinitionId,
                categoryName: group.taskDefinitionName,
                totalCount: questions.length,
                answeredCount,
                progressClass:
                    answeredCount === questions.length
                        ? 'progress-complete'
                        : 'progress-pending',
                questions
            };
        });

        this.showReviewModal = true;
    }


    closeReviewModal() {
        this.showReviewModal = false;
    }

    handleSubmitFromReview() {
        this.closeReviewModal();
        this.handleSubmit();
    }

    handleNavigateToQuestion(event) {
        const { questionid, categoryid } = event.currentTarget.dataset;
        this.closeReviewModal();

        this.groupedQuestions = this.groupedQuestions.map(group => {
            if (group.taskDefinitionId !== categoryid) return group;
            return { ...group, isExpanded: true, iconName: 'utility:chevrondown' };
        });

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const el = this.template.querySelector(`[data-question-id="${questionid}"]`);
            if (el) {
                el.scrollIntoView({ behavior: 'smooth', block: 'center' });
                el.classList.add('question-card--highlight');
                // eslint-disable-next-line @lwc/lwc/no-async-operation
                setTimeout(() => el.classList.remove('question-card--highlight'), 2000);
            }
        }, 100);
    }

    // ========================================
    // FILE UPLOAD
    // ========================================

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        const definitionId = event.target.dataset.definitionid;

        if (!this.uploadedFilesMap[definitionId]) {
            this.uploadedFilesMap[definitionId] = [];
        }
        uploadedFiles.forEach(file => file.documentId && this.uploadedFilesMap[definitionId].push(file.documentId));

        this.updateGroupedQuestions((group, parent) => {
            if (parent.assessmentIndicatorDefinitionId !== definitionId) return parent;
            return {
                ...parent,
                hasAttachments: true,
                attachmentCount: (parent.attachmentCount || 0) + uploadedFiles.length,
                uploadedContentDocIds: [...(parent.uploadedContentDocIds || []), ...uploadedFiles.map(f => f.documentId)]
            };
        });

        this.showToast('Success', `${uploadedFiles.length} file(s) uploaded`, 'success');
    }

    // ========================================
    // SUBMIT
    // ========================================

    handleSubmit() {
      this.showEndInspectionModal = true;
    }

    handleGoBack() {
      this.showEndInspectionModal = false;
    }

    async handleCompleteInspection() {
      this.showEndInspectionModal = false;
      await this.handleFinalSubmit();
    }

    async handleFinalSubmit() {
                    let isValid = true;
                    let statusnotselected = false;
                    let duedateempty = false;
                        this.template.querySelectorAll('lightning-input[data-field="compduedate"]').forEach(input => {
                            input.setCustomValidity('');
                            input.reportValidity();
                        });

                        for (const group of this.groupedQuestions) {
                            for (const parent of group.parentQuestions) {

                                if (!parent.result) {
                                    statusnotselected = true;
                                    isValid = false;
                                }

                                if (
                                    parent.showChildren &&                 
                                    !parent.preferredDateTime              
                                ) {
                                    duedateempty = true;
                                    isValid = false;

                                    
                                    const input = this.template.querySelector(
                                        `lightning-input[data-field="compduedate"][data-question-id="${parent.assessmentIndicatorDefinitionId}"]`
                                    );

                                    if (input) {
                                        input.setCustomValidity('Enter a compliance due date for non-compliant items');
                                        input.reportValidity();
                                    }
                                }
                            }
                        }

                        if (!isValid) {

                            if (statusnotselected) {
                                this.showToast(
                                    'Error',
                                    'Compliance Status must be selected for each inspection question before submitting.',
                                    'error'
                                );
                               return;
                            } 
                            if (duedateempty) {
                                this.showToast(
                                    'Error',
                                    'Enter a compliance due date for non-compliant items',
                                    'error'
                                );
                                return;
                            }
                        }
                    this.isLoading = true;
                    this.setSectionSavingState(true);

            try {
                    const responsesToSave = [];
                    let hasAnySelection = false;
                    const sectionsWithChanges = new Set();

                    for (const group of this.groupedQuestions) {
                        for (const parent of group.parentQuestions) {
                            //if (parent.result) {
                                const hasParentChanged =
                                    parent.result !== parent.originalResult ||
                                    parent.comment !== parent.originalComment ||
                                    parent.selectPriority !== parent.originalSelectPriority ||
                                    parent.preferredDateTime !== parent.originalPreferredDateTime ||
                                    parent.actionDescription !== parent.originalActionDescription ||
                                    parent.correctedDuringInspection !== parent.originalCorrectedDuringInspection;

                                if (hasParentChanged) {
                                responsesToSave.push({
                                    assessmentTaskId: parent.assessmentTaskId,
                                    definitionId: parent.assessmentIndicatorDefinitionId,
                                    comment: parent.comment || '',
                                    result: parent.result || '',
                                    checkboxValue: null,
                                    selectPriority: parent.selectPriority || null,
                                    preferredDateTime: parent.preferredDateTime
                                    ? new Date(parent.preferredDateTime).toISOString()
                                    : null,
                                    actionDescription: parent.actionDescription || null,
                                    correctedDuringInspection: parent.correctedDuringInspection || false
                                });
                                sectionsWithChanges.add(group.taskDefinitionId);
                                //if (resultChanged && parent.result) hasAnySelection = true;
                            }

                            if (parent.showChildren && parent.childQuestions) {
                                for (const child of parent.childQuestions) {
                                    if (child.checkboxValue !== child.originalCheckboxValue) {
                                        responsesToSave.push({
                                            assessmentTaskId: child.assessmentTaskId,
                                            definitionId: child.assessmentIndicatorDefinitionId,
                                            comment: '',
                                            result: RESULT_NON_COMPLIANT,
                                            checkboxValue: child.checkboxValue
                                        });
                                        sectionsWithChanges.add(group.taskDefinitionId);
                                    }
                                }
                            }
                        }
                    }


                    if (!hasAnySelection && responsesToSave.length === 0) {
                        this.setSectionSavingState(false);
                        this.showToast('Info', 'No changes to save', 'info');
                        this.isLoading = false;
                        return;
                    }

                    let saveResult = null;
                    if (responsesToSave.length > 0) {
                        saveResult = await saveAssessmentResponses({ responses: responsesToSave });
                        
                        if (!saveResult.success && saveResult.errors?.length > 0) {
                            console.error('Save errors:', saveResult.errors);
                            this.showToast('Warning', `Saved with ${saveResult.errors.length} error(s). Some responses may not have been saved.`, 'warning');
                        }
                    }

                    // Link uploaded files
                    if (saveResult && Object.keys(this.uploadedFilesMap).length > 0) {
                        try {
                            const defIdToAssessmentIndId = {};
                            for (const defId of Object.keys(this.uploadedFilesMap)) {
                                const assessmentIndId = saveResult.definitionIdToRecordIdMap[defId];
                                if (assessmentIndId) defIdToAssessmentIndId[defId] = assessmentIndId;
                            }

                            if (Object.keys(defIdToAssessmentIndId).length > 0) {
                                await linkFilesToAssessmentRecords({
                                    definitionIdToContentDocIds: this.uploadedFilesMap,
                                    definitionIdToAssessmentIndId: defIdToAssessmentIndId
                                });
                            }
                        } catch (linkError) {
                            console.error('Error linking files:', linkError);
                        }
                    }

                    // Update original values
                    this.updateGroupedQuestions((group, parent) => ({
                        ...parent,
                        originalResult: parent.result,
                        originalComment: parent.comment,
                        originalSelectPriority: parent.selectPriority,
                        originalPreferredDateTime: parent.preferredDateTime,
                        originalActionDescription: parent.actionDescription,
                        originalCorrectedDuringInspection: parent.correctedDuringInspection,
                        childQuestions: parent.childQuestions.map(child => ({ ...child, originalCheckboxValue: child.checkboxValue }))
                    }));

                    this.uploadedFilesMap = {};
                    this.setSectionSavedState(sectionsWithChanges);
                    
                    this.inspection = {
                        ...(this.inspection || {}),
                        Status: 'Completed'
                    };


                    await this.createViolationsAndNotify();

                    await completeInspection({ visitId: this.recordId, closingComments: this.closingComments });

                    } catch (error) {
                        console.error('Error saving assessment:', error);
                        this.setSectionSavingState(false);
                        this.showToast('Error', 'Error saving assessment: ' + (error?.body?.message || error?.message || 'Unknown error'), 'error');
                    } finally {
                        this.isLoading = false;
                    }
    }

    handleClosingCommentsChange(event) {
      this.closingComments = event.target.value;
      const length = this.closingComments.length;

      if (length >= 900 && length < 1000) {
        this.closingCommentsMessage =
            `You are approaching the 1000 character limit (${length}/1000).`;
        this.closingCommentsMessageClass = 'slds-text-color_warning';
      } else if (length === 1000) {
        this.closingCommentsMessage =
            'Maximum 1000 characters allowed.';
        this.closingCommentsMessageClass = 'slds-text-color_error';
      } else {
        this.closingCommentsMessage = '';
        this.closingCommentsMessageClass = '';
      }
    }

    async createViolationsAndNotify() {
        try {
            const violationResult = await createViolationsForInspection({ visitId: this.recordId });
            
            if (violationResult?.success) {
                const parentCount = violationResult.parentViolationIds?.length || 0;
                const cannedCount = violationResult.cannedCommentViolationIds?.length || 0;
                const totalCount = violationResult.violationCount || 0;
                
                if (totalCount > 0) {
                    let msg = `Inspection saved. ${parentCount} violation(s) created for non-compliant questions`;
                    if (cannedCount > 0) msg += ` and ${cannedCount} violation(s) for selected canned comments`;
                    this.showToast('Success', msg + '.', 'success');
                } else {
                    this.showToast('Success', 'Inspection Assessment saved successfully. No violations created.', 'success');
                }
                return violationResult.parentViolationIds || [];              
            } else {
                this.showToast('Partial Success', `Inspection saved, but violation creation had issues: ${violationResult?.message || 'Unknown error'}. Please review manually.`, 'warning');
            }
        } catch (violationError) {
            console.error('Error creating violations:', violationError);
            this.showToast('Partial Success', `Inspection saved, but could not create violations: ${violationError?.body?.message || violationError?.message || 'Unknown error'}. Please review the inspection manually.`, 'warning');
        }
    }

    setSectionSavingState(isSaving) {
        this.groupedQuestions = this.groupedQuestions.map(group => ({ ...group, isSaving, hasSaved: false }));
    }

    setSectionSavedState(sectionIds) {
        this.groupedQuestions = this.groupedQuestions.map(group => ({
            ...group,
            isSaving: false,
            hasSaved: sectionIds ? sectionIds.has(group.taskDefinitionId) : true
        }));

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.groupedQuestions = this.groupedQuestions.map(group => ({ ...group, hasSaved: false }));
        }, 3000);
    }
}