/**********************************************************************************************
* @Author:Accenture_ALR Dev Team   
* @Date:       
* @Description: The purpose of this Class is to have the methods related to BusinessLicenseApplication trigger
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description] 
                           ALR-553             Keerthana          Renewal Unit Fee  and Late Fee Status in RegulatoryTrxnFee changes according to the application Status and Late fee Status in BLA
***********************************************************************************************/


public with sharing class BusinessLicenseApplicationHelper {
    public static void updateFeeStatus(List<BusinessLicenseApplication> applications) {
        try {
            Set<Id> appIds = new Set<Id>();
            for (BusinessLicenseApplication app : applications) {
                appIds.add(app.Id);
            }
            
            List<RegulatoryTrxnFee> relatedFees = [SELECT Id, ParentRecordId, FeeType__c, Status 
                                                    FROM RegulatoryTrxnFee 
                                                    WHERE ParentRecordId IN :appIds];
            
            List<RegulatoryTrxnFee> feesToUpdate = new List<RegulatoryTrxnFee>();
            for (RegulatoryTrxnFee fee : relatedFees) {
                for (BusinessLicenseApplication app : applications) {
                    if ((app.Status == 'Cancelled' && fee.FeeType__c == 'Renewal Unit Fee') ||
                        (app.Late_Fee_Status__c == 'Cancelled' && fee.FeeType__c == 'Late Fee')) {
                        feesToUpdate.add(fee);
                        break; 
                    }
                }
            }

            if (!feesToUpdate.isEmpty()) {
                for (RegulatoryTrxnFee fee : feesToUpdate) {
                    fee.Status = 'Canceled';
                }
                update feesToUpdate;
            }
        } catch(Exception e) {
             System.debug('An error occurred: ' + e.getMessage());
        }
    }
}