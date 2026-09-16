/**********************************************************************************************
* @Author:      Accenture
* @Date:        15 Sep 2026
* @Description: Reusable service for creating DocumentGenerationProcess requests
*                (Type = GenerateAndConvert) against any PHOCS DocumentTemplate. Callers only
*                need to pass the template's Name and a JSON string of the token data to merge
*                into it, so any PHOCS document (invoices, notices, etc.) can reuse the same
*                submission logic.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                15 Sep -  EHIS-910          -  Deepak      -  Initial version
                15 Sep -  EHIS-910          -  Deepak      -  added a 4-argument generateDocument overload accepting an explicit documentTitle
***********************************************************************************************/
public with sharing class PHOCSDocumentGenerationService {

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: Creates and inserts a DocumentGenerationProcess request (Type = GenerateAndConvert)
*                  for the named DocumentTemplate, merging in the supplied JSON token data and
*                  linking the generated output to a parent record via ReferenceObject. The
*                  generated document is titled after the template's own Name - use the
*                  4-argument overload to supply a different title.
* @param templateName Name of the DocumentTemplate to generate against (e.g. 'PHOCSInvoiceTemplate').
* @param tokenDataJson JSON string of merge-field data to pass as the request's TokenData.
* @param referenceObjectId Id of the record the generated document should be attached to, or null.
* @return Id the inserted DocumentGenerationProcess record's Id, or null if no matching DocumentTemplate or template ContentVersion was found.
*/
    public static Id generateDocument(String templateName, String tokenDataJson, Id referenceObjectId) {
        return generateDocument(templateName, tokenDataJson, referenceObjectId, templateName);
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: Creates and inserts a DocumentGenerationProcess request (Type = GenerateAndConvert)
*                  for the named DocumentTemplate, merging in the supplied JSON token data,
*                  linking the generated output to a parent record via ReferenceObject, and
*                  titling the generated document with the supplied documentTitle.
* @param templateName Name of the DocumentTemplate to generate against (e.g. 'PHOCSInvoiceTemplate').
* @param tokenDataJson JSON string of merge-field data to pass as the request's TokenData.
* @param referenceObjectId Id of the record the generated document should be attached to, or null.
* @param documentTitle Title to give the generated document/attachment.
* @return Id the inserted DocumentGenerationProcess record's Id, or null if no matching DocumentTemplate or template ContentVersion was found.
*/
    public static Id generateDocument(String templateName, String tokenDataJson, Id referenceObjectId, String documentTitle) {
        List<DocumentTemplate> docTemplateList = [SELECT Id, Name FROM DocumentTemplate WHERE Name = :templateName LIMIT 1];
        if (docTemplateList.isEmpty()) {
            return null;
        }

        List<DocumentTemplateContentDoc> templateContentDocs = [SELECT Id, ContentDocumentId FROM DocumentTemplateContentDoc WHERE ContentDocument.Title LIKE :(templateName + '%') ORDER BY CreatedDate DESC LIMIT 1];
        if (templateContentDocs.isEmpty()) {
            return null;
        }

        List<ContentVersion> templateContentVersions = [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :templateContentDocs[0].ContentDocumentId ORDER BY CreatedDate DESC LIMIT 1];
        if (templateContentVersions.isEmpty()) {
            return null;
        }

        String requestText = JSON.serialize(new Map<String, Object>{
            'templateContentVersionId' => templateContentVersions[0].Id,
            'title' => documentTitle,
            'keepIntermediate' => false
        });

        DocumentGenerationProcess request = new DocumentGenerationProcess();
        request.Type = 'GenerateAndConvert';
        request.TokenData = tokenDataJson;
        request.RequestText = requestText;
        request.ReferenceObject = referenceObjectId;
        request.DocGenApiVersionType = 'Advanced';
        request.DocumentTemplateId = docTemplateList[0].Id;
        insert request;

        return request.Id;
    }
}