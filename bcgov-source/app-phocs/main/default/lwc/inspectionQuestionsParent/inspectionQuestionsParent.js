import { LightningElement, track, api } from 'lwc';
import getInspectionQuestions from '@salesforce/apex/InspectionQuestionsController.getInspectionQuestions';
import getRegulatoryCodesByIndicator from '@salesforce/apex/InspectionQuestionsController.getRegulatoryCodesByIndicator';
//import createInspectionAssessments from '@salesforce/apex/InspectionQuestionsController.createInspectionAssessments';
import getcmtresult from '@salesforce/apex/PHOCSInspectionAssessmentIndController.getcmtresult';
import getExistingCommentsByDefAndTask from '@salesforce/apex/PHOCSInspectionAssessmentIndController.getExistingCommentsByDefAndTask';


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
        let defIds = [];
        let taskIds = [];
        result.forEach(group => {
            group.parentQuestions.forEach(parent => {
                const defId = parent.assessmentIndicatorDefinitionId || parent.assessmentIndDefinitionId;
                const taskId = parent.assessmentTaskId;
                if (defId) defIds.push(defId);
                if (taskId) taskIds.push(taskId);

                if (parent.childQuestions && parent.childQuestions.length) {
                    parent.childQuestions.forEach(child => {
                if (child.assessmentIndicatorDefinitionId) defIds.push(child.assessmentIndicatorDefinitionId);
                if (child.assessmentTaskId) taskIds.push(child.assessmentTaskId);
                });
                }
            });
        });

        
        defIds = [...new Set(defIds)].filter(id => id);
        taskIds = [...new Set(taskIds)].filter(id => id);

        let commentsMap = {};
        if (defIds.length && taskIds.length) {
            
            commentsMap = await getExistingCommentsByDefAndTask({ defIds: defIds, taskIds: taskIds });
        } else {
            commentsMap = {};
        }

       
        this.groupedQuestions = result.map(group => ({
            ...group,
            isExpanded: false,
            iconName: 'utility:chevronright',
            parentQuestions: group.parentQuestions.map(parent => {
                const defId = parent.assessmentIndicatorDefinitionId || parent.assessmentIndDefinitionId;
                const taskId = parent.assessmentTaskId;
                const key = `${defId}|${taskId}`;
                const saved = commentsMap[key] || {};
                const savedComment = saved.comment || '';
                const savedCheckbox = saved.checkbox || false;

                return {
                    ...parent,
                    result: parent.Result || '',
                    originalResult: parent.Result || '',
                    comment: savedComment,
                    originalComment: savedComment,
                    commentChange: false,
                    showChildren: parent.Result === 'Non-compliant',
                    childQuestions: parent.childQuestions.map(child => {
                        const childKey = `${child.assessmentIndicatorDefinitionId}|${child.assessmentTaskId}`;
                        const childSaved = commentsMap[childKey] || {};
                        return{
                        ...child,
                        responseValue: child.Result || '',
                        originalResponse: child.Result || '',
                        checkboxValue: childSaved.hasOwnProperty('checkbox') ? childSaved.checkbox : false,
                        originalCheckboxValue: childSaved.hasOwnProperty('checkbox') ? childSaved.checkbox : false

                        };
                    })
                };
            })
        }));

    } catch (err) {
        console.error('Error loading inspection questions', err);
        this.showToast('Error', 'Error loading inspection questions: ' + (err?.body?.message || err?.message || JSON.stringify(err)), 'error');
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
    const { childId, taskId, value, isCheckbox } = event.detail;

    this.groupedQuestions = this.groupedQuestions.map(group => ({
        ...group,
        parentQuestions: group.parentQuestions.map(parent => ({
            ...parent,
            childQuestions: parent.childQuestions.map(child => {
                if (
                    child.assessmentIndicatorDefinitionId === childId &&
                    child.assessmentTaskId === taskId
                ) {
                    return {
                        ...child,
                        checkboxValue: isCheckbox ? value : child.checkboxValue,
                        responseValue: !isCheckbox ? value : child.responseValue
                    };
                }
                return child;
            })
        }))
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
                    parent.comment !== parent.originalComment;

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
                    const checkboxChanged = child.checkboxValue !== child.originalCheckboxValue;

                        if(checkboxChanged){
                            

                            await getcmtresult({
                                assessmentTaskId: child.assessmentTaskId,
                                definitionId: child.assessmentIndicatorDefinitionId,
                                comment: '',
                                result: "Non-compliant",
                                checkboxValue: child.checkboxValue
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