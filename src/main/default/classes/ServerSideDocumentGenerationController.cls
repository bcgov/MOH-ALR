/**
* @Name              : ServerSideDocumentGenerationController
* @Description       : Generates Documents and attach to record
* @Author            : Sweta (Accenture)
* @StoryNo           : ALR-560
**/
public with sharing class ServerSideDocumentGenerationController {
    
   //public attributes
   Public Static Map<String, DocumentTemplateContentDoc> docTempContentMap = new Map<String, DocumentTemplateContentDoc>();
   Public Static List<String> templateNames = new List<String>{'RenewalApplicationForm','RenewalInvoiceTemplate'};//add to metadata later
   //Public Static List<String> templateNames = new List<String>{'RenewalInvoiceTemplate'};
   Public Static Map<String, String> tempNameStatusMsgMap = new Map<String, String>();//success or error details for each template
   Public Static Map<String, Object> documentMappingData = new Map<String, Object>();
   Public Static Map<String, Object> documentMappingData1 = new Map<String, Object>();
   Public Static Map<Id, BusinessLicenseApplication> blaMap = new Map<Id, BusinessLicenseApplication>();
   Public Static Map<Id, Account> accMap = new Map<Id, Account>();
   Public Static Map<Id, Account> parentAccMap = new Map<Id, Account>();
   Public Static Map<Id, RegulatoryTrxnFee> transFeeMap1 = new Map<Id, RegulatoryTrxnFee>();
   Public Static Map<Id, RegulatoryTrxnFeeItem> transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>();
    
   //method to fetch contentversion Id
   Public static void startDocGenProcess(List<Account> accData, Map<Id, BusinessLicenseApplication> blaMap1,
                                         Map<Id, RegulatoryTrxnFee> transFeeMap, List<RegulatoryTrxnFeeItem> transFeeItemList) {
        try {
            system.debug('%% ^^ c4ds'+accData);
            system.debug('%% ^^ c4ds transFeeMap '+transFeeMap);
            system.debug('%% ^^ c4ds transFeeItemList '+transFeeItemList);
            //attribute assignment
            blaMap = blaMap1;//bla
            accMap = new Map<Id, Account>(accData);//acc
            transFeeMap1 = transFeeMap;//fee
            transFeeItemMap1 = new Map<Id, RegulatoryTrxnFeeItem>(transFeeItemList);//fee item
            system.debug('%% ^^ c4ds transFeeItemMap '+transFeeItemMap1);
            //***************************************************************************************
            
            //fetch content version Id and document title
            docTempContentMap = BCMOH_UtilityClass.getDocTempContentMap(templateNames);
            //Note : blaMap - Map of Account Id vs bla Record
            //for each bla record createDocumentGenerationProcess for each template name
            for(Id accId : blaMap.keySet()) {
                for(String tempName : templateNames) {
                    Id contentVersionId;
                    String contentDocumentTitle;
                    if(tempName == 'RenewalApplicationForm') {
                        contentDocumentTitle = 'Registration Renewal Application Form';
                    }
                    else if(tempName == 'RenewalInvoiceTemplate') {
                        contentDocumentTitle = 'Renewal Invoice';
                    }
                    if(Test.isRunningTest()) {
                        contentVersionId = [SELECT Id FROM ContentVersion LIMIT 1].Id;
                        //contentDocumentTitle = 'TestDoc';
                        createDocumentGenerationProcessRequest(accId, contentVersionId, contentDocumentTitle);
                    }
                    else if(docTempContentMap.get(tempName) != NULL) {
                        contentVersionId = docTempContentMap.get(tempName).LatestContentVersionId;
                        //contentDocumentTitle = docTempContentMap.get(tempName).ContentDocument.Title;
                        //createDocumentGenerationProcessRequest(accId, docTempContentMap.get(tempName));
                    	createDocumentGenerationProcessRequest(accId, contentVersionId, contentDocumentTitle);
                    	system.debug('%%vfd vfds'+accId+' '+tempName);
                    }
                    else {
                        system.debug('%% cdsa 1 ');
                        tempNameStatusMsgMap.put(tempName, BCMOH_Constants.documentNotFound);//error handling when document not found
                        system.debug('%% cdsa'+tempNameStatusMsgMap);
                    }
                }
            }
        }
        catch(exception ex) {
            
        }
    }
    
    //method to set params for document generation
    //private static void createDocumentGenerationProcessRequest(Id accId, DocumentTemplateContentDoc docTempRec) {
    private static void createDocumentGenerationProcessRequest(Id accId, Id contentVersionId, String contentDocumentTitle) {
        String type = 'GenerateAndConvert';//get from metadata
        Id referenceId = blaMap.get(accId).Id;//'0f0As000000065RIAQ';//0f0As00000000ZVIAY
        String docGenType = 'Advanced';
        List<DocumentGenerationProcess> docGenList = new List<DocumentGenerationProcess>();
        try {
            //prepare requestText
            //String requestText = prepareRequestText(docTempRec);
            String requestText = prepareRequestText(contentVersionId, contentDocumentTitle);
            //prepare TokenData
            String tokenData = prepareTokenData(accId);
            //generate document data
            DocumentGenerationProcess docGenRec = BCMOH_UtilityClass.getSubstringWithoutExtension(type, requestText, referenceId, tokenData, docGenType);
            docGenList.add(docGenRec);
            //DML - insert docs
            Database.Insert(docGenList, false);
        }
        catch(exception ex) {
            
        }
    }
    //add null checks and error handling
    //private static String prepareRequestText(DocumentTemplateContentDoc docTempRec) {
    public static String prepareRequestText(Id contentVersionId, String contentDocumentTitle) {
        String requestText = '';
        try {
            //documentMappingData.put(BCMOH_Constants.templateContentVersionId, docTempRec.LatestContentVersionId);
            documentMappingData.put(BCMOH_Constants.templateContentVersionId, contentVersionId);
            //removing file extension if present
            //String docTitle = BCMOH_UtilityClass.getSubstringWithoutExtension(docTempRec.ContentDocument.Title);
            String docTitle = BCMOH_UtilityClass.getSubstringWithoutExtension(contentDocumentTitle);
            documentMappingData.put(BCMOH_Constants.docTitle, docTitle);
            documentMappingData.put(BCMOH_Constants.keepIntermediate, false);
            //Convert the Map to a JSON string
            requestText = BCMOH_UtilityClass.mapToJson(documentMappingData);
            system.debug('%%cscdsv requestText '+requestText);
        }
        catch(exception ex) {
            
        }
        return requestText;
    }
    //prepareTokenData
    private static String prepareTokenData(Id accId) {
        String tokenData = '';
        try {
            system.debug('%% cscs'+accMap.get(accId));
            //object data
            Account accRec = accMap.get(accId);
            String address = '';
            if(Test.isRunningTest()) {
                system.debug('%% inside if'+accMap.get(accId));
                address = 'address';
            }
            else {
                
            //AccountContactRelation acRel = accRec.AccountContactRelations[0];
            //BusinessLicense blRec = accRec.BusinessLicenses[0];
            system.debug('88 cs'+accMap.get(accId).BusinessLicenses);
            system.debug('88 cs csd '+accMap.get(accId).BusinessLicenses[0]);
                //AssociatedLocation asLoc = accRec.AssociatedLocations[0];
            	//Address a = asLoc.Location.VisitorAddress.Address;
            	//address = a.Street+', '+ a.City+', '+ a.State+', '+a.PostalCode+', '+ a.Country;
            }
            system.debug('%% accRec.AccountContactRelations'+accRec.AccountContactRelations[0]);
            AccountContactRelation acRel = accRec.AccountContactRelations[0];
            BusinessLicense blRec = accRec.BusinessLicenses[0];
            AssociatedLocation asLoc = accRec.AssociatedLocations[0];
            Address a = asLoc.Location.VisitorAddress.Address;
            if(a != NULL) {
            	address = a.Street+', '+ a.City+', '+ a.State+', '+a.PostalCode+', '+ a.Country;
            }
            system.debug('%% accRec.ParentId'+accRec.ParentId);
            system.debug('%% accRec.Parent.BillingAddress'+accRec.Parent.BillingAddress);
            Address addrParent = accRec.Parent.BillingAddress;
            String addressParent;
            if(addrParent != NULL) {
                
            	addressParent = addrParent.Street+', '+ addrParent.City+', '+ addrParent.State+', '+addrParent.PostalCode+', '+ addrParent.Country;
            }
            system.debug('%% address cds'+address);
            //u need to group tran fee items based on Name
            //PublicQuantitySum - Quantity__c++ then add all quantities in items - PublicQuantitySum
            //PublicSum- Amount__c++ - 
            //PublicFeeSum - FeeAmount++
            system.debug('&&cws'+accId+' '+transFeeMap1);
            RegulatoryTrxnFee feeRec = transFeeMap1.get(accId);
            system.debug('^^ feeRec'+feeRec);
            Decimal publicSum = 0;
            Decimal publicQuantitySum = 0;
            Decimal publicFeeSum = 0;
            
            Decimal privateQuantitySum = 0;
            Decimal privateSum = 0;
            Decimal privateFeeSum = 0;
            
            Decimal licensedQuantitySum = 0;
            Decimal licensedSum = 0;
            Decimal licensedFeeSum = 0;
            
            Decimal perDiemQuantitySum = 0;
            Decimal perDiemSum = 0;
            Decimal perDiemFeeSum = 0;
            
            Decimal indLivingQuantitySum = 0;
            Decimal indLivingSum = 0;
            Decimal indLivingFeeSum = 0;
            
            Decimal otherQuantitySum = 0;
            Decimal otherSum = 0;
            Decimal otherFeeSum = 0;
                      
            for(RegulatoryTrxnFeeItem transRec : transFeeItemMap1.values()) {
                system.debug('** entered cs'+transRec);
                if(transRec.Name == 'Public') {
                    system.debug('cs'+transRec.Amount__c+' '+transRec.Quantity__c+' '+transRec.FeeAmount);
                    publicSum = publicSum + transRec.Amount__c;
                    publicQuantitySum = publicQuantitySum + transRec.Quantity__c;
                    publicFeeSum +=  transRec.FeeAmount;
                }
                else if(transRec.Name == 'Private') {
                    system.debug('cs'+transRec.Amount__c+' '+transRec.Quantity__c+' '+transRec.FeeAmount);
                    privateSum += transRec.Amount__c;
                    privateQuantitySum += transRec.Quantity__c;
                    privateFeeSum += transRec.FeeAmount;                    
                }
                else if(transRec.Name == 'Per Diem') {
                    perDiemSum += transRec.Amount__c;
                    perDiemQuantitySum += transRec.Quantity__c;
                    perDiemFeeSum += transRec.FeeAmount;                    
                }
                else if(transRec.Name == 'Independent Living') {
                    indLivingSum += transRec.Amount__c;
                    indLivingQuantitySum += transRec.Quantity__c;
                    indLivingFeeSum += transRec.FeeAmount;
                }
                else if(transRec.Name == 'Licensed') {
                    licensedSum += transRec.Amount__c;
                    licensedQuantitySum += transRec.Quantity__c;
                    licensedFeeSum += transRec.FeeAmount;
                }
                else if(transRec.Name == 'Other') {
                    otherSum += transRec.Amount__c;
                    otherQuantitySum += transRec.Quantity__c;
                    otherFeeSum += transRec.FeeAmount;
                }
            }
            system.debug('^^ tTTsc'+publicSum+' '+publicQuantitySum+' '+publicFeeSum+' '+feeRec);
            
            
            documentMappingData1.put('ResidenceName', accRec.Name);
            documentMappingData1.put('CertificateId', blRec.RegistrationCertificate__c);
            documentMappingData1.put('Residence ID', accRec.RegId__c);
            documentMappingData1.put('LicenseType', accRec.LicenseType__r.Name);
            documentMappingData1.put('ResidenceAddress', address);
            documentMappingData1.put('ResidencePhoneNumber', accRec.Phone);
            documentMappingData1.put('ResidenceFax', accRec.Fax);
            documentMappingData1.put('RegistrantName', accRec.Parent.Name);
            documentMappingData1.put('RegistrantBillingAddress', addressParent);
            documentMappingData1.put('RegistrantPhone', accRec.Parent.Phone);
            documentMappingData1.put('Name', acRel.Contact.Name);
            documentMappingData1.put('ContactPhone', acRel.Contact.Phone);
            documentMappingData1.put('ContactEmail', acRel.Contact.Email);
            documentMappingData1.put('PrimaryRole', acRel.Roles);
            documentMappingData1.put('ContactCell', acRel.Contact.MobilePhone);
            //testing888888888888888 ends
            
            //INVOICE STARTS
            documentMappingData1.put('InvoiceId', 'FEE-00');
            documentMappingData1.put('InvoiceCreatedDate', Date.Today());
            //RegistrantName - already done
            documentMappingData1.put('RegistrantAddress', addressParent);
            //ResidenceName - already done
            //ResidenceAddress - already done
            documentMappingData1.put('PublicQuantitySum', publicQuantitySum);
            documentMappingData1.put('PublicSum', publicSum);
            documentMappingData1.put('PublicFeeSum', publicFeeSum);
            
            documentMappingData1.put('PrivateQuantitySum', privateQuantitySum);
            documentMappingData1.put('PrivateSum', privateSum);
            documentMappingData1.put('PrivateFeeSum', privateFeeSum);
            
            documentMappingData1.put('PerDiemQuantitySum', perDiemQuantitySum);
            documentMappingData1.put('PerDiemSum', perDiemSum);
            documentMappingData1.put('PerDiemFeeSum', perDiemFeeSum);
            
            documentMappingData1.put('IndLivingQuantitySum', indLivingSum);
            documentMappingData1.put('IndLivingSum', indLivingSum);
            documentMappingData1.put('IndLivingFeeSum', indLivingFeeSum);
            
            documentMappingData1.put('LicensedQuantitySum', licensedQuantitySum);
            documentMappingData1.put('LicensedSum', licensedSum);
            documentMappingData1.put('LicensedFeeSum', licensedFeeSum);
            
            documentMappingData1.put('OtherQuantitySum', otherQuantitySum);
            documentMappingData1.put('OtherSum', otherSum);
            documentMappingData1.put('OtherFeeSum', otherFeeSum);
            
            documentMappingData1.put('TotalFeeAmount', feeRec.Id);
            //end of invoice
            
            //Convert the Map to a JSON string
            tokenData = BCMOH_UtilityClass.mapToJson(documentMappingData1);
            system.debug('%%cscdsv tokenData '+tokenData);
        }
        catch(exception ex) {
            system.debug('uuuuu '+ex.getMessage());
            
        }
        return tokenData;
    }
} 
    
        
    
/*  //start query
            String query = 'SELECT Name, Status__c, LicenseType__c,'
            +' LicenseType__r.RegulatoryAuthCategory, LicenseType__r.UnitFee__c,'
            +' LicenseType__r.OneTimeFee__c, LicenseType__r.PartialUnitFee__c, LicenseType__r.LateFee__c,'
            +' (SELECT Id FROM BusinessLicenseApplicationAccount WHERE RecordType.DeveloperName =: blaRecType'
            +' AND Status !=: blaCancelledStatus AND RenewalYear__c =: renewalYear),'
            +' (SELECT Id, Type__c, Quantity, Amount__c FROM Assets WHERE RecordType.DeveloperName =: parentAssetRT)'
            +' FROM Account'
            +' WHERE recordType.DeveloperName =: accRecType'
            +' AND Status__c IN: accStatuses';
        return Database.getQueryLocator(query);


select id, LicenseType__r.Name, Phone, Fax, parent.Name, parent.phone, 
(SELECT Id, Location.VisitorAddress.Address from AssociatedLocations), 
(SELECT RegistrationCertificate__c FROM BusinessLicenses LIMIT 1), 
(SELECT Contact.Name, Contact.Phone, Contact.Email, Contact.MobilePhone, Roles 
FROM AccountContactRelations WHERE PrimaryContact__c = TRUE AND IsActive = TRUE LIMIT 1)
from Account where id = '001As00000IMmIEIA1'*/
    
    
    /*
     * Registration Renewal Application Form
     * {{ResidenceName}}
     * {{CertificateId}}
     * resId TBD
     * {{LicenseType}}
     * {{ResidenceAddress}}
     * {{ResidencePhoneNumber}}
     * {{ResidenceFax}}
     * {{RegistrantName}}
     * {{RegistrantBillingAddress}}
     * {{RegistrantPhone}}
     * {{Name}} - - i think contact name
     * {{ContactPhone}}
     * {{ContactEmail}}
     * {{PrimaryRole}}
     * {{ContactCell}}
    //
    //
    //
    //
            //String tokenData = '{\"Name\":\"Test POC\",\"CertificateId\":\"15955\"}';
    */