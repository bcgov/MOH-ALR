import { LightningElement, api } from "lwc";
import getInspectionQuestions from "@salesforce/apex/InspectionQuestionsControllerV2.getInspectionQuestions";
import getRegulatoryCodesByIndicator from "@salesforce/apex/InspectionQuestionsControllerV2.getRegulatoryCodesByIndicator";
import saveAssessmentResponses from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.saveAssessmentResponses";
import linkFilesToAssessmentRecords from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.linkFilesToAssessmentRecords";
import createViolationsForInspection from "@salesforce/apex/InspectionViolationService.createRegulatoryCodeViolationsForInspection";
import completeInspection from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.completeInspection";
import getVisitMeta from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.getVisitMeta";
import resetChildResponsesForCompliantParents from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.resetChildResponsesForCompliantParents";
import markInspectionAsDraft from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.markInspectionAsDraft";
import validateResumeInspection from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.validateResumeInspection";
import updateInspectionStatusToInProgress from "@salesforce/apex/InspectionQuestionsControllerV2.updateInspectionStatusToInProgress";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getInspection from '@salesforce/apex/PHOCSInspectionsHelper.getInspection';
import updateOpeningComments from "@salesforce/apex/PHOCSInspectionAssessmentIndControllerV2.updateOpeningComments";
import getParentQuestionsWithOpenViolations from "@salesforce/apex/PHOCSInspectionOpenViolationController.getParentQuestionsWithOpenViolations";


const RESULT_COMPLIANT = "Compliant";
const RESULT_NON_COMPLIANT = "PHOCSNonCompliant";
const RESULT_NA = "Not Applicable";
const RESULT_NS = "Not Inspected";
const RESULT_YES = "Yes";
const RESULT_NO = "No";
const ROUTINE_INSPECTION ="Routine";

const STATUS_CONFIG = {
    [RESULT_COMPLIANT]: { label: 'Compliant', icon: 'utility:success', iconClass: 'slds-icon-text-success', itemClass: 'review-item review-item--compliant', statusClass: 'review-status-compliant' },
    [RESULT_NON_COMPLIANT]: { label: 'Non-Compliant', icon: 'utility:error', iconClass: 'slds-icon-text-error', itemClass: 'review-item review-item--noncompliant', statusClass: 'review-status-noncompliant' },
    [RESULT_NA]: { label: RESULT_NA, icon: 'utility:dash', iconClass: 'slds-icon-text-default', itemClass: 'review-item review-item--neutral', statusClass: 'review-status-neutral' },
    [RESULT_NS]: { label: RESULT_NS, icon: 'utility:dash', iconClass: 'slds-icon-text-default', itemClass: 'review-item review-item--neutral', statusClass: 'review-status-neutral' },
    [RESULT_YES]: { label: 'Yes', icon: 'utility:success', iconClass: 'slds-icon-text-success', itemClass: 'review-item review-item--compliant', statusClass: 'review-status-compliant' },
	[RESULT_NO]: { label: 'No', icon: 'utility:error', iconClass: 'slds-icon-text-error', itemClass: 'review-item review-item--noncompliant', statusClass: 'review-status-noncompliant' },
	default: { label: 'Not Answered', icon: 'utility:warning', iconClass: 'slds-icon-text-warning', itemClass: 'review-item review-item--unanswered', statusClass: 'review-status-unanswered' }
};

export default class InspectionQuestionsParentv2 extends LightningElement {
	@api recordId;

	inspection = {};
	groupedQuestions = [];
	showQuestions = false;
	isLoading = false;
	showRegulatoryModal = false;
	regulatoryCodes = [];
	showReviewModal = false;
	reviewData = [];
	autoOpenedReview = false;
	timeSpent = '';
    followUpInspectionRequired = false;
	routineInspection = false;

	totalQuestions = 0;
	answeredQuestions = 0;
	compliantCount = 0;
	nonCompliantCount = 0;
	 
	showEndInspectionModal = false;
	closingComments = "";
	closingCommentsMessage = "";
	closingCommentsMessageClass = "";
	isDraft = false;
	inspectionOpeningComments = "";

	regulatoryCodesCache = {};
	uploadedFilesMap = {};

	get acceptedFormats() {
		return [".pdf", ".png", ".jpg", ".jpeg", ".doc", ".docx", ".xls", ".xlsx"];
	}

	get isSubmitDisabled() {
		if (!this.groupedQuestions?.length) return true;
		
		for (const group of this.groupedQuestions) {
			for (const parent of group.parentQuestions) {
				if (!parent.result) {
					return true; 
            }
        }
    }
	   return false; 
	}

	get progressText() {
		return `${this.answeredQuestions} of ${this.totalQuestions} questions answered`;
	}

	get progressBarStyle() {
		const pct =
			this.totalQuestions > 0 ?
			Math.round((this.answeredQuestions / this.totalQuestions) * 100) :
			0;
		return `width: ${pct}%`;
	}

	get hasRegulatoryCodes() {
		return this.regulatoryCodes?.length > 0;
	}

	get unansweredCount() {
		return this.totalQuestions - this.answeredQuestions;
	}

	get isCompleted() {
		return this.inspection?.Status === 'Completed';
	}

	/*get minComplianceDateTime() {
	  const today = new Date();
	  today.setHours(0, 0, 0, 0); 
	  const yyyy = today.getFullYear();
	  const mm = String(today.getMonth() + 1).padStart(2, '0');
	  const dd = String(today.getDate()).padStart(2, '0');
	  return `${yyyy}-${mm}-${dd}T00:00`;
	} */

	priorityOptions = [
      { label: "Critical", value: "Critical" },
      { label: "High", value: "High" },
      { label: "Medium", value: "Medium" },
      { label: "Low", value: "Low" },
    ];

	connectedCallback() {
		this.getInspection();
		this.loadInspectionQuestions();
	}

	renderedCallback() {
		if (
			this.isCompleted &&
			this.groupedQuestions.length > 0 &&
			!this.autoOpenedReview
		) {
			this.autoOpenedReview = true;
			this.showQuestions = true;
		}
	}


	// ========================================
	// HELPER METHODS
	// ========================================

	getButtonClass(buttonValue, selectedValue) {
		if (selectedValue !== buttonValue) return "compliance-btn";
		const classMap = {
			[RESULT_COMPLIANT]: "compliance-btn compliance-btn--selected-compliant",
			[RESULT_NON_COMPLIANT]: "compliance-btn compliance-btn--selected-noncompliant",
			[RESULT_NA]: "compliance-btn compliance-btn--selected-na",
			[RESULT_NS]: "compliance-btn compliance-btn--selected-ns",
			[RESULT_YES]: "compliance-btn compliance-btn--selected-compliant",
			[RESULT_NO]: "compliance-btn compliance-btn--selected-noncompliant",
		};
		return classMap[buttonValue] || "compliance-btn";
	}

	get startButtonLabel() {
		return this.isDraft ? "Resume Inspection" : "Start Inspection";
	}

	calculateSectionProgress(parentQuestions) {
		const total = parentQuestions.length;
		const answered = parentQuestions.filter((q) => q.result).length;
		return {
			progressText: `(${answered}/${total})`,
			isComplete: answered === total,
			pendingCount: total - answered,
		};
	}

	updateParentQuestion(parent, updates) {
		const result = updates.result ?? parent.result;
		const effectiveChildren = updates.childQuestions ?? parent.childQuestions ?? [];
		const effectiveComment = updates.comment !== undefined ? updates.comment : parent.comment;
		const hasCannedComment = effectiveChildren.some(child => child.checkboxValue === true);
		const hasComment = effectiveComment && effectiveComment.trim().length > 0;
		const showNonCompliantHelpText = result === RESULT_NON_COMPLIANT && !hasCannedComment && !hasComment;

		return {
			...parent,

			selectPriority: updates.selectPriority !== undefined ?
				updates.selectPriority : parent.selectPriority,

			preferredDateTime: updates.preferredDateTime !== undefined ?
				updates.preferredDateTime : parent.preferredDateTime,

			actionDescription: updates.actionDescription !== undefined ?
				updates.actionDescription : parent.actionDescription,

			correctedDuringInspection: updates.correctedDuringInspection !== undefined ?
				updates.correctedDuringInspection : parent.correctedDuringInspection,

			...updates,

			showNonCompliantHelpText,

			compliantButtonClass: this.getButtonClass(RESULT_COMPLIANT, result),
			nonCompliantButtonClass: this.getButtonClass(
				RESULT_NON_COMPLIANT,
				result,
			),
			naButtonClass: this.getButtonClass(RESULT_NA, result),
			nsButtonClass: this.getButtonClass(RESULT_NS, result),
			yesButtonClass: this.getButtonClass(RESULT_YES, result),
			noButtonClass: this.getButtonClass(RESULT_NO, result),
			showChildren: result === RESULT_NON_COMPLIANT || result === RESULT_COMPLIANT,
			showNonCompliantFields: result === RESULT_NON_COMPLIANT,
		};
	}

	updateGroupedQuestions(updateFn) {
		this.groupedQuestions = this.groupedQuestions.map((group) => {
			const parentQuestions = group.parentQuestions.map((parent) =>
				updateFn(group, parent),
			);
			const progress = this.calculateSectionProgress(parentQuestions);
			return {
				...group,
				parentQuestions,
				...progress
			};
		});
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({
			title,
			message,
			variant
		}));
	}

	// ========================================
	// DATA LOADING
	// ========================================
	async getInspection() {
		try {
			this.inspection = await getInspection({
				visitId: this.recordId
			});

			this.inspectionOpeningComments = this.inspection.InstructionDescription || '';

		} catch (error) {
			console.error('Error fetching inspection:', error);
		}
	}

	async loadInspectionQuestions() {
		this.isLoading = true;

		try {
			const visit = await getVisitMeta({
				visitId: this.recordId
			});

			this.isDraft = visit.PHOCSIsDraft__c === true;
			this.showQuestions = false;

			this.routineInspection = visit.VisitType.Name === ROUTINE_INSPECTION;

			const result = await getInspectionQuestions({
				visitId: this.recordId
			});

			let questionCount = 0;
			let answeredCount = 0;
			let compliant = 0;
			let nonCompliant = 0;

			this.groupedQuestions = result.map((group) => {
				const parentQs = group.parentQuestions.map((parent) => {
					questionCount++;

					//const currentResult = parent.Result || '';
					const currentResult = parent.Result ?? parent.result ?? "";
					const savedComment = parent.PHOCSInspectionComments || "";

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
						showRegulationButtons: parent.questionType === 'Regulation',
						showBestPracticeButtons: parent.questionType === 'Best Practice/Guidelines' || parent.questionType === 'None',
						originalSelectPriority: parent.originalSelectPriority !== undefined ?
							parent.originalSelectPriority : (parent.selectPriority ?? null),

						originalPreferredDateTime: parent.originalPreferredDateTime !== undefined ?
							parent.originalPreferredDateTime : parent.preferredDateTime ?
							parent.preferredDateTime.slice(0, 16) : null,

						originalActionDescription: parent.originalActionDescription !== undefined ?
							parent.originalActionDescription : (parent.actionDescription ?? ""),

						originalCorrectedDuringInspection: parent.originalCorrectedDuringInspection !== undefined ?
							parent.originalCorrectedDuringInspection : (parent.correctedDuringInspection ?? false),

						// current editable values
						selectPriority: parent.selectPriority ?? null,
						preferredDateTime: parent.preferredDateTime 
						? this.formatDatetimeForInput(parent.preferredDateTime) : null,
						actionDescription: parent.actionDescription ?? "",
						correctedDuringInspection: parent.correctedDuringInspection ?? false,
						regcodvioId: parent.inspectionAssessmentIndId ?? null,
						showViolationIcon: false,
						questionCardClass: parent.showCriticalIcon ?
							"question-card question-card--critical" : "question-card",
						uploadedContentDocIds: [],
						childQuestions: parent.childQuestions.map((child) => {
							const savedCheckbox = child.PHOCSCheckboxResponse === true;

							return {
								...child,
								responseValue: child.Result || "",
								originalResponse: child.Result || "",
								checkboxValue: savedCheckbox,
								originalCheckboxValue: savedCheckbox
							};
						}),
					});
				});

				const progress = this.calculateSectionProgress(parentQs);
				return {
					...group,
					isExpanded: false,
					iconName: "utility:chevronright",
					isSaving: false,
					hasSaved: false,
					parentQuestions: parentQs,
					...progress,
				};
			});
			
			await this.loadViolationIcons();
			
			this.totalQuestions = questionCount;
			this.answeredQuestions = answeredCount;
			this.compliantCount = compliant;
			this.nonCompliantCount = nonCompliant;
		} catch (err) {
			console.error("Error loading inspection questions", err);
			this.showToast(
				"Error",
				"Error loading inspection questions: " +
				(err?.body?.message || err?.message),
				"error",
			);
		} finally {
			this.isLoading = false;
		}
	}

	// ========================================
	// EVENT HANDLERS
	// ========================================

	handleViewOnly() {
		this.showQuestions = true;

	}

	handleTimeSpentChange(event) {
    const input = event.target;
    const value = input.value.trim();
    this.timeSpent = value;

    const timeRegex = /^(\d{1,2}):([0-5][0-9])$/;

    if (!value) {
        input.setCustomValidity("Time Spent is required.");
    } else if (!timeRegex.test(value)) {
        input.setCustomValidity("Please enter time in valid HH:MM format.");
    } else {
        input.setCustomValidity("");
    }

	input.reportValidity();
	}

    handleFollowUpChange(event) {
        this.followUpInspectionRequired = event.target.checked;
    }

	async handleStart() {
		this.isLoading = true;

		try {
			if (this.isDraft) {
				await validateResumeInspection({
					visitId: this.recordId
				});
			} else {
				await updateInspectionStatusToInProgress({
					inspectionId: this.recordId
				});
			}

			if (this.isCompleted) {
				this.handleViewOnly();
			} else {
				this.showQuestions = true;
			}

		} catch (error) {
			const message =
				error?.body?.message ||
				error?.message ||
				"Unexpected error occurred";

			if (message.includes("Only the Officer who started the inspection")) {
				this.showToast("Error", message, "error");
			} else {
				this.showToast("Error", message, "error");
			}
			this.showQuestions = false;

		} finally {
			this.isLoading = false;
		}
	}

	handleToggleSection(event) {
		const sectionId = event.currentTarget.dataset.id;
		this.groupedQuestions = this.groupedQuestions.map((group) => {
			if (group.taskDefinitionId !== sectionId) return group;
			const expanded = !group.isExpanded;
			return {
				...group,
				isExpanded: expanded,
				iconName: expanded ? "utility:chevrondown" : "utility:chevronright",
			};
		});
	}

	handleSectionKeydown(event) {
		if (event.key === "Enter" || event.key === " ") {
			event.preventDefault();
			this.handleToggleSection(event);
		}
	}

	handleAssessmentChange(event) {
		const definitionId = event.target.dataset.definitionid;
		const taskId = event.target.dataset.taskid;
		const value = event.target.dataset.value;
		let prevResult = "";

		this.updateGroupedQuestions((group, parent) => {
			if (
				parent.assessmentIndicatorDefinitionId !== definitionId ||
				parent.assessmentTaskId !== taskId
			) {
				return parent;
			}

			prevResult = parent.result;
			const isNowNonCompliant = value === RESULT_NON_COMPLIANT;

			return this.updateParentQuestion(parent, {
				result: value,

				selectPriority: isNowNonCompliant ? parent.selectPriority : null,
				preferredDateTime: isNowNonCompliant ? parent.preferredDateTime : null,
				correctedDuringInspection: isNowNonCompliant ? parent.correctedDuringInspection : false,
				actionDescription: isNowNonCompliant ? parent.actionDescription : "",

				childQuestions:
                   value === RESULT_NA || value === RESULT_NS
                   ? parent.childQuestions.map(child => ({
                   ...child,
                   checkboxValue: false
                      }))
                   : parent.childQuestions
			});

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
				preferredDateTime: value,
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
				selectPriority: value,
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

			return this.updateParentQuestion(parent, {
				actionDescription: value
			});
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
				correctedDuringInspection: value,
			};
		});
	}

	// ========================================
	// Inspection Opening Comments EVENT
	// ========================================

	handleinspectionOpenCommentsChange(event) {
        this.inspectionOpeningComments = event.target.value;
    }

	// ========================================
	// Open Violation Incident Icon EVENT
	// ========================================

			async loadViolationIcons() {

        try {
            let parentIds = new Set();

            this.groupedQuestions.forEach(group => {
                group.parentQuestions.forEach(parent => {
                    parentIds.add(parent.assessmentIndicatorDefinitionId);
                });
            });

            const quewithopenvio = await getParentQuestionsWithOpenViolations({
                visitId: this.recordId,
                parentQuestionIds: Array.from(parentIds)
            });

            const violationSet = new Set(quewithopenvio);


            this.groupedQuestions = this.groupedQuestions.map(group => {
                return {
                    ...group,
                    parentQuestions: group.parentQuestions.map(parent => {
                        return {
                            ...parent,
                            showViolationIcon: violationSet.has(parent.assessmentIndicatorDefinitionId)
                        };
                    })
                };
            });

        } catch (error) {
            console.error('Violation error:', error);
        }
    }

	

	handleCommentChange(event) {
		const definitionId = event.target.dataset.definitionid;
		const newComment = event.target.value;

		this.updateGroupedQuestions((group, parent) => {
			const taskId = event.target.dataset.taskid;

			if (
				parent.assessmentIndicatorDefinitionId !== definitionId ||
				parent.assessmentTaskId !== taskId
			) {
				return parent;
			}
			return this.updateParentQuestion(parent, {
				comment: newComment
			});
		});
	}

	handleChildValueChange(event) {
		const {
			childId,
			taskId,
			value,
			isCheckbox
		} = event.detail;

		this.updateGroupedQuestions((group, parent) => {
			const ownsChild = parent.childQuestions?.some(
				(child) =>
				child.assessmentIndicatorDefinitionId === childId &&
				child.assessmentTaskId === taskId,
			);

			if (!ownsChild) {
				return parent;
			}

			const updatedChildren = parent.childQuestions.map((child) => {
				if (
					child.assessmentIndicatorDefinitionId !== childId ||
					child.assessmentTaskId !== taskId
				) {
					return child;
				}

				return {
					...child,
					checkboxValue: isCheckbox ? value : child.checkboxValue,
					responseValue: !isCheckbox ? value : child.responseValue,
				};
			});

			return this.updateParentQuestion(parent, {
				childQuestions: updatedChildren
			});
		});
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
			const result = await getRegulatoryCodesByIndicator({
				assessmentIndicatorDefinitionId: indicatorId,
			});
			const seenCodes = new Set();
			const formattedCodes = [];

			result.forEach(code => {
				const key = code.regulatoryCodeId;
				if (seenCodes.has(key)) {
					return;
				}
				seenCodes.add(key);

				formattedCodes.push({
					regulatoryCodeId: code.regulatoryCodeId,
					regulatoryCodeName: code.regulatoryCodeName,
					regulatoryCodeSubject: code.regulatoryCodeSubject,
					statusText: code.isActive ? "Active" : "Inactive",
					validityText: code.validityText || "N/A",
				});
			});

			this.regulatoryCodesCache[indicatorId] = formattedCodes;
			this.regulatoryCodes = formattedCodes;
			this.showRegulatoryModal = true;
		} catch (error) {
			console.error(error);
			this.showToast("Error", "Unable to fetch regulatory codes", "error");
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
		this.reviewData = this.groupedQuestions.map((group) => {
			const questions = group.parentQuestions.map((parent) => {
				const config = STATUS_CONFIG[parent.result] || STATUS_CONFIG.default;
				const isNonCompliant = parent.result === RESULT_NON_COMPLIANT;
				const isCompliant = parent.result === RESULT_COMPLIANT;

				return {
					questionId: parent.assessmentIndicatorDefinitionId,
					questionText: parent.questionText,
					result: parent.result || "",
					statusLabel: config.label,
					statusIcon: config.icon,
					statusClass: config.statusClass,
					statusIconClass: config.iconClass,
					reviewItemClass: config.itemClass,
					hasComment: !!parent.comment,
					comment: parent.comment || "",
					isCompliant,
					isNonCompliant,
					priority: isNonCompliant ? parent.selectPriority || '' : null,
					complianceDueDate: isNonCompliant ? parent.preferredDateTime || null : null,
					correctiveActionDescription: isNonCompliant ?
						parent.actionDescription || '' :
						null,

					childQuestionsForReview: (isNonCompliant || isCompliant) ?
						(parent.childQuestions || []).map(child => ({
							id: child.assessmentIndicatorDefinitionId,
							questionText: child.questionText,
							checked: child.checkboxValue === true
						})) :
						[]
				};
			});

			const answeredCount = questions.filter((q) => q.result).length;
			return {
				categoryId: group.taskDefinitionId,
				categoryName: group.taskDefinitionName,
				totalCount: questions.length,
				answeredCount,
				progressClass: answeredCount === questions.length ?
					"progress-complete" : "progress-pending",
				questions,
			};
		});
		this.showReviewModal = true;
	}
	handleMarkNotInspected() {		
		let updatedCount = 0;		
    	this.groupedQuestions = (this.groupedQuestions || []).map(group => {
			const updatedParentQuestions = (group.parentQuestions || []).map(parent => {
				const currentValue = parent.result ?? "";
				if (currentValue === "") {				
					updatedCount += 1;
					return this.updateParentQuestion(parent, {
						result: RESULT_NS,
					});
				}
				return parent;
			});
        return { ...group, parentQuestions: updatedParentQuestions };
		});
		this.answeredQuestions = (this.answeredQuestions || 0) + updatedCount;
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

		// Close modal
		this.closeReviewModal();

		// Expand the correct category
		this.groupedQuestions = this.groupedQuestions.map(group => {
			if (group.taskDefinitionId !== categoryid) return group;
			return {
				...group,
				isExpanded: true,
				iconName: 'utility:chevrondown'
			};
		});

		// Wait for LWC render + browser paint
		requestAnimationFrame(() => {
			requestAnimationFrame(() => {
				const target = this.template.querySelector(
					`[data-question-id="${questionid}"]`
				);

				if (target) {
					target.scrollIntoView({
						behavior: 'smooth',
						block: 'center'
					});

					target.classList.add('question-card--highlight');

					setTimeout(() => {
						target.classList.remove('question-card--highlight');
					}, 2000);
				}
			});
		});
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
		uploadedFiles.forEach(
			(file) =>
			file.documentId &&
			this.uploadedFilesMap[definitionId].push(file.documentId),
		);

		this.updateGroupedQuestions((group, parent) => {
			if (parent.assessmentIndicatorDefinitionId !== definitionId)
				return parent;
			return {
				...parent,
				hasAttachments: true,
				attachmentCount: (parent.attachmentCount || 0) + uploadedFiles.length,
				uploadedContentDocIds: [
					...(parent.uploadedContentDocIds || []),
					...uploadedFiles.map((f) => f.documentId),
				],
			};
		});

		this.showToast(
			"Success",
			`${uploadedFiles.length} file(s) uploaded`,
			"success",
		);
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
		const input = this.template.querySelector(
        'lightning-input[data-field="timespent"]'
        );

        const value = input.value ? input.value.trim() : '';
		const timeRegex = /^(\d{1,2}):([0-5][0-9])$/;

        if (!value) {
			input.setCustomValidity("Time Spent is required.");
			input.reportValidity();
			return;
		}
		
		if (!timeRegex.test(value)) {
			input.setCustomValidity("Please enter time in valid HH:MM format.");
			input.reportValidity();
			return;
		}

        input.setCustomValidity("");
        input.reportValidity();

		this.showEndInspectionModal = false;
		await this.handleFinalSubmit();
	}

	async handleFinalSubmit() {
		let isValid = true;
		let statusnotselected = false;
		let duedateempty = false;
		let missingNonCompliantDetails = false;
		const unansweredParents = [];

        for (const group of this.groupedQuestions) {
          for (const parent of group.parentQuestions) {
              if (!parent.result) {
                  unansweredParents.push(parent.assessmentIndicatorDefinitionId);
              }
            }
        }

        if (unansweredParents.length > 0) {
          this.showToast(
            "Error",
            `You have ${unansweredParents.length} unanswered question(s). Please complete them before submitting.`,
            "error"
          );
          return;
        }

		this.template
			.querySelectorAll('lightning-input[data-field="compduedate"]')
			.forEach((input) => {
				input.setCustomValidity("");
				input.reportValidity();
			});

		for (const group of this.groupedQuestions) {
			for (const parent of group.parentQuestions) {
				if (parent.result === RESULT_NON_COMPLIANT) {
					const hasComment =
						parent.comment && parent.comment.trim().length > 0;

					const hasCannedComment =
						parent.childQuestions &&
						parent.childQuestions.some(child => child.checkboxValue === true);

					if (!hasComment && !hasCannedComment) {
						missingNonCompliantDetails = true;
						isValid = false;
					}
				}

				if (!parent.result) {
					statusnotselected = true;
					isValid = false;
				}

				if (parent.result === RESULT_NON_COMPLIANT && !parent.preferredDateTime) {
					duedateempty = true;
					isValid = false;

					const input = this.template.querySelector(
						`lightning-input[data-field="compduedate"][data-question-id="${parent.assessmentIndicatorDefinitionId}"]`,
					);

					if (input) {
						input.setCustomValidity(
							"Enter a compliance due date for non-compliant items",
						);
						input.reportValidity();
					}
				}
			}
		}

		if (!isValid) {
			if (statusnotselected) {
				this.showToast(
					"Error",
					"Compliance Status must be selected for each inspection question before submitting.",
					"error",
				);
				return;
			}
			if (duedateempty) {
				this.showToast(
					"Error",
					"Enter a compliance due date for non-compliant items",
					"error",
				);
				return;
			}
			if (missingNonCompliantDetails) {
				this.showToast(
					"Error",
					"Please select the applicable observation(s) or enter comments for all non-compliant questions to submit the inspection.",
					"error"
				);
				return;
			}
		}
		this.isLoading = true;
		this.setSectionSavingState(true);

		try {
			const responsesToSave = [];
			const sectionsWithChanges = new Set();
			const seenChildren = new Set();

			for (const group of this.groupedQuestions) {
				for (const parent of group.parentQuestions) {

					const hasParentChanged =
						parent.result !== parent.originalResult ||
						parent.comment !== parent.originalComment ||
						parent.selectPriority !== parent.originalSelectPriority ||
						parent.preferredDateTime !== parent.originalPreferredDateTime ||
						parent.actionDescription !== parent.originalActionDescription ||
						parent.correctedDuringInspection !==
						parent.originalCorrectedDuringInspection;

					if (hasParentChanged) {
						responsesToSave.push({
							assessmentTaskId: parent.assessmentTaskId,
							definitionId: parent.assessmentIndicatorDefinitionId,
							comment: parent.comment || "",
							result: parent.result || "",
							checkboxValue: null,
							selectPriority: parent.selectPriority || null,
							preferredDateTime: parent.preferredDateTime ? this.convertToSalesforceDatetime(parent.preferredDateTime) : null,
							actionDescription: parent.actionDescription || null,
							correctedDuringInspection: parent.correctedDuringInspection || false,
						});

						sectionsWithChanges.add(group.taskDefinitionId);
					}

					if ((parent.result === RESULT_NON_COMPLIANT || parent.result === RESULT_COMPLIANT)&& parent.childQuestions?.length) {

							const anyChildChanged = parent.childQuestions.some(
								c => c.checkboxValue !== c.originalCheckboxValue
								);
								
								if (anyChildChanged) {
									sectionsWithChanges.add(group.taskDefinitionId);

							for (const child of parent.childQuestions) {
								const key = `${child.assessmentTaskId}-${child.assessmentIndicatorDefinitionId}`;
								if (seenChildren.has(key)) continue;
								seenChildren.add(key);

								responsesToSave.push({
									assessmentTaskId: child.assessmentTaskId,
									definitionId: child.assessmentIndicatorDefinitionId,
									comment: "",
									result: child.checkboxValue === true ? parent.result : null,
									checkboxValue: child.checkboxValue === true,
								});
							}
						}
					}
				}
			}
			
			await updateOpeningComments({
				visitId: this.recordId,
				openingComments: this.inspectionOpeningComments
			});

			/*if (responsesToSave.length === 0) {
			    this.setSectionSavingState(false);
			    this.showToast("Info", "No changes to save", "info");
			    this.isLoading = false;
			    return;
			} */

			let saveResult = null;
			if (responsesToSave.length > 0) {
				saveResult = await saveAssessmentResponses({
					responses: responsesToSave,
				});

				if (!saveResult.success && saveResult.errors?.length > 0) {
					console.error("Save errors:", saveResult.errors);
					this.showToast(
						"Warning",
						`Saved with ${saveResult.errors.length} error(s). Some responses may not have been saved.`,
						"warning",
					);
				}
			}

			// Link uploaded files
			if (saveResult && Object.keys(this.uploadedFilesMap).length > 0) {
				try {
					const defIdToAssessmentIndId = {};
					for (const defId of Object.keys(this.uploadedFilesMap)) {
						const assessmentIndId = saveResult.definitionIdToRecordIdMap[defId];
						if (assessmentIndId)
							defIdToAssessmentIndId[defId] = assessmentIndId;
					}

					if (Object.keys(defIdToAssessmentIndId).length > 0) {
						await linkFilesToAssessmentRecords({
							definitionIdToContentDocIds: this.uploadedFilesMap,
							definitionIdToAssessmentIndId: defIdToAssessmentIndId,
						});
					}
				} catch (linkError) {
					console.error("Error linking files:", linkError);
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
				childQuestions: parent.childQuestions.map((child) => ({
					...child,
					originalCheckboxValue: child.checkboxValue,
				})),
			}));

			this.uploadedFilesMap = {};
			this.setSectionSavedState(sectionsWithChanges);
			if (saveResult?.success) {
				await resetChildResponsesForCompliantParents({
					visitId: this.recordId
				});
			}
			this.inspection = {
				...(this.inspection || {}),
				Status: 'Completed'
			};
			await this.createViolationsAndNotify();

			await completeInspection({
				visitId: this.recordId,
				closingComments: this.closingComments,
				timeSpent: this.timeSpent,
                followUpInspectionRequired: this.followUpInspectionRequired
			});
			this.isDraft = false;

			// HARD refresh to ensure clean read-only state
			window.location.reload();

		} catch (error) {
			console.error("Error saving assessment:", error);
			this.setSectionSavingState(false);
			this.showToast(
				"Error",
				"Error saving assessment: " +
				(error?.body?.message || error?.message || "Unknown error"),
				"error",
			);
		} finally {
			this.isLoading = false;
		}
	}

	handleClosingCommentsChange(event) {
		this.closingComments = event.target.value;
		const length = this.closingComments.length;

		if (length >= 900 && length < 1000) {
			this.closingCommentsMessage = `You are approaching the 1000 character limit (${length}/1000).`;
			this.closingCommentsMessageClass = "slds-text-color_warning";
		} else if (length === 1000) {
			this.closingCommentsMessage = "Maximum 1000 characters allowed.";
			this.closingCommentsMessageClass = "slds-text-color_error";
		} else {
			this.closingCommentsMessage = "";
			this.closingCommentsMessageClass = "";
		}
	}

	async createViolationsAndNotify() {
		try {
			const violationResult = await createViolationsForInspection({
				visitId: this.recordId,
			});

			if (violationResult?.success) {
				const parentCount = violationResult.parentViolationIds?.length || 0;
				const cannedCount =
					violationResult.cannedCommentViolationIds?.length || 0;
				const totalCount = violationResult.violationCount || 0;

				if (totalCount > 0) {
					let msg = `Inspection saved. ${parentCount} violation(s) created for non-compliant questions`;
					//if (cannedCount > 0)
					//	msg += ` and ${cannedCount} violation(s) for selected canned comments`;
					this.showToast("Success", msg + ".", "success");
				} else {
					this.showToast(
						"Success",
						"Inspection Assessment saved successfully. No violations created.",
						"success",
					);
				}
				return violationResult.parentViolationIds || [];
			} else {
				this.showToast(
					"Partial Success",
					`Inspection saved, but violation creation had issues: ${violationResult?.message || "Unknown error"}. Please review manually.`,
					"warning",
				);
			}
		} catch (violationError) {
			console.error("Error creating violations:", violationError);
			this.showToast(
				"Partial Success",
				`Inspection saved, but could not create violations: ${violationError?.body?.message || violationError?.message || "Unknown error"}. Please review the inspection manually.`,
				"warning",
			);
		}
	}

	setSectionSavingState(isSaving) {
		this.groupedQuestions = this.groupedQuestions.map((group) => ({
			...group,
			isSaving,
			hasSaved: false,
		}));
	}

	setSectionSavedState(sectionIds) {
		this.groupedQuestions = this.groupedQuestions.map((group) => ({
			...group,
			isSaving: false,
			hasSaved: sectionIds ? sectionIds.has(group.taskDefinitionId) : true,
		}));

		// eslint-disable-next-line @lwc/lwc/no-async-operation
		setTimeout(() => {
			this.groupedQuestions = this.groupedQuestions.map((group) => ({
				...group,
				hasSaved: false,
			}));
		}, 3000);
	}

	async handleSaveForLater() {
		this.isLoading = true;
		this.setSectionSavingState(true);

		try {
			const responsesToSave = this.buildResponsesPayload();

			if (responsesToSave.length > 0) {
				await saveAssessmentResponses({
					responses: responsesToSave
				});
			}

			await updateOpeningComments({
				visitId: this.recordId,
				openingComments: this.inspectionOpeningComments
			});


			await markInspectionAsDraft({
				visitId: this.recordId
			});

			// Reset originals so resume works cleanly
			this.updateGroupedQuestions((group, parent) => ({
				...parent,
				originalResult: parent.result,
				originalComment: parent.comment,
				originalSelectPriority: parent.selectPriority,
				originalPreferredDateTime: parent.preferredDateTime,
				originalActionDescription: parent.actionDescription,
				originalCorrectedDuringInspection: parent.correctedDuringInspection,
				childQuestions: parent.childQuestions.map((child) => ({
					...child,
					originalCheckboxValue: child.checkboxValue,
				})),
			}));

			this.isDraft = true;

			this.showToast(
				"Saved",
				"Inspection saved as draft. You can resume later.",
				"success",
			);

			this.setSectionSavedState();
		} catch (error) {
			console.error(error);
			this.showToast("Error", "Failed to save draft", "error");
			this.setSectionSavingState(false);
		} finally {
			this.isLoading = false;
		}
	}

	formatDatetimeForInput(sfDate) {
    if (!sfDate) return null;

    const d = new Date(sfDate);
    const yyyy = d.getFullYear();
    const mm = String(d.getMonth()+1).padStart(2,'0');
    const dd = String(d.getDate()).padStart(2,'0');
    const hh = String(d.getHours()).padStart(2,'0');
    const mi = String(d.getMinutes()).padStart(2,'0');

    return `${yyyy}-${mm}-${dd}T${hh}:${mi}`;
    }

	convertToSalesforceDatetime(value) {
    if (!value) return null;
    return value.replace('T',' ') + ':00';
    }

	buildResponsesPayload() {
		const responses = [];
		const seenChildren = new Set();

		for (const group of this.groupedQuestions) {
			for (const parent of group.parentQuestions) {
				const isNonCompliant = parent.result === RESULT_NON_COMPLIANT;
				const parentChanged =
					parent.result !== parent.originalResult ||
					parent.comment !== parent.originalComment ||
					parent.selectPriority !== parent.originalSelectPriority ||
					parent.preferredDateTime !== parent.originalPreferredDateTime ||
					parent.actionDescription !== parent.originalActionDescription ||
					parent.correctedDuringInspection !==
					parent.originalCorrectedDuringInspection;

				// Parent
				if (parentChanged) {
					responses.push({
						assessmentTaskId: parent.assessmentTaskId,
						definitionId: parent.assessmentIndicatorDefinitionId,
						comment: parent.comment || "",
						result: parent.result || "",
						checkboxValue: null,
						selectPriority: isNonCompliant ? parent.selectPriority : null,
						preferredDateTime: isNonCompliant && parent.preferredDateTime ? parent.preferredDateTime : null,
						correctedDuringInspection: isNonCompliant ?
							parent.correctedDuringInspection :
							false,
						actionDescription: isNonCompliant ?
							parent.actionDescription || null :
							null,
					});
				}

				// Children
				if (
					(parent.result === RESULT_NON_COMPLIANT || parent.result === RESULT_COMPLIANT) &&
					parent.childQuestions?.length
				) {
						for (const child of parent.childQuestions) {
							const key = `${child.assessmentTaskId}-${child.assessmentIndicatorDefinitionId}`;
							if (seenChildren.has(key)) continue;
							seenChildren.add(key);

							responses.push({
								assessmentTaskId: child.assessmentTaskId,
								definitionId: child.assessmentIndicatorDefinitionId,
								comment: "",
								result: child.checkboxValue === true ? parent.result : null,
								checkboxValue: child.checkboxValue === true,
								selectPriority: parent.result === RESULT_NON_COMPLIANT ? parent.selectPriority : null,
								preferredDateTime: parent.result === RESULT_NON_COMPLIANT && parent.preferredDateTime ? parent.preferredDateTime : null,
								correctedDuringInspection: parent.correctedDuringInspection || false,
							});
						}
				}
			}
		}

		return responses;
	}
	
	get showMarkNotInspectedButton() {
			return (
				this.routineInspection === false && this.compliantCount > 0
			);
	}
}