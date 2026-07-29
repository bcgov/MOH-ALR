/**********************************************************************************************
* @Author:      Accenture 
* @Date:        26 Jun 2026
* @Description: The purpose of this class is to sent exception email into a Queueable so it executes in a separate transaction.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                26 Jun -  PHOCS-295/589     -  Accenture   -  BCCDC - Water lab requisition
***********************************************************************************************/
public with sharing class PHOCSLabIntExceptionEmailQueueable implements Queueable {
    public static final String CLASS_NAME = 'PHOCSLabIntExceptionEmailQueueable';
    public static final String REQUISITION_SERVICE = 'PHOCSRequisitionService';
    public static final String LAB_RESULTS_SERVICE = 'PHOCSLabResults';
    public static Boolean throwTestException = false;

    private String className;
    private String exceptionMessage;
    private String exceptionType;

    public PHOCSLabIntExceptionEmailQueueable(String className, String exceptionMessage, String exceptionType) {
        this.className = className;
        this.exceptionMessage = exceptionMessage;
        this.exceptionType = exceptionType;
    }

/**
* @author: Deepak
* @date: 27 Jul 2026
* @description: execute method for QueueableContext.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public void execute(QueueableContext context) {
        try {
            if (Test.isRunningTest() && throwTestException) {
                throw new DmlException('Test Exception');
            }
            List<String> toAddresses = new List<String>();
            String recipientLabel = System.Label.PHOCS_LBL_BCCDC_Requisition_Email_To;

            if (String.isBlank(recipientLabel)) {
                return;
            }

            for (String address : recipientLabel.split(',')) {
                if (String.isNotBlank(address)) {
                    toAddresses.add(address.trim());
                }
            }

            if (toAddresses.isEmpty()) {
                return;
            }

            String subject = getEnvironmentName() + ': ' + System.Label.PHOCS_LBL_BCCDC_LabResults_Exception_Email_Subject;
            String body = className == REQUISITION_SERVICE ? System.Label.PHOCS_LBL_BCCDC_LabRequisitions_Exception_Email_Body : System.Label.PHOCS_LBL_BCCDC_LabResults_Exception_Email_Body;

            body = body.replace('{0}', className);
            body = body.replace('{1}', exceptionMessage);
            body = body.replace('{2}', exceptionType);
            body = body.replace('{3}', System.now().format());
            body = body.replace('{4}', getEnvironmentName());

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(toAddresses);
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSaveAsActivity(false);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });

        } catch (Exception ex) {
            LogService.logAndPublish('PHOCSLabResultsExceptionEmailQueueable', 'execute', exceptionMessage, ex);
        }
    }
    
/**
* @author: Deepak
* @date: 27 Jul 2026
* @description: Returns the PHOCS environment name (e.g. PHOCS - Dev2 or PHOCS - Prod).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String getEnvironmentName() {
        try {
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            
            if (baseUrl.contains('.sandbox.')) {
                String sandboxName = baseUrl.substringBetween('--', '.sandbox.');
                
                if (String.isNotBlank(sandboxName)) {
                     return 'PHOCS-' + sandboxName.toUpperCase();
                }
            }
            
            return 'PHOCS-Prod';
            
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'getEnvironmentName', null, ex);
            return 'PHOCS-Prod';
        }
    }
}