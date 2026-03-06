trigger PHOCSInspectionAfterUpdate on Visit (after update) {
    
    Set<Id> compltedinspection = new Set<Id>();
            for(Visit insp : Trigger.New){
                Visit oldinsp = Trigger.oldMap.get(insp.Id);
                    if(insp.Status == 'Completed' && oldinsp.Status != 'Completed'
                    ) {
                        compltedinspection.add(insp.Id); 
                    }
            
    }
    if(!compltedinspection.isEmpty()){
        PHOCSInspectionAssessmentIndBatch.delInsInd(compltedinspection);
    }
}