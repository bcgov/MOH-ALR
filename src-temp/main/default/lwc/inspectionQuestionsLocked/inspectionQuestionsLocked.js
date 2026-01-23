import { LightningElement, track, api } from 'lwc';

export default class InspectionQuestionsLocked extends LightningElement {

    @api recordId;

    @track showQuestions = false;
    @track showReviewModal = false;
    @track showConfirmModal = false;
    @track isReadOnly = false;
    @track isLoading = false;
    @track isSubmitDisabled = false;

    // Demo data – replace with Apex later
    @track groupedQuestions = [
        {
            taskDefinitionId: 'CAT1',
            taskDefinitionName: 'Facility Safety',
            iconName: 'utility:chevronright',
            isExpanded: true,
            isComplete: false,
            pendingCount: 1,
            parentQuestions: [
                {
                    assessmentTaskId: 'Q1',
                    assessmentIndicatorDefinitionId: 'DEF1',
                    questionText: 'Are emergency exits clearly marked?',
                    compliantButtonClass: 'btn',
                    nonCompliantButtonClass: 'btn',
                    naButtonClass: 'btn',
                    nsButtonClass: 'btn',
                    correctedDuringInspection: false,
                    selectPriority: '',
                    preferredDateTime: '',
                    comment: ''
                }
            ]
        }
    ];

    priorityOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    connectedCallback() {
        // Simulate backend inspection status
        const inspectionStatus = 'Draft'; // Change to 'Completed' to test lock
        const isAdmin = false;

        if (inspectionStatus === 'Completed' && !isAdmin) {
            this.isReadOnly = true;
        }

        // Expand all sections by default
        this.groupedQuestions = this.groupedQuestions.map(g => {
            return { ...g, isExpanded: true };
        });
    }

    get progressText() {
        return 'Inspection In Progress';
    }

    get progressBarStyle() {
        return 'width:50%';
    }

    handleStart() {
        this.showQuestions = true;
    }

    handleToggleSection(event) {
        const id = event.currentTarget.dataset.id;
        this.groupedQuestions = this.groupedQuestions.map(group => {
            if (group.taskDefinitionId === id) {
                return { ...group, isExpanded: !group.isExpanded };
            }
            return group;
        });
    }

    handleAssessmentChange() {}
    handleCorrectedDuringInspectionChange() {}
    handlePriorityChange() {}
    handleDatetimeChange() {}
    handleCommentChange() {}

    handleShowReview() {
        this.showReviewModal = true;
    }

    closeReviewModal() {
        this.showReviewModal = false;
    }

    handleSubmit() {
        this.showConfirmModal = true;
    }

    handleSubmitFromReview() {
        this.showConfirmModal = true;
        this.showReviewModal = false;
    }

    closeConfirmModal() {
        this.showConfirmModal = false;
    }

    handleCompleteInspection() {
        this.isLoading = true;

        // Simulate server update
        setTimeout(() => {
            this.isLoading = false;
            this.isReadOnly = true;
            this.showConfirmModal = false;
        }, 1000);
    }

    get totalQuestions() {
        return 1;
    }

    get compliantCount() {
        return 0;
    }

    get nonCompliantCount() {
        return 0;
    }

    get unansweredCount() {
        return 1;
    }

    get isSubmitDisabled() {
        return this.isReadOnly || this.isSubmitDisabled;
    }
}