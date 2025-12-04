import { LightningElement, track, api } from 'lwc';
import getInspectionQuestions from '@salesforce/apex/InspectionQuestionsController.getInspectionQuestions';
import getRegulatoryCodesByIndicator from '@salesforce/apex/InspectionQuestionsController.getRegulatoryCodesByIndicator';
//import createInspectionAssessments from '@salesforce/apex/InspectionQuestionsController.createInspectionAssessments';
import getcmtresult from '@salesforce/apex/PHOCSInspectionAssessmentIndController.getcmtresult';
import getExistingComments from '@salesforce/apex/PHOCSInspectionAssessmentIndController.getExistingComments';


import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class InspectionQuestionsParent extends LightningElement {
    @api recordId;
    @track groupedQuestions = [];
    @track showQuestions = false;
    @track isLoading = false;
    @track showRegulatoryModal = false;
    @track regulatoryCodes = [];

    resultOptions = [
        { label: 'Compliant', value: 'Compliant' },
        { label: 'Non-compliant', value: 'Non-compliant' }
    ];

    connectedCallback() {
        this.loadInspectionQuestions();
    }
    async loadInspectionQuestions() {
    this.isLoading = true;

    try {
        const result = await getInspectionQuestions({ visitId: this.recordId });
        const definitionIds = [];
        result.forEach(group => {
            group.parentQuestions.forEach(parent => {
                definitionIds.push(parent.assessmentIndicatorDefinitionId);
            });
        });
        const commentsMap = await getExistingComments({ defIds: definitionIds });
        this.groupedQuestions = result.map(group => ({
            ...group,
            isExpanded: false,
            iconName: 'utility:chevronright',
            parentQuestions: group.parentQuestions.map(parent => {

                const savedComment =
                    commentsMap[parent.assessmentIndicatorDefinitionId] || '';

                return {
                    ...parent,
                    result: parent.Result || '',       
                    originalResult: parent.Result || '',
                    comment: savedComment,
                    commentChange: false,
                    showChildren: parent.Result === 'Non-compliant',
                    childQuestions: parent.childQuestions.map(child => ({
                        ...child,
                        responseValue: child.Result || '',
                        originalResponse: child.Result || ''
                    }))
                };
            })
        }));

    } catch (error) {
        console.error(error);
        this.showToast('Error', 'Error loading inspection questions', 'error');

    } finally {
        this.isLoading = false;
    }
}

    handleStart() {
        this.showQuestions = true;
    }

    handleToggleSection(event) {
        const sectionId = event.currentTarget.dataset.id;
        this.groupedQuestions = this.groupedQuestions.map(group => {
            if (group.taskDefinitionId === sectionId) {
                const expanded = !group.isExpanded;
                return {
                    ...group,
                    isExpanded: expanded,
                    iconName: expanded ? 'utility:chevrondown' : 'utility:chevronright'
                };
            }
            return group;
        });
    }

    handleAssessmentChange(event) {
    const definitionId = event.target.dataset.definitionid;
    const value = event.target.dataset.value;

    this.groupedQuestions = this.groupedQuestions.map(group => ({
        ...group,
        parentQuestions: group.parentQuestions.map(parent => {
            if (parent.assessmentIndicatorDefinitionId === definitionId) {

                
                parent.result = value;
                parent.resultChanged = true;
                parent.showChildren = (value === 'Non-compliant');
            }
            return parent;
        })
    }));
}
    handleCommentChange(event) {
    const definitionId = event.target.dataset.definitionid;
    const newComment = event.target.value;

    this.groupedQuestions = this.groupedQuestions.map(group => ({
        ...group,
        parentQuestions: group.parentQuestions.map(parent => {
            if (parent.assessmentIndicatorDefinitionId === definitionId) {

                parent.comment = newComment;
                parent.commentChange = true;
            }
            return parent;
        })
    }));
}


    handleChildValueChange(event) {
        const { parentId, childId } = event.detail;
        const value = event.detail.value;

        this.groupedQuestions = this.groupedQuestions.map(group => ({
            ...group,
            parentQuestions: group.parentQuestions.map(parent => {
                if (parent.assessmentIndicatorDefinitionId === parentId) {
                    const updatedChildren = parent.childQuestions.map(child => {
                        if (child.assessmentIndicatorDefinitionId === childId) {
                            return { ...child, responseValue: value };
                        }
                        return child;
                    });
                    return { ...parent, childQuestions: updatedChildren };
                }
                return parent;
            })
        }));
    }

    async handleViewRegulatoryCodes(event) {
        const indicatorId = event.target.value;
        this.isLoading = true;
        try {
            const result = await getRegulatoryCodesByIndicator({ assessmentIndicatorDefinitionId: indicatorId });
            this.regulatoryCodes = result.map(code => ({
                regulatoryCodeName: code.regulatoryCodeName,
                statusText: code.isActive ? 'Active' : 'Inactive',
                validityText: code.validityText || 'N/A'
            }));
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

    async handleSubmit() {
    this.isLoading = true;

    try {
        let hasAnySelection = false;

        for (const group of this.groupedQuestions) {

            for (const parent of group.parentQuestions) {

                const resultChanged =
                    parent.result !== parent.originalResult;

                const commentChanged =
                    parent.commentChange === true;

                if (resultChanged || commentChanged) {

                    await getcmtresult({
                        assessmentTaskId: parent.assessmentTaskId,
                        definitionId: parent.assessmentIndicatorDefinitionId,
                        comment: parent.comment || '',
                        result: parent.result || ''
                    });

                    if (resultChanged && parent.result) {
                        hasAnySelection = true;
                    }
                }

                
                if (parent.showChildren && parent.childQuestions) {

                    for (const child of parent.childQuestions) {

                        const childChanged =
                            child.responseValue !== child.originalResponse;

                        if (childChanged) {
                            await getcmtresult({
                                assessmentTaskId: child.assessmentTaskId,
                                definitionId: child.assessmentIndicatorDefinitionId,
                                comment: '',
                                result: child.responseValue || "Non-compliant"
                            });
                        }
                    }
                }
            }
        }

        if (!hasAnySelection) {
            this.showToast(
                'Info',
                'No Compliance Status selected to submit',
                'info'
            );
            return;
        }

        this.showToast(
            'Success',
            'Inspection Assessment saved successfully',
            'success'
        );

    } catch (error) {
        console.error(error);
        this.showToast('Error', 'Error saving assessment', 'error');

    } finally {
        this.isLoading = false;
    }
}


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}