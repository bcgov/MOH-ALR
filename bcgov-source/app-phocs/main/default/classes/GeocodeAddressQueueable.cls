/**********************************************************************************************
* @Author:Accenture_PHOCS    
* @Date:      
* @Description: The purpose of this Class is to trigger Geocoder integration for PHOCS Accounts
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           EHIS-718               Vasanthi    Initial Version
***********************************************************************************************/
public class GeocodeAddressQueueable implements Queueable, Database.AllowsCallouts {

    private Id accountId;
    private Id initiatingUserId;

    public GeocodeAddressQueueable(Id accountId) {
        this.accountId = accountId;
        this.initiatingUserId = UserInfo.getUserId(); 
    }

    public void execute(QueueableContext context) {
        AccountTriggerHandler.setSkipGeocode(true);
        Account acct = [
            SELECT Id,
                   Physical_Address__Street__s,
                   Physical_Address__City__s,
                   Physical_Address__StateCode__s,
                   Physical_Address__PostalCode__s,
                   Physical_Address__CountryCode__s
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        //  Build address string
        List<String> addressParts = new List<String>();
        if (String.isNotBlank(acct.Physical_Address__Street__s)) addressParts.add(acct.Physical_Address__Street__s);
        if (String.isNotBlank(acct.Physical_Address__City__s)) addressParts.add(acct.Physical_Address__City__s);
        if (String.isNotBlank(acct.Physical_Address__StateCode__s)) addressParts.add(acct.Physical_Address__StateCode__s);
        //if (String.isNotBlank(acct.Physical_Address__PostalCode__s)) addressParts.add(acct.Physical_Address__PostalCode__s);
        if (String.isNotBlank(acct.Physical_Address__CountryCode__s)) addressParts.add(acct.Physical_Address__CountryCode__s);

        String fullAddress = String.join(addressParts, ', ');
        String encodedAddress = EncodingUtil.urlEncode(fullAddress, 'UTF-8');

        String provinceCode = String.isBlank(acct.Physical_Address__StateCode__s) ? '' : acct.Physical_Address__StateCode__s;

        //  Construct the API URL
        String url = 'https://geocoder.api.gov.bc.ca/addresses.json'
            + '?addressString=' + encodedAddress
            + '&locationDescriptor=any'
            + '&maxResults=1'
            + '&interpolation=adaptive'
            + '&echo=true'
            + '&brief=True'
            + '&autoComplete=True'
            + '&exactSpelling=false'
            + '&fuzzyMatch=True'
            + '&setBack=0'
            + '&outputSRS=4326'
            + '&minScore=80'
            + '&provinceCode=' + provinceCode;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setTimeout(10000);

        try {
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> features = (List<Object>) jsonResponse.get('features');

                if (!features.isEmpty()) {
                    Map<String, Object> feature = (Map<String, Object>) features[0];
                    Map<String, Object> properties = (Map<String, Object>) feature.get('properties');
                    Map<String, Object> geometry = (Map<String, Object>) feature.get('geometry');
                    List<Object> coordinates = (List<Object>) geometry.get('coordinates');


                    String postalCode = (String) properties.get('postalCode');
                    Decimal longitude = (Decimal) coordinates[0];
                    Decimal latitude = (Decimal) coordinates[1];
                    
                     String fullAddressresponse = (String) properties.get('fullAddress');
                     String street = '';
                     String city = '';
                     String province = '';

				if (String.isNotBlank(fullAddressresponse)) {
    				List<String> parts = fullAddressresponse.split(',');

                    if (parts.size() > 0) street = parts[0].trim();
                    if (parts.size() > 1) city = parts[1].trim();
                    if (parts.size() > 2) province = parts[2].trim();
                 }


                    // Update the Account with geocoded info
                    Account acctToUpdate = new Account(
                        Id = acct.Id,
                        PhysicalLocation__Latitude__s = latitude,
                        PhysicalLocation__Longitude__s = longitude,
                         Physical_Address__Street__s = street,
                         Physical_Address__City__s = city,
                         Physical_Address__StateCode__s = province
                    );

                    update acctToUpdate;
                }
                else{
                    sendNotification(new Set<String>{ initiatingUserId }, accountId);
                }
            } else {
                System.debug('Geocoding failed with status: ' + res.getStatus());
            }

        } catch (Exception ex) {
            System.debug('Callout exception: ' + ex.getMessage());
        }
    }
        
      private void sendNotification(Set<String> recipientsIds,Id accountId) {
		CustomNotificationType cnt = [
              SELECT Id 
              FROM CustomNotificationType 
              WHERE DeveloperName = 'GeoCoder_Notification' 
              LIMIT 1
          ];
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('Address Not Found');
        notification.setBody('The location for this address was not found. Please try again with a different address.');
        notification.setNotificationTypeId(cnt.Id); 
        notification.setTargetId(accountId);

        try {
            notification.send(recipientsIds);
        } catch (Exception e) {
            System.debug('Notification error: ' + e.getMessage());
        }
    }
        
}