/**
* @Name              : ServerSideDocumentGenerationController
* @Description       : class to generate documents and attach to record
					 : referenced in RenewalManagementControllerBatch, TestClassCoverage - RenewalManagementControllerTest
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
/*
Updatd description : added new method for late fee document generation and attach to BLA record. 
referenced in LateFeeManagementControllerBatch as part of ALR-997
Done by : Komal Gupta
*/
/*modified "fetchFeeRelatedInformation" method as part of ALR-1107*/
   public with sharing class ServerSideDocumentGenerationController {
   Public Static Map<String, String> tempNameStatusMsgMap = new Map<String, String>();//success or error details for each template
   Public Static Map<Id, Account> parentAccMap = new Map<Id, Account>();
  
   Public Static String className = 'ServerSideDocumentGenerationController';
   Public Static Map<String, String> docNameWithTitleMap = new Map<String, String>();//doc name with title
   Public Static Map<String, DocumentTemplateContentDoc> docTempContentMap = new Map<String, DocumentTemplateContentDoc>();
   Public Static Map<String, Object> documentMappingData = new Map<String, Object>();//to stringify req text for doc gen process
   Public Static Map<String, Object> documentMappingData1 = new Map<String, Object>();//to stringify token data for doc gen process
   Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
   Public Static Map<Id, Account> accMap = new Map<Id, Account>();
   Public Static Map<Id, Account> accMap1 = new Map<Id, Account>();
   Public Static Map<Id, RegulatoryTrxnFee> transFeeMap1 = new Map<Id, RegulatoryTrxnFee>();
   Public Static Map<Id, RegulatoryTrxnFeeItem> transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>();
   Public Static List<DocumentGenerationProcess> docGenList = new List<DocumentGenerationProcess>();//for DML Docs
   
   Public Static Map<Id, String> blaErrMap = new Map<Id, String>();//Update status to error with errmsg
   Public Static Boolean reqdDataPresent = true;
   Public Static List<BusinessLicenseApplication> blaErrUpdateList = new List<BusinessLicenseApplication>();
   
   Public Static Id contentVersionId1 = NULL;
    
     Public static void startDocGenProcess(List<Account> accData, Map<Id, BusinessLicenseApplication> blaMap1,
                                         Map<Id, RegulatoryTrxnFee> transFeeMap, List<RegulatoryTrxnFeeItem> transFeeItemList) {
        try {
            blaMap = blaMap1;//Note : blaMap - Map of Account Id vs bla Record
            accMap = new Map<Id, Account>(accData);//acc
            transFeeMap1 = transFeeMap;//fee
            transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>(transFeeItemList);//fee item
           
            Map<Id, RegulatoryTrxnFee> transFeeMap2 = new Map<Id, RegulatoryTrxnFee>(transFeeMap.values());//to fetch ids of reg trans recs
            for(RegulatoryTrxnFee regFeeRec : [SELECT Id, Name, TotalFeeAmount, recordTypeId, AccountId, ParentRecordId, FeeType__c,
                                                Status, DueDate FROM RegulatoryTrxnFee WHERE Id IN: transFeeMap2.keyset() LIMIT 50000]) {
                transFeeMap1.put(regFeeRec.AccountId, regFeeRec);
            }
            
            docNameWithTitleMap = BCMOH_UtilityClass.getDocNameTitle(BCMOH_Constants.templatePurpose);
            docTempContentMap = BCMOH_UtilityClass.getDocTempContentMap(new List<String>(docNameWithTitleMap.keySet()));
            if(Test.isRunningTest()) {
                contentVersionId1 = [SELECT Id FROM ContentVersion LIMIT 1].Id;
            }
            
            for (Id accId : blaMap.keySet()) {
            reqdDataPresent = true;
            documentMappingData.clear();
            documentMappingData1.clear();
            for (String tempName : docNameWithTitleMap.keyset()) {
                if (reqdDataPresent) {
                    DocumentGenerationProcess docGenRec = createDocumentGenerationProcessRequest(accId, tempName);
                    if (docGenRec.TokenData != NULL) {
                        docGenList.add(docGenRec);
                    }
                }
            }

            if (docNameWithTitleMap.isEmpty()) {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.documentNotFetched);
            }
        }
          
        if (!docGenList.isEmpty()) {
            Database.Insert(docGenList, false);
        }

        if (!blaErrMap.isEmpty()) {
            blaErrUpdateList = BCMOH_UtilityClass.updateBlaStatus(blaErrMap, BCMOH_Constants.errorBlaStatus);
            if (!blaErrUpdateList.isEmpty() && BusinessLicenseApplication.sObjectType.getDescribe().isUpdateable()) {
                Database.Update(blaErrUpdateList, false);
            }
        }
       }
        catch(exception ex) {
           LogService.logAndPublish(className, 'startDocGenProcess', '', ex);
        }
    }
    
    public static DocumentGenerationProcess createDocumentGenerationProcessRequest(Id accId, String tempName) {
        String type = 'GenerateAndConvert';//get from metadata
        String docGenType = 'Advanced';
        DocumentGenerationProcess docGenRec = new DocumentGenerationProcess();
        String tokenData = '';
        try {
        Id referenceId = blaMap.get(accId).Id; // null check not needed coz acc id comes from bla map
        String requestText = prepareRequestText(accId, tempName);
            if (requestText != NULL) {
            tokenData = prepareTokenData(accId);
             if (referenceId != NULL && tokenData != NULL) {
                docGenRec = BCMOH_UtilityClass.getDocGenProcRec(type, requestText, referenceId, tokenData, docGenType);
            }
        }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'createDocumentGenerationProcessRequest', '', ex);
        }
        return docGenRec;
    }
   
    public static String prepareRequestText(Id accId, String tempName) {
        String requestText = '';
        String contentDocumentTitle = '';
        Id contentVersionId = NULL;
        try {
            //1) Get doc title
            contentDocumentTitle = docNameWithTitleMap.get(tempName);//null check not needed as attribute is passed from for looping of map
            if(contentDocumentTitle.contains(BCMOH_Constants.invoiceIdMerge) && transFeeMap1.get(accId) == NULL) {
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFee);
                return NULL;//go to next iteration
            }
            else if(contentDocumentTitle.contains(BCMOH_Constants.invoiceIdMerge) && transFeeMap1.get(accId) != NULL) {
                contentDocumentTitle = contentDocumentTitle.replace(BCMOH_Constants.invoiceIdMerge, transFeeMap1.get(accId).Name);
                }else{
           }
            
            if(Test.isRunningTest()) {
                contentVersionId = contentVersionId1;
            }
            else if(docTempContentMap.get(tempName) != NULL && docTempContentMap.get(tempName).LatestContentVersionId != NULL) {
                contentVersionId = docTempContentMap.get(tempName).LatestContentVersionId;
            }
            else {
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.LatestContentVersionId);
                return NULL;
            }
           
            if(contentVersionId != NULL && contentDocumentTitle != NULL) {
                documentMappingData.put(BCMOH_Constants.templateContentVersionId, contentVersionId);
                documentMappingData.put(BCMOH_Constants.docTitle, contentDocumentTitle);
                documentMappingData.put(BCMOH_Constants.keepIntermediate, false);
                requestText = BCMOH_UtilityClass.mapToJson(documentMappingData);
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'prepareRequestText', '', ex);
        }
        return requestText;
    }
    
    public static String prepareTokenData(Id accId) {
        String tokenData = '';
        try {
           
            Account accRec = accMap.get(accId);//null check not needed as blaMap acc comes from accmap
            documentMappingData1.put('ResidenceName', accRec.Name);
            documentMappingData1.put('ResID', accRec.RegId__c);
            documentMappingData1.put('LicenseType', accRec.LicenseType__r.Name);//TO DO: add if for null check?
            documentMappingData1.put('ResidencePhoneNumber', accRec.Phone);
            documentMappingData1.put('ResidenceFax', accRec.Fax);
            
            if(accRec.ParentId != NULL) {
                documentMappingData1.put('RegistrantName', accRec.Parent.Name);          
                documentMappingData1.put('RegistrantPhone', accRec.Parent.Phone);
                
                if(accRec.Parent.BillingAddress != NULL) {
                    Address addrParent = accRec.Parent.BillingAddress;
                    String addressParent = addrParent.Street+', '+ addrParent.City+', '+ addrParent.State+', '+addrParent.PostalCode+', '+ addrParent.Country;
                    if(addressParent.contains('null,')) {
                        addressParent = addressParent.replace('null,','');
                    }
                    documentMappingData1.put('RegistrantAddress', addressParent);
                    documentMappingData1.put('RegistrantBillingAddress', addressParent);
                }
                else {
                    reqdDataPresent = false;
                    blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountParentAddr);
                    return NULL;
                }
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountParent);
                return NULL;
            }
           
            if(reqdDataPresent && accRec.AssociatedLocations != NULL && accRec.AssociatedLocations.size() > 0 
               && accRec.AssociatedLocations[0].Location.VisitorAddress.Address != NULL) {
                    AssociatedLocation asLoc = accRec.AssociatedLocations[0];//TO DO: reduce to single line
                    Address accAddress = asLoc.Location.VisitorAddress.Address;
                    String accAddr = accAddress.Street+', '+ accAddress.City+', '+ accAddress.State+', '+accAddress.PostalCode+', '+ accAddress.Country;
                    if(accAddr.contains('null,')) {
                       accAddr = accAddr.replace('null,','');
                    }
                    documentMappingData1.put('ResidenceAddress', accAddr);
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountAddr);
                return NULL;
            }
            
            if(reqdDataPresent && accRec.AccountBusinessLicenses__r != NULL && accRec.AccountBusinessLicenses__r.size() > 0 &&
               accRec.AccountBusinessLicenses__r[0].RegistrationCertificate__c != NULL) {
                BusinessLicense blRec = accRec.AccountBusinessLicenses__r[0];
                documentMappingData1.put('CertificateId', blRec.RegistrationCertificate__c);
            } 
            else {
               reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.blCertId);
                return NULL;
            }
            
            if(reqdDataPresent && accRec.AccountContactRelations != NULL && accRec.AccountContactRelations.size() > 0) {
            	AccountContactRelation acRel = accRec.AccountContactRelations[0];
                documentMappingData1.put('Name', acRel.Contact.Name);
                documentMappingData1.put('ContactPhone', acRel.Contact.Phone);
                documentMappingData1.put('ContactEmail', acRel.Contact.Email);
                documentMappingData1.put('PrimaryRole', acRel.Roles);
                documentMappingData1.put('ContactCell', acRel.Contact.MobilePhone);
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.relatedContacts);
                return NULL;
            }
            
            if(reqdDataPresent && transFeeMap1.get(accId) != NULL) {
                reqdDataPresent = fetchFeeRelatedInformation(accId);
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFee);
                return NULL;
            }
            
             if(reqdDataPresent) {
                documentMappingData1.put('InvoiceCreatedDate', Date.Today());//INVOICE template
            }
            
            if(reqdDataPresent) {
                tokenData = BCMOH_UtilityClass.mapToJson(documentMappingData1);
            }
            else {
                tokenData = NULL;
            }
         }
        catch(exception ex) {
            LogService.logAndPublish(className, 'prepareTokenData', '', ex);
        }
        return tokenData;
    }
    
    private static Boolean fetchFeeRelatedInformation(Id accId) {
        Boolean hasFeeItem = false;
        Decimal Sum1 = 0;
        Decimal QuantitySum1 = 0;
        Decimal FeeSum1 = 0;
        
        Decimal QuantitySum2 = 0;
        Decimal Sum2 = 0;
        Decimal FeeSum2 = 0;
        
        Decimal QuantitySum3 = 0;
        Decimal Sum3 = 0;
        Decimal FeeSum3 = 0;
        integer count = 0;
        try {
            RegulatoryTrxnFee feeRec = transFeeMap1.get(accId);
            documentMappingData1.put('InvoiceId', feeRec.Name);//ALR-775
            documentMappingData1.put('TotalFeeAmount', '$'+feeRec.TotalFeeAmount);//ALR-775            
            
            for(RegulatoryTrxnFeeItem transRec : transFeeItemMap1.values()) {
                
                 if(transRec.RegulatoryTrxnFeeId == feeRec.Id && BCMOH_Constants.allALUnitTypes.contains(transRec.Name) &&
                   transRec.Quantity__c != NULL && transRec.Quantity__c > 0) {
                   count++;
					
                    if(transRec.Name == 'Public') {
                        hasFeeItem = true;
						if(count ==1){
							documentMappingData1.put('Unit1', BCMOH_Constants.unitsPublic);
							Sum1 = transRec.Amount__c;
							QuantitySum1 += transRec.Quantity__c;
							FeeSum1 +=  transRec.FeeAmount;
						}						
                             
                    }
                    else if(transRec.Name == 'Private') {
                        hasFeeItem = true;
						if(count ==1 ){
							documentMappingData1.put('Unit1', BCMOH_Constants.unitsPrivate);
							Sum1 = transRec.Amount__c;
							QuantitySum1 += transRec.Quantity__c;
							FeeSum1 +=  transRec.FeeAmount;
						}
						else{
							documentMappingData1.put('Unit2', BCMOH_Constants.unitsPrivate);
							Sum2 = transRec.Amount__c;
							QuantitySum2 += transRec.Quantity__c;
							FeeSum2 +=  transRec.FeeAmount; 
						}						
                    }
                    else if(transRec.Name == 'Per Diem') {
                        hasFeeItem = true;
						if(count ==1 ){
							documentMappingData1.put('Unit1', BCMOH_Constants.unitsPerDiem);
							Sum1 = transRec.Amount__c;
							QuantitySum1 += transRec.Quantity__c;
							FeeSum1 +=  transRec.FeeAmount;
						}
						else if (count ==2 ){
							documentMappingData1.put('Unit2', BCMOH_Constants.unitsPerDiem);
							Sum2 = transRec.Amount__c;
							QuantitySum2 += transRec.Quantity__c;
							FeeSum2 +=  transRec.FeeAmount; 
						}						
                        else{
							documentMappingData1.put('Unit3', BCMOH_Constants.unitsPerDiem);
							Sum3 = transRec.Amount__c;
							QuantitySum3 += transRec.Quantity__c;
							FeeSum3 +=  transRec.FeeAmount; 
						}              
                    }
                }
            }
            
            if(!hasFeeItem) {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFeeItem);
            }
            else {
                if(documentMappingData1.keySet().contains('Unit1')) {
                    documentMappingData1.put('QuantitySum1', QuantitySum1);
                    documentMappingData1.put('Sum1', '$'+Sum1);
                    FeeSum1 = FeeSum1.setscale(2);//ALR-805 - setting decimal points to 2
                    documentMappingData1.put('FeeSum1', '$'+FeeSum1);
                }
                if(documentMappingData1.keySet().contains('Unit2')) {
                    documentMappingData1.put('QuantitySum2', QuantitySum2);
                    documentMappingData1.put('Sum2', '$'+Sum2);
                    FeeSum2 = FeeSum2.setscale(2);//ALR-805 - setting decimal points to 2
                    documentMappingData1.put('FeeSum2', '$'+FeeSum2);
                }
                if(documentMappingData1.keySet().contains('Unit3')) {
                    documentMappingData1.put('QuantitySum3', QuantitySum3);
                    documentMappingData1.put('Sum3', '$'+Sum3);
                    FeeSum3 = FeeSum3.setscale(2);//ALR-805 - setting decimal points to 2
                    documentMappingData1.put('FeeSum3', '$'+FeeSum3);
                }
            }
        }
        catch(exception ex) {
           LogService.logAndPublish(className, 'fetchFeeRelatedInformation', '', ex);
        }
        return reqdDataPresent;
    }


    Public static void startDocGenProcessLateFee(Map<Id, Account> accmap, Map<Id, BusinessLicenseApplication> blaMap1,
                                         Map<Id, RegulatoryTrxnFee> transFeeMap, List<RegulatoryTrxnFeeItem> transFeeItemList) {
        try {
            
            blaMap = blaMap1;
            accMap1 = accmap;
            transFeeMap1 = transFeeMap;
            transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>(transFeeItemList);

            Map<Id, RegulatoryTrxnFee> transFeeMap2 = new Map<Id, RegulatoryTrxnFee>(transFeeMap1.values());//to fetch ids of reg trans recs
            for(RegulatoryTrxnFee regFeeRec : [SELECT Id, Name, TotalFeeAmount, recordTypeId, AccountId, ParentRecordId, FeeType__c,
                                                Status, DueDate FROM RegulatoryTrxnFee WHERE Id IN: transFeeMap2.keyset() LIMIT 50000]) {
                transFeeMap1.put(regFeeRec.AccountId, regFeeRec);
            }
             docNameWithTitleMap = BCMOH_UtilityClass.getDocNameTitleLateFee(BCMOH_Constants.templatePurposeDetails);
            
            docTempContentMap = BCMOH_UtilityClass.getDocTempContentMap(new List<String>(docNameWithTitleMap.keySet()));
            
            if(Test.isRunningTest()) {
                contentVersionId1 = [SELECT Id FROM ContentVersion LIMIT 1].Id;
            }
            for (Id accId : blaMap.keySet()) {
            reqdDataPresent = true;
            documentMappingData.clear();
            documentMappingData1.clear();
            for (String tempName : docNameWithTitleMap.keyset()) {
                if (reqdDataPresent) {
                    DocumentGenerationProcess docGenRec = createDocumentGenerationProcessRequestLateFee(accId, tempName);
                    if (docGenRec.TokenData != NULL) {
                        docGenList.add(docGenRec);
                    }
                }
            }
            if (docNameWithTitleMap.isEmpty()) {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.documentNotFetched);
            }
        }

        if (!docGenList.isEmpty()) {
            Database.Insert(docGenList, false);
        }

        if (!blaErrMap.isEmpty()) {
            blaErrUpdateList = BCMOH_UtilityClass.updateBlaLateFeeStatus(blaErrMap, BCMOH_Constants.errorBlaStatus);
            if (!blaErrUpdateList.isEmpty() && BusinessLicenseApplication.sObjectType.getDescribe().isUpdateable()) {
                Database.Update(blaErrUpdateList, false);
            }
        }
             }
        catch(exception ex) {
            LogService.logAndPublish(className, 'startDocGenProcess', '', ex);
        }
    }

    public static DocumentGenerationProcess createDocumentGenerationProcessRequestLateFee(Id accId, String tempName) {
        String type = 'GenerateAndConvert';
        String docGenType = 'Advanced';
        DocumentGenerationProcess docGenRec = new DocumentGenerationProcess();
        String tokenData = '';
        try {
        Id referenceId = blaMap.get(accId).Id;
        String requestText = prepareRequestTextLateFee(accId, tempName);
        if (requestText != NULL) {
            tokenData = prepareTokenDataLateFee(accId);
            if (referenceId != NULL && tokenData != NULL) {
                docGenRec = BCMOH_UtilityClass.getDocGenProcRec(type, requestText, referenceId, tokenData, docGenType);
            }
        }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'createDocumentGenerationProcessRequest', '', ex);
        }
        return docGenRec;
    }
    
    public static String prepareRequestTextLateFee(Id accId, String tempName) {
        String requestText = '';
        String contentDocumentTitle = '';
        Id contentVersionId = NULL;
        try {
            contentDocumentTitle = docNameWithTitleMap.get(tempName);//null check not needed as attribute is passed from for looping of map
             if(contentDocumentTitle.contains(BCMOH_Constants.invoiceIdMerge) && transFeeMap1.get(accId) == NULL) {
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFee);
                return NULL;
            }
            else if(contentDocumentTitle.contains(BCMOH_Constants.invoiceIdMerge) && transFeeMap1.get(accId) != NULL) {
                contentDocumentTitle = contentDocumentTitle.replace(BCMOH_Constants.invoiceIdMerge, transFeeMap1.get(transFeeMap1.get(accId).AccountId).Name);
             }else{
            }
            
            if(Test.isRunningTest()) {
                contentVersionId = contentVersionId1;
            }
            else if(docTempContentMap.get(tempName) != NULL && docTempContentMap.get(tempName).LatestContentVersionId != NULL) {
                contentVersionId = docTempContentMap.get(tempName).LatestContentVersionId;
            }
            else {
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.LatestContentVersionId);
                return NULL;
            }
            if(contentVersionId != NULL && contentDocumentTitle != NULL) {
                documentMappingData.put(BCMOH_Constants.templateContentVersionId, contentVersionId);
                documentMappingData.put(BCMOH_Constants.docTitle, contentDocumentTitle);
                documentMappingData.put(BCMOH_Constants.keepIntermediate, false);
                requestText = BCMOH_UtilityClass.mapToJson(documentMappingData);
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'prepareRequestText', '', ex);
        }
        return requestText;
    }
    
    public static String prepareTokenDataLateFee(Id accId) {
        String tokenData = '';
        try {
            
            Account accRec = accMap1.get(blaMap.get(accId).AccountId);
            documentMappingData1.put('ResidenceName', accRec.Name);
            documentMappingData1.put('ResID', accRec.RegId__c);
            documentMappingData1.put('LicenseType', accRec.LicenseType__r.Name);
            documentMappingData1.put('ResidencePhoneNumber', accRec.Phone);
            documentMappingData1.put('ResidenceFax', accRec.Fax);
               
            if(accRec.ParentId != NULL) {
                documentMappingData1.put('RegistrantName', accRec.Parent.Name);          
                documentMappingData1.put('RegistrantPhone', accRec.Parent.Phone);

                if(accRec.Parent.BillingAddress != NULL) {
                    Address addrParent = accRec.Parent.BillingAddress;
                    String addressParent = addrParent.Street+', '+ addrParent.City+', '+ addrParent.State+', '+addrParent.PostalCode+', '+ addrParent.Country;
                    if(addressParent.contains('null,')) {
                        addressParent = addressParent.replace('null,','');
                    }
                    documentMappingData1.put('RegistrantAddress', addressParent);
                    documentMappingData1.put('RegistrantBillingAddress', addressParent);
                }
                else {
                    reqdDataPresent = false;
                    blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountParentAddr);
                    return NULL;
                }
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountParent);
                return NULL;
            }

            if(reqdDataPresent && accRec.AssociatedLocations != NULL && accRec.AssociatedLocations.size() > 0 
               && accRec.AssociatedLocations[0].Location.VisitorAddress.Address != NULL) {
                    AssociatedLocation asLoc = accRec.AssociatedLocations[0];//TO DO: reduce to single line
                    Address accAddress = asLoc.Location.VisitorAddress.Address;
                    String accAddr = accAddress.Street+', '+ accAddress.City+', '+ accAddress.State+', '+accAddress.PostalCode+', '+ accAddress.Country;
                    if(accAddr.contains('null,')) {
                       accAddr = accAddr.replace('null,','');
                    }
                    documentMappingData1.put('ResidenceAddress', accAddr);
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountAddr);
                return NULL;
            }
            
            if(reqdDataPresent && accRec.AccountBusinessLicenses__r != NULL && accRec.AccountBusinessLicenses__r.size() > 0 &&
               accRec.AccountBusinessLicenses__r[0].RegistrationCertificate__c != NULL) {
                BusinessLicense blRec = accRec.AccountBusinessLicenses__r[0];
                documentMappingData1.put('CertificateId', blRec.RegistrationCertificate__c);
            } 
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.blCertId);
                return NULL;
            }
            
            if(reqdDataPresent && accRec.AccountContactRelations != NULL && accRec.AccountContactRelations.size() > 0) {
            	AccountContactRelation acRel = accRec.AccountContactRelations[0];
                documentMappingData1.put('Name', acRel.Contact.Name);
                documentMappingData1.put('ContactPhone', acRel.Contact.Phone);
                documentMappingData1.put('ContactEmail', acRel.Contact.Email);
                documentMappingData1.put('PrimaryRole', acRel.Roles);
                documentMappingData1.put('ContactCell', acRel.Contact.MobilePhone);
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.relatedContacts);
                return NULL;
            }
            
            if(reqdDataPresent && transFeeMap1.get(accId) != NULL) {
                reqdDataPresent = fetchFeeRelatedInformationLateFee(accId);
            }
            else {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFee);
                return NULL;
            }

            if(reqdDataPresent) {
                documentMappingData1.put('InvoiceCreatedDate', Date.Today());//INVOICE template
            }

            if(reqdDataPresent) {
                tokenData = BCMOH_UtilityClass.mapToJson(documentMappingData1);
            }
            else {
                tokenData = NULL;
            }
        }
        catch(exception ex) {
           LogService.logAndPublish(className, 'prepareTokenData', '', ex);
        }
        return tokenData;
    }

    private static Boolean fetchFeeRelatedInformationLateFee(Id accId) {
        Boolean hasFeeItem = false;
        
        Decimal lateFeeSum = 0;
        Decimal lateFeeQuantitySum = 0;
        Decimal latefeeFeeSum = 0;
        
        try {
            RegulatoryTrxnFee feeRec = transFeeMap1.get(transFeeMap1.get(accId).AccountId);
            
            documentMappingData1.put('InvoiceId', feeRec.Name);
            documentMappingData1.put('TotalFeeAmount', '$'+feeRec.TotalFeeAmount);          
            
            for(RegulatoryTrxnFeeItem transRec : transFeeItemMap1.values()) {
               
                if(transRec.RegulatoryTrxnFeeId == feeRec.Id && BCMOH_Constants.allALUnitTypes.contains(transRec.Name)) {
                   if(transRec.Name == 'Late Fee') {
                        hasFeeItem = true;
                        documentMappingData1.put('Name', BCMOH_Constants.lateFee);
                        lateFeeSum = transRec.Amount__c;
                        latefeeFeeSum = transRec.FeeAmount;                 
                    }
                }
            }

            if(!hasFeeItem) {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFeeItem);
                    }
            else {
                if(documentMappingData1.keySet().contains(BCMOH_Constants.lateFee) || !documentMappingData1.isEmpty()) {
                    lateFeeSum = lateFeeSum.setscale(2);
                    documentMappingData1.put('Amount', '$'+lateFeeSum);
                    latefeeFeeSum = latefeeFeeSum.setscale(2);
                    documentMappingData1.put('Fees', '$'+latefeeFeeSum);
                }
            }
        }
        catch(exception ex) {
            system.debug('fetchFeeRelatedInformation catch uuuuu '+ex.getMessage());
            LogService.logAndPublish(className, 'fetchFeeRelatedInformation', '', ex);
        }
        return reqdDataPresent;
    }
}