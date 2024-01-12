/**
* @Name              : ServerSideDocumentGenerationController
* @Description       : Generates Documents and attach to record
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
public with sharing class ServerSideDocumentGenerationController {
    //unwanted attributes
   Public Static Map<String, String> tempNameStatusMsgMap = new Map<String, String>();//success or error details for each template
   Public Static Map<Id, Account> parentAccMap = new Map<Id, Account>();
   //public attributes
   Public Static String className = 'ServerSideDocumentGenerationController';
   Public Static Map<String, String> docNameWithTitleMap = new Map<String, String>();//doc name with title
   Public Static Map<String, DocumentTemplateContentDoc> docTempContentMap = new Map<String, DocumentTemplateContentDoc>();
   Public Static Map<String, Object> documentMappingData = new Map<String, Object>();//to stringify req text for doc gen process
   Public Static Map<String, Object> documentMappingData1 = new Map<String, Object>();//to stringify token data for doc gen process
   Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
   Public Static Map<Id, Account> accMap = new Map<Id, Account>();
   Public Static Map<Id, RegulatoryTrxnFee> transFeeMap1 = new Map<Id, RegulatoryTrxnFee>();
   Public Static Map<Id, RegulatoryTrxnFeeItem> transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>();
   Public Static List<DocumentGenerationProcess> docGenList = new List<DocumentGenerationProcess>();//for DML Docs
   //Error handling
   Public Static Map<Id, String> blaErrMap = new Map<Id, String>();//Update status to error with errmsg
   Public Static Boolean reqdDataPresent = true;
   Public Static List<BusinessLicenseApplication> blaErrUpdateList = new List<BusinessLicenseApplication>();
   //used when test running
   Public Static Id contentVersionId1 = NULL;
    
   //method to fetch contentversion Id
   Public static void startDocGenProcess(List<Account> accData, Map<Id, BusinessLicenseApplication> blaMap1,
                                         Map<Id, RegulatoryTrxnFee> transFeeMap, List<RegulatoryTrxnFeeItem> transFeeItemList) {
        try {
            system.debug('%% ^^ c4ds'+accData);
            system.debug('%% ^^ c4ds blaMap1 '+blaMap1);
            system.debug('%% ^^ c4ds transFeeMap '+transFeeMap);
            system.debug('%% ^^ c4ds transFeeItemList '+transFeeItemList);
            //attribute assignment
            blaMap = blaMap1;//Note : blaMap - Map of Account Id vs bla Record
            accMap = new Map<Id, Account>(accData);//acc
            transFeeMap1 = transFeeMap;//fee
            transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>(transFeeItemList);//fee item
            //***************************************************************************************
            //fetch required data of reg trans fee
            Map<Id, RegulatoryTrxnFee> transFeeMap2 = new Map<Id, RegulatoryTrxnFee>(transFeeMap.values());//to fetch ids of reg trans recs
            for(RegulatoryTrxnFee regFeeRec : [SELECT Id, Name, TotalFeeAmount, recordTypeId, AccountId, ParentRecordId, FeeType__c,
                                                Status, DueDate FROM RegulatoryTrxnFee WHERE Id IN: transFeeMap2.keyset() LIMIT 50000]) {
                transFeeMap1.put(regFeeRec.AccountId, regFeeRec);
            }
            system.debug('%% ^^ c4ds transFeeMap1 after query '+transFeeMap1);
            
            //fetch document name and title for given purpose
            docNameWithTitleMap = BCMOH_UtilityClass.getDocNameTitle(BCMOH_Constants.templatePurpose);
            system.debug('## csd docNameWithTitleMap '+docNameWithTitleMap);
            //fetch content version Id for given doc names
            docTempContentMap = BCMOH_UtilityClass.getDocTempContentMap(new List<String>(docNameWithTitleMap.keySet()));
            system.debug('## csd docTempContentMap '+docTempContentMap);
            //fetch content version id when test running
            if(Test.isRunningTest()) {
                contentVersionId1 = [SELECT Id FROM ContentVersion LIMIT 1].Id;
            }
            //for each bla record generate createDocumentGenerationProcess for each template name in docNameWithTitleMap
            for(Id accId : blaMap.keySet()) {
                for(String tempName : docNameWithTitleMap.keyset()) {
                    if(reqdDataPresent) {
                        DocumentGenerationProcess docGenRec = createDocumentGenerationProcessRequest(accId, tempName);
                        system.debug('cdsjk cscd docGenRec '+docGenRec);
                        if(docGenRec != NULL) {
                            docGenList.add(docGenRec);
                        }
                    }
                }
                //if no templates fetched for renewals
                if(docNameWithTitleMap.isEmpty()) {
                    system.debug('sv css'+BCMOH_Constants.documentNotFetched);
                    reqdDataPresent = false;
                    blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.documentNotFetched);
                }
            }
            //DML - insert docgenproc records
            if(!docGenList.isEmpty()) {//TO DO: check if alr admin can insert doc gen obj records and add access check
                system.debug('##entered doc gen insert'+docGenList);
                Database.Insert(docGenList, false);
            }
            //DML - bla status err msg
            if(!blaErrMap.isEmpty()) {
                system.debug('##blaErrMap'+blaErrMap);
                blaErrUpdateList = BCMOH_UtilityClass.updateBlaStatus(blaErrMap, BCMOH_Constants.errorBlaStatus);
                if(!blaErrUpdateList.isEmpty() && BusinessLicenseApplication.sObjectType.getDescribe().isUpdateable()) {
                 	Database.Update(blaErrUpdateList, false);//add error logs for failed records               
           		}
           }
           system.debug('cdsfinal '+blaErrMap);
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'startDocGenProcess', '', ex);
        }
    }
    
    //method to set params for document generation
    private static DocumentGenerationProcess createDocumentGenerationProcessRequest(Id accId, String tempName) {
        String type = 'GenerateAndConvert';//get from metadata
        String docGenType = 'Advanced';
        DocumentGenerationProcess docGenRec = new DocumentGenerationProcess();
        String tokenData = '';
        try {
             Id referenceId = blaMap.get(accId).Id;//null check not needed coz acc id comes from bla map//'0f0As000000065RIAQ';//0f0As00000000ZVIAY
            //prepare requestText
            String requestText = prepareRequestText(accId, tempName);
            //prepare TokenData
            if(requestText != NULL) {
                tokenData = prepareTokenData(accId);
                //generate document data
                if(referenceId != NULL && tokenData != NULL) {
                    docGenRec = BCMOH_UtilityClass.getDocGenProcRec(type, requestText, referenceId, tokenData, docGenType);
                }
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'createDocumentGenerationProcessRequest', '', ex);
        }
        return docGenRec;
    }
    //request text for doc gen process
    public static String prepareRequestText(Id accId, String tempName) {
        String requestText = '';
        String contentDocumentTitle = '';
        Id contentVersionId = NULL;
        try {
            //1) Get doc title
            contentDocumentTitle = docNameWithTitleMap.get(tempName);//null check not needed as attribute is passed from for looping of map
            system.debug('*** cdsa contentDocumentTitle '+contentDocumentTitle);
            system.debug('*** cdsa transFeeMap1.get(accId) '+transFeeMap1.get(accId));
            //if title contains "InvoiceId" merge field append to doc title, else add bla to error map
            if(contentDocumentTitle.contains(BCMOH_Constants.invoiceIdMerge) && transFeeMap1.get(accId) == NULL) {
                system.debug('*** cdsa contains but no fee map '+contentDocumentTitle);
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFee);
                return NULL;//go to next iteration
            }
            else if(contentDocumentTitle.contains(BCMOH_Constants.invoiceIdMerge) && transFeeMap1.get(accId) != NULL) {
                system.debug('*** cdsa contains and fee present '+contentDocumentTitle);
                contentDocumentTitle = contentDocumentTitle.replace(BCMOH_Constants.invoiceIdMerge, transFeeMap1.get(accId).Name);
                system.debug('*** cdsa after replace '+contentDocumentTitle);
            }
            
            //2) Get content version id
            if(Test.isRunningTest()) {
                contentVersionId = contentVersionId1;
            }
            else if(docTempContentMap.get(tempName) != NULL && docTempContentMap.get(tempName).LatestContentVersionId != NULL) {
                system.debug('%%docTempContentMap.get(tempName) '+docTempContentMap.get(tempName));
                contentVersionId = docTempContentMap.get(tempName).LatestContentVersionId;
            }
            else {
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.LatestContentVersionId);
                system.debug('%%docTempContentMap. blaErrMap '+blaErrMap);
                return NULL;
            }
            //3) set map to prepare request text json
            if(contentVersionId != NULL && contentDocumentTitle != NULL) {
                documentMappingData.put(BCMOH_Constants.templateContentVersionId, contentVersionId);
                documentMappingData.put(BCMOH_Constants.docTitle, contentDocumentTitle);
                documentMappingData.put(BCMOH_Constants.keepIntermediate, false);
                //Convert the Map to a JSON string
                requestText = BCMOH_UtilityClass.mapToJson(documentMappingData);
                system.debug('%%cscdsv requestText '+requestText);
            }
        }
        catch(exception ex) {
            LogService.logAndPublish(className, 'prepareRequestText', '', ex);
        }
        return requestText;
    }
    
    //prepareTokenData
    public static String prepareTokenData(Id accId) {
        String tokenData = '';
        try {
            system.debug('%% cscs'+accMap.get(accId));
            //a) Account data
            Account accRec = accMap.get(accId);//null check not needed as blaMap acc comes from accmap
            documentMappingData1.put('ResidenceName', accRec.Name);
            documentMappingData1.put('ResID', accRec.RegId__c);
            documentMappingData1.put('LicenseType', accRec.LicenseType__r.Name);//TO DO: add if for null check?
            documentMappingData1.put('ResidencePhoneNumber', accRec.Phone);
            documentMappingData1.put('ResidenceFax', accRec.Fax);
            
            //b) Account's Parent Data    
            system.debug('%% accRec.ParentId'+accRec.ParentId);
            if(accRec.ParentId != NULL) {
                documentMappingData1.put('RegistrantName', accRec.Parent.Name);          
                documentMappingData1.put('RegistrantPhone', accRec.Parent.Phone);
                
                //c) Account's Parent Address
                if(accRec.Parent.BillingAddress != NULL) {
                    system.debug('%% accRec.Parent.BillingAddress'+accRec.Parent.BillingAddress);//TO DO: is billing address mandatory?
                    Address addrParent = accRec.Parent.BillingAddress;
                    String addressParent = addrParent.Street+', '+ addrParent.City+', '+ addrParent.State+', '+addrParent.PostalCode+', '+ addrParent.Country;
                    if(addressParent.contains('null,')) {
                        system.debug('csda addressParent '+addressParent);
                        addressParent = addressParent.replace('null,','');
                    }
                    system.debug('csda 3 addressParent '+addressParent);
                    documentMappingData1.put('RegistrantAddress', addressParent);
                    documentMappingData1.put('RegistrantBillingAddress', addressParent);
                }
                else {
                    system.debug(' cs accRec.Parent.BillingAddress '+reqdDataPresent+' '+accRec.Parent.BillingAddress);
                    reqdDataPresent = false;
                    blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountParentAddr);
                    return NULL;
                }
            }
            else {
                system.debug(' cs AssociatedLocations'+reqdDataPresent+' '+accRec.AssociatedLocations);
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountParent);
                return NULL;
            }
           
            //d) Account's Address data
            if(reqdDataPresent && accRec.AssociatedLocations != NULL &&
               accRec.AssociatedLocations[0].Location.VisitorAddress.Address != NULL) {
                AssociatedLocation asLoc = accRec.AssociatedLocations[0];//TO DO: reduce to single line
                Address accAddress = asLoc.Location.VisitorAddress.Address;
                String accAddr = accAddress.Street+', '+ accAddress.City+', '+ accAddress.State+', '+accAddress.PostalCode+', '+ accAddress.Country;
                system.debug('%% acc address cds'+accAddr);
                if(accAddr.contains('null,')) {
                    system.debug('csda addressParent '+accAddr);
                    accAddr = accAddr.replace('null,','');
                }
                documentMappingData1.put('ResidenceAddress', accAddr);
            }
            else {
                system.debug('accountAddr cs'+reqdDataPresent+' '+accRec.AssociatedLocations);
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.accountAddr);
                return NULL;
            }
            
            //e) BL related data
            if(reqdDataPresent && accRec.BusinessLicenses != NULL && accRec.BusinessLicenses[0].RegistrationCertificate__c != NULL) {
                system.debug(' &&&&& bl thr cds'+reqdDataPresent+' '+accRec.BusinessLicenses[0]);
                BusinessLicense blRec = accRec.BusinessLicenses[0];
                documentMappingData1.put('CertificateId', blRec.RegistrationCertificate__c);
            } 
            else {
                system.debug(' &&&&& cds bl not there'+reqdDataPresent+' '+accRec.BusinessLicenses[0]);
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.blCertId);
                return NULL;
            }
            
            //f) Contact related data
            system.debug('%% accRec.AccountContactRelations'+accRec.AccountContactRelations[0]);
            if(reqdDataPresent && accRec.AccountContactRelations != NULL) {
                system.debug(' AccountContactRelations thr cds'+reqdDataPresent+' '+accRec.AccountContactRelations[0]);
                AccountContactRelation acRel = accRec.AccountContactRelations[0];
                documentMappingData1.put('Name', acRel.Contact.Name);
                documentMappingData1.put('ContactPhone', acRel.Contact.Phone);
                documentMappingData1.put('ContactEmail', acRel.Contact.Email);
                documentMappingData1.put('PrimaryRole', acRel.Roles);
                documentMappingData1.put('ContactCell', acRel.Contact.MobilePhone);
            }
            else {
                system.debug(' AccountContactRelations not there cds'+reqdDataPresent+' '+accRec.AccountContactRelations[0]);
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.relatedContacts);
                return NULL;
            }
            
            //h) Fee related data
            system.debug('%% entered fee map transFeeMap1.get(accId)'+reqdDataPresent+' '+transFeeMap1.get(accId));
            if(reqdDataPresent && transFeeMap1.get(accId) != NULL) {
                system.debug('%% entered fee map'+transFeeMap1);
                reqdDataPresent = fetchFeeRelatedInformation(accId);
                system.debug('%% entered fee map'+reqdDataPresent);
            }
            else {
                system.debug('%% entered fee map transFeeMap1.get(accId)'+transFeeMap1.get(accId));
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFee);
                return NULL;
            }
            
            //g) Formula fields mapping
            if(reqdDataPresent) {
            	documentMappingData1.put('InvoiceCreatedDate', Date.Today());//INVOICE template
            }
            
            //Convert the Map to a JSON string
            if(reqdDataPresent) {
                tokenData = BCMOH_UtilityClass.mapToJson(documentMappingData1);
            }
            else {
                tokenData = NULL;
            }
            system.debug('%%cscdsv tokenData '+tokenData);
        }
        catch(exception ex) {
            system.debug('uuuuu '+ex.getMessage());
            LogService.logAndPublish(className, 'prepareTokenData', '', ex);
        }
        return tokenData;
    }
    
    //fetchFeeRelatedInformation;
    private static Boolean fetchFeeRelatedInformation(Id accId) {
        Boolean hasFeeItem = false;
        Decimal publicSum = 0;
        Decimal publicQuantitySum = 0;
        Decimal publicFeeSum = 0;
        
        Decimal privateQuantitySum = 0;
        Decimal privateSum = 0;
        Decimal privateFeeSum = 0;
        
        Decimal perDiemQuantitySum = 0;
        Decimal perDiemSum = 0;
        Decimal perDiemFeeSum = 0;
        try {
            //Fee data
            system.debug('&&cws'+accId+' '+transFeeMap1);
            RegulatoryTrxnFee feeRec = transFeeMap1.get(accId);
            //fee mapping
            documentMappingData1.put('InvoiceId', feeRec.Name);//ALR-775
            documentMappingData1.put('TotalFeeAmount', feeRec.TotalFeeAmount);//ALR-775
            system.debug('^^ feeRec'+feeRec);
            
            //fee item mapping
            for(RegulatoryTrxnFeeItem transRec : transFeeItemMap1.values()) {
                if(transRec.RegulatoryTrxnFeeId == feeRec.Id && transRec.Quantity__c != 0) {
                    if(transRec.Name == 'Public') {
                        system.debug('cs'+transRec.Amount__c+' '+transRec.Quantity__c+' '+transRec.FeeAmount);
                        hasFeeItem = true;
                        documentMappingData1.put(BCMOH_Constants.unitsPublic, BCMOH_Constants.unitsPublic);
                        publicSum = transRec.Amount__c;
                        publicQuantitySum += transRec.Quantity__c;
                        publicFeeSum +=  transRec.FeeAmount;
                    }
                    else if(transRec.Name == 'Private') {
                        system.debug('cs'+transRec.Amount__c+' '+transRec.Quantity__c+' '+transRec.FeeAmount);
                        hasFeeItem = true;
                        documentMappingData1.put(BCMOH_Constants.unitsPrivate, BCMOH_Constants.unitsPrivate);
                        privateSum = transRec.Amount__c;
                        privateQuantitySum += transRec.Quantity__c;
                        privateFeeSum += transRec.FeeAmount;                    
                    }
                    else if(transRec.Name == 'Per Diem') {
                        system.debug('sdscd has per diem'+transRec);
                        hasFeeItem = true;
                        documentMappingData1.put(BCMOH_Constants.unitsPerDiem, BCMOH_Constants.unitsPerDiem);
                        perDiemSum = transRec.Amount__c;
                        perDiemQuantitySum += transRec.Quantity__c;
                        perDiemFeeSum += transRec.FeeAmount;                 
                    }
                }
            }
            
            //add values to mapping if present
            if(!hasFeeItem) {
                reqdDataPresent = false;
                blaErrMap.put(blaMap.get(accId).Id, BCMOH_Constants.docDataNotFetched+': '+BCMOH_Constants.regulatoryTransactionFeeItem);
                return NULL;
            }
            else {
                if(documentMappingData1.keySet().contains(BCMOH_Constants.unitsPublic)) {
                    documentMappingData1.put('PublicQuantitySum', publicQuantitySum);
                    documentMappingData1.put('PublicSum', publicSum);
                    documentMappingData1.put('PublicFeeSum', publicFeeSum);
                }
                if(documentMappingData1.keySet().contains(BCMOH_Constants.unitsPrivate)) {
                    documentMappingData1.put('PrivateQuantitySum', privateQuantitySum);
                    documentMappingData1.put('PrivateSum', privateSum);
                    documentMappingData1.put('PrivateFeeSum', privateFeeSum);
                }
                if(documentMappingData1.keySet().contains(BCMOH_Constants.unitsPerDiem)) {
                    system.debug('A contais perdiem'+documentMappingData1);
                    documentMappingData1.put('PerDiemQuantitySum', perDiemQuantitySum);
                    documentMappingData1.put('PerDiemSum', perDiemSum);
                    documentMappingData1.put('PerDiemFeeSum', perDiemFeeSum);
                }
            }
        }
        catch(exception ex) {
            system.debug('uuuuu '+ex.getMessage());
            LogService.logAndPublish(className, 'fetchFeeRelatedInformation', '', ex);
        }
        return reqdDataPresent;
    }
}