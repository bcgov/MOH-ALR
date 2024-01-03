public with sharing class FetchAndGenerateCSV 
{
    static String csvHeader = 'ResID,Residence,HACode,Res_Phone,Res_Phone_Ext,Res_Fax,Website,Registrant_Contact,RegNo,RegStatus,HospSvc_Meal,HospSvc_HouseKeep,HospSvc_Laundry,HospSvc_SocialRec,HospSvc_24HResp,ResCatCode,Public_Units,Private_Units,Per_Diem_Units,Number_of_AL_Units,ADLS,Meds,Diets,Safekeeping,Psychosocial,Behaviour,Res_Building_Floor,\n';
    static String csvContent = '';
    static String ResID= '', Residence= '', HACode= '', Res_Phone= '', Res_Phone_Ext= '', Res_Fax= '', Website= '', Registrant_Contact= '', RegNo= '', RegStatus= '', HospSvc_Meal= '', HospSvc_HouseKeep= '', HospSvc_Laundry= '', HospSvc_SocialRec= '', HospSvc_24HResp= '', ResCatCode= '', ADLS= '', Meds= '', Diets= '', Safekeeping= '', Psychosocial= '', Behaviour= '';
    static Integer Public_Units = 0, Private_Units = 0, Per_Diem_Units = 0, Number_of_AL_Units = 0;
    static List<String> resFilterStatuses = new List<String> {'Registered Active', 'Registered Active with Conditions', 'Registered Active Progressive Enforcement'};
    static Map<String, String> healthAuthorityMap = new Map<String, String>
                                                                        {
                                                                            'Island Health - Island' => 'VIHA',
                                                                            'Interior Health - IH' => 'IHA',
                                                                            'Fraser Health - FH' => 'FHA',
                                                                            'Northern Health - NH' => 'NHA',
                                                                            'Vancouver Coastal Health - VCH' => 'VCHA'
                                                                        };
   
   
    @AuraEnabled(cacheable=true)
    public static String generateCSV() 
    {
        csvContent = csvHeader;  
        List<Account> accounts = [SELECT Id, RegId__c, Name, HealthAuthority__c, Phone, Extension__c, Fax, Website, Status__c,
                                   (SELECT ContactId, PrimaryContact__c, Contact.Name FROM AccountContactRelations WHERE PrimaryContact__c = true LIMIT 1),
                                   (SELECT RegistrationCertificate__c FROM BusinessLicenses WHERE Status = 'Active' LIMIT 1),
                                   (SELECT ServiceName__c FROM Services__r WHERE ServiceName__c IN ('Meal Services', 'Housekeeping', 'Laundry', 'Social and Recreational Opps', 'S24-Hour Emergency Response System') LIMIT 50),
                                   Account.LicenseType__r.RegulatoryAuthorizationCode__c,
                                   (SELECT Quantity, Type__c FROM Assets WHERE Type__c IN ('Public', 'Private', 'Per Diem') AND ParentId = NULL AND Quantity > 0.00)
                                   FROM Account
                                   WHERE Status__c IN :resFilterStatuses
                                    LIMIT 10000];
        
        for(Account acc : accounts) 
        {
            ResID = (acc.RegId__c != null) ? acc.RegId__c : '';
            Residence = (acc.Name != null) ? acc.Name : '';
            HACode = healthAuthorityMap.get(acc.HealthAuthority__c );
            HACode = (HACode != null) ? HACode : '';
            Res_Phone = (acc.Phone != null) ? acc.Phone : '';
            Res_Phone_Ext = (acc.Extension__c != null) ? acc.Extension__c : '';
            Res_Fax = (acc.Fax != null) ? acc.Fax : '';
            Website = (acc.Website != null) ? acc.Website : '';
            RegStatus = (acc.Status__c != null) ? acc.Status__c : '';
            ResCatCode = (acc.LicenseType__r.RegulatoryAuthorizationCode__c != null) ? acc.LicenseType__r.RegulatoryAuthorizationCode__c : '';
           
            Contact primaryContact = getPrimaryContact(acc);
            if (primaryContact != null) 
            {
                Registrant_Contact = primaryContact.Name;
            }
            
            RegNo = getRegistrationCertificates(acc.BusinessLicenses);
            
            HospSvc_Meal = getServiceFlag(acc.Services__r, 'Meal Services');
            HospSvc_HouseKeep = getServiceFlag(acc.Services__r, 'Housekeeping'); 
            HospSvc_Laundry = getServiceFlag(acc.Services__r, 'Laundry');                       
            HospSvc_SocialRec = getServiceFlag(acc.Services__r, 'Social and Recreational Opps'); 
            HospSvc_24HResp = getServiceFlag(acc.Services__r, 'S24-Hour Emergency Response System');  
            ADLS = getServiceFlag(acc.Services__r, 'Assistance with daily living activities');                       
            Meds = getServiceFlag(acc.Services__r, 'Assistance with managing medication'); 
            Diets = getServiceFlag(acc.Services__r, 'Assistance managing therapeutic diets');  
            Safekeeping = getServiceFlag(acc.Services__r, 'Safekeeping of money/personal property');                       
            Psychosocial = getServiceFlag(acc.Services__r, 'Psychosocial support'); 
            Behaviour = getServiceFlag(acc.Services__r, 'Assistance with behaviour management');

            Public_Units = getAssetQuantity(acc.Assets, 'Public');
            Private_Units = getAssetQuantity(acc.Assets, 'Private');
            Per_Diem_Units = getAssetQuantity(acc.Assets, 'Per Diem');
            Number_of_AL_Units = Public_Units + Private_Units + Per_Diem_Units;

            // Append fetched data to the CSV content
            csvContent += ResID + ',' + Residence + ',' + HACode + ',' + Res_Phone + ',' + Res_Phone_Ext + ',' + Res_Fax + ',' + Website + ',' + 
            Registrant_Contact + ',' +
            RegNo + ',' + 
            RegStatus + ',' + 
            HospSvc_Meal + ',' + HospSvc_HouseKeep + ',' + HospSvc_Laundry + ',' + HospSvc_SocialRec + ',' + HospSvc_24HResp + ',' + 
            ResCatCode + ',' + 
            Public_Units + ',' + Private_Units + ',' + Per_Diem_Units + ',' + Number_of_AL_Units + ',' + 
            ADLS + ',' + Meds + ',' + Diets + ',' + Safekeeping + ',' + Psychosocial + ',' + Behaviour+ '\n';        
        }        
        return csvContent;
    }
    
    // Helper method to get the registration certificates
    private static String getRegistrationCertificates(List<BusinessLicense> licenses) 
    {
        String certificates = '';
        for(BusinessLicense license : licenses) 
        {
            if(license.RegistrationCertificate__c != null) 
            {
                certificates += license.RegistrationCertificate__c + ';'; // Separating certificates by a delimiter
            }
        }
        return certificates;
    }
    
    // Helper method to get the service flag
    private static String getServiceFlag(List<Service__c> services, String serviceName) 
    {
        for(Service__c service : services) 
        {
            if(service.ServiceName__c == serviceName) 
            {
                return '-1'; // Flag '-1' if service name is found
            }
        }
        return '0'; // Default flag '0' if service name is not found
    }
    
    // Helper method to get the asset quantity based on type
    private static Integer getAssetQuantity(List<Asset> assets, String assetType) 
    {
        Decimal quantity = 0;
        for (Asset asset : assets) 
        {
            if (asset.Type__c == assetType) 
            {
                quantity += asset.Quantity != null ? asset.Quantity : 0;
            }
        }
        return quantity.intValue(); // Convert Decimal to Integer using intValue() method
    }

        // Helper method to retrieve primary contacts from AccountContactRelation
    private static Contact getPrimaryContact(Account acc) 
    {
        Contact primaryContact = null;

        if (acc.AccountContactRelations != null && !acc.AccountContactRelations.isEmpty()) 
        {
            // Loop through AccountContactRelations to find the primary contact
            for (AccountContactRelation acr : acc.AccountContactRelations) 
            {
                if (acr.PrimaryContact__c) 
                {
                    // Retrieve Contact object if Primary_Contact__c is true
                    primaryContact = acr.Contact;
                    break; // Found the primary contact, exit loop
                }
            }
        }
        return primaryContact;
    }

}