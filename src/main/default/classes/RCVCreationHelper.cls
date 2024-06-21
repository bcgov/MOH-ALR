/**
* @Name              : RCVCreationHelper
* @Description       : Helper class for Regulatory Code Violation Records Creation(try catch is not possible as we are inserting 2 different records)
* @Author            : Anilkumar (Accenture)
* @StoryNo           : ALR-1291 & ALR-1173
**/

public with sharing class RCVCreationHelper {
    public static String className = 'RCVCreationHelper';
    Public static void createRegulatoryCodeViolations(Id VisitId){
        Set<Id> taskIds = new Set<Id>();
        Set<Id>inspasesmntindIds = new Set<Id>();
        Set<Id> asesmntinddefIds = new Set<Id>();
        Set<Id> rcaiIds 	= new Set<Id>(); 
        List<InspectionAssessmentInd> inspasmntind = new List<InspectionAssessmentInd>();
        List<RegulatoryCodeAssessmentInd> regcdassind = new List<RegulatoryCodeAssessmentInd>();
        for(AssessmentTask asesmntsk  : [Select Id,ParentId From AssessmentTask
                                         Where ParentId = :visitId WITH SECURITY_ENFORCED]){
                                             taskIds.add(asesmntsk.Id);
                                         }
        If(!taskIds.isEmpty()){
            for(InspectionAssessmentInd inspasesmntind : [Select Id,AssessmentTaskId,AssessmentIndDefinitionId,TextFieldResponse,Result
                                                          From InspectionAssessmentInd
                                                          Where Result =:BCMOH_Constants.resultt
                                                          AND TextFieldResponse !=:BCMOH_Constants.nulltest
                                                          AND AssessmentTaskId IN :taskIds WITH SECURITY_ENFORCED ]){
                                                              inspasesmntindIds.add(inspasesmntind.Id);
                                                              asesmntinddefIds.add(inspasesmntind.AssessmentIndDefinitionId);
                                                          }
        }
        if(!asesmntinddefIds.isEmpty()){
            for(RegulatoryCodeAssessmentInd regcodasesmntInd : [Select Id,AssessmentIndDefinitionId, Name, RegulatoryCodeId
                                                                From RegulatoryCodeAssessmentInd
                                                                Where AssessmentIndDefinitionId IN :asesmntinddefIds WITH SECURITY_ENFORCED ]){
                                                                    rcaiIds.add(regcodasesmntInd.Id); 
                                                                }
        } 
        if(!rcaiIds.isEmpty()){
            inspasmntind = [Select Id,AssessmentTaskId,AssessmentIndDefinitionId,TextFieldResponse,Result
                                                 From InspectionAssessmentInd
                                                 Where Result =:BCMOH_Constants.resultt
                                                 AND TextFieldResponse !=:BCMOH_Constants.nulltest
                                                 AND AssessmentTaskId IN :taskIds WITH SECURITY_ENFORCED
                                                 order by AssessmentIndDefinitionId];
            regcdassind =[Select Id,AssessmentIndDefinitionId, Name, RegulatoryCodeId
                                 From RegulatoryCodeAssessmentInd
                                 Where AssessmentIndDefinitionId IN :asesmntinddefIds WITH SECURITY_ENFORCED
                                 order by AssessmentIndDefinitionId];
            List<RegulatoryCodeViolation> regulatoryCodeViolationsToCreate = new List<RegulatoryCodeViolation>();           
            for(InspectionAssessmentInd insai : inspasmntind ){               
                for(RegulatoryCodeAssessmentInd rcai : regcdassind){
                    if(insai.AssessmentIndDefinitionId == rcai.AssessmentIndDefinitionId){
                        RegulatoryCodeViolation violation = new RegulatoryCodeViolation();         
                        violation.InspectionId = visitId;
                        violation.InspectionAssmntIndId = insai.Id; // Assign InspectionAssessmentInd Id
                        violation.RegulatoryCodeId = rcai.RegulatoryCodeId;
                        violation.DateCreated = DateTime.now();
                        violation.Description = insai.TextFieldResponse; // Assigning text field response to Description
                        regulatoryCodeViolationsToCreate.add(violation);
                    }
                }
                
            }
            database.insert(regulatoryCodeViolationsToCreate);
            List<ContentDocumentLink> ContentDocumentLinkToCreate = new List<ContentDocumentLink>();
            List<ContentDocumentLink> cntdoclinkId = [Select Id,ContentDocumentId, LinkedEntityId
                                                  From ContentDocumentLink
                                                  Where LinkedEntityId IN :inspasesmntindIds WITH SECURITY_ENFORCED ];
            if(!cntdoclinkId.isEmpty()){
                for(RegulatoryCodeViolation rcv :regulatoryCodeViolationsToCreate){
                    for(ContentDocumentLink cdl : cntdoclinkId){
                        if(cdl.LinkedEntityId == rcv.InspectionAssmntIndId){
                            ContentDocumentLink doclink = New ContentDocumentLink();
                            doclink.ContentDocumentId = cdl.ContentDocumentId;
                            doclink.LinkedEntityId = rcv.Id;
                            ContentDocumentLinkToCreate.add(doclink);
                        }
                    }
                }
                database.insert(ContentDocumentLinkToCreate);
            }
        }
        
    }
}