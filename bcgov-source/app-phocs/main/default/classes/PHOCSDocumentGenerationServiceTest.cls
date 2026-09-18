/**********************************************************************************************
* @Author:      Accenture
* @Date:        15 Sep 2026
* @Description: The purpose of this class is to cover code coverage of PHOCSDocumentGenerationService.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                15 Sep -  EHIS-910          -  Deepak      -  Initial Test Methods
***********************************************************************************************/
@isTest
public class PHOCSDocumentGenerationServiceTest {

    private static final String TEMPLATE_NAME = 'PHOCSInvoiceTemplate';

    @testSetup
    static void setupTestData() {
        DocumentTemplate testDocumentTemplate = new DocumentTemplate(
            Name = TEMPLATE_NAME,
            Type = 'MicrosoftWord',
            TokenMappingType = 'JSON',
            TokenMappingMethodType = 'OmniDataTransform'
        );
        insert testDocumentTemplate;

        ContentVersion templateContentVersion = new ContentVersion(
            Title = TEMPLATE_NAME,
            PathOnClient = TEMPLATE_NAME + '.docx',
            VersionData = Blob.valueOf('Test template content')
        );
        insert templateContentVersion;
        templateContentVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :templateContentVersion.Id LIMIT 1];

        DocumentTemplateContentDoc templateContentDocLink = new DocumentTemplateContentDoc(
            Name = TEMPLATE_NAME,
            DocumentTemplateId = testDocumentTemplate.Id,
            ContentDocumentId = templateContentVersion.ContentDocumentId
        );
        insert templateContentDocLink;
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of generateDocument when a
*                  matching DocumentTemplate exists and no referenceObjectId is supplied.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateDocument_CreatesRequest_WithNullReferenceObject_Test() {
        String tokenDataJson = '{"amount":100}';
        ContentVersion templateContentVersion = [SELECT Id FROM ContentVersion WHERE Title = :TEMPLATE_NAME LIMIT 1];

        Test.startTest();
        Id resultId = PHOCSDocumentGenerationService.generateDocument(TEMPLATE_NAME, tokenDataJson, null);
        Test.stopTest();

        Assert.isNotNull(resultId, 'A DocumentGenerationProcess Id should be returned when the template exists.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id, Type, ReferenceObject, TokenData, RequestText, DocGenApiVersionType, DocumentTemplateId FROM DocumentGenerationProcess];
        Assert.areEqual(1, generatedProcesses.size(), 'One DocumentGenerationProcess record should be created.');
        Assert.areEqual('GenerateAndConvert', generatedProcesses[0].Type, 'Type should be GenerateAndConvert.');
        Assert.areEqual(tokenDataJson, generatedProcesses[0].TokenData, 'TokenData should match the input JSON.');
        Assert.areEqual('Advanced', generatedProcesses[0].DocGenApiVersionType, 'DocGenApiVersionType should be Advanced.');
        Assert.isNull(generatedProcesses[0].ReferenceObject, 'ReferenceObject should be null on the two-argument overload.');
        Assert.isTrue(generatedProcesses[0].RequestText.contains(templateContentVersion.Id), 'RequestText should carry the resolved templateContentVersionId.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of generateDocument,
*                  verifying ReferenceObject is set from the supplied Id.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateDocument_ThreeArgOverload_SetsReferenceObject_Test() {
        Account referenceAccount = new Account(Name = 'Reference Account For Test');
        insert referenceAccount;

        String tokenDataJson = '{"amount":250}';

        Test.startTest();
        Id resultId = PHOCSDocumentGenerationService.generateDocument(TEMPLATE_NAME, tokenDataJson, referenceAccount.Id);
        Test.stopTest();

        Assert.isNotNull(resultId, 'A DocumentGenerationProcess Id should be returned when the template exists.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id, Type, ReferenceObject, TokenData FROM DocumentGenerationProcess];
        Assert.areEqual(1, generatedProcesses.size(), 'One DocumentGenerationProcess record should be created.');
        Assert.areEqual(referenceAccount.Id, generatedProcesses[0].ReferenceObject, 'ReferenceObject should match the supplied Id.');
        Assert.areEqual(tokenDataJson, generatedProcesses[0].TokenData, 'TokenData should match the input JSON.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the not-found path,
*                  verifying no DocumentGenerationProcess is created when the template name
*                  does not match an existing DocumentTemplate.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateDocument_ReturnsNull_WhenTemplateNotFound_Test() {
        Test.startTest();
        Id resultId = PHOCSDocumentGenerationService.generateDocument('NonExistentTemplateName', '{}', null);
        Test.stopTest();

        Assert.isNull(resultId, 'A null Id should be returned when no matching DocumentTemplate exists.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess record should be created when the template is not found.');
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: The purpose of this method is to cover Testcoverage of the case where the
*                  DocumentTemplate exists but has no matching DocumentTemplateContentDoc link
*                  to resolve a templateContentVersionId from.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    public static void generateDocument_ReturnsNull_WhenNoMatchingContentVersion_Test() {
        DocumentTemplate templateWithNoFile = new DocumentTemplate(
            Name = 'PHOCSTemplateWithNoFile',
            Type = 'MicrosoftWord',
            TokenMappingType = 'JSON',
            TokenMappingMethodType = 'OmniDataTransform'
        );
        insert templateWithNoFile;

        Test.startTest();
        Id resultId = PHOCSDocumentGenerationService.generateDocument('PHOCSTemplateWithNoFile', '{}', null);
        Test.stopTest();

        Assert.isNull(resultId, 'A null Id should be returned when the template has no matching ContentVersion.');

        List<DocumentGenerationProcess> generatedProcesses = [SELECT Id FROM DocumentGenerationProcess];
        Assert.areEqual(0, generatedProcesses.size(), 'No DocumentGenerationProcess record should be created without a resolvable template file.');
    }
}