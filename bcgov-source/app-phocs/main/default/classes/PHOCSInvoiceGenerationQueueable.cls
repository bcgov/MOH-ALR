/**********************************************************************************************
* @Author:      Accenture
* @Date:        15 Sep 2026
* @Description: Queueable that generates the invoice PDF (via PHOCSInvoiceDetailsService) for a
*                batch of RegulatoryTrxnFee Ids asynchronously, so the calling transaction
*                (e.g. the RegulatoryTrxnFee trigger) isn't blocked by the SOQL/DML work
*                PHOCSInvoiceDetailsService performs per record.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                15 Sep -  EHIS-910          -  Deepak      -  Initial version
***********************************************************************************************/
public with sharing class PHOCSInvoiceGenerationQueueable implements Queueable {
    private List<Id> regulatoryTrxnFeeIds;

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: Constructs the job with the RegulatoryTrxnFee Ids to generate invoice PDFs for.
* @param regulatoryTrxnFeeIds Ids of the RegulatoryTrxnFee records to generate invoice PDFs for.
*/
    public PHOCSInvoiceGenerationQueueable(List<Id> regulatoryTrxnFeeIds) {
        this.regulatoryTrxnFeeIds = regulatoryTrxnFeeIds;
    }

    /**
* @author: Deepak
* @date: 15 Sep 2026
* @description: Generates the invoice PDF for each supplied RegulatoryTrxnFee Id via
*                  PHOCSInvoiceDetailsService.generateInvoicePdf.
* @param context the Queueable execution context.
*/
    public void execute(QueueableContext context) {
        PHOCSInvoiceDetailsService.generateInvoicePdf(regulatoryTrxnFeeIds);
    }
}