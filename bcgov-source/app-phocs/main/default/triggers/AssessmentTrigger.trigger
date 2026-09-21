/**********************************************************************************************
* @Author:      Accenture
* @Date:        03 Sep 2026
* @Description: AssessmentTrigger for different triggering context
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                03 Sep -  EHIS-5027         -  Deepak      -  Initial trigger for RAT-driven inspection generation
***********************************************************************************************/
trigger AssessmentTrigger on Assessment (after insert) {
    AssessmentTriggerHandler.afterInsert(Trigger.new);
}