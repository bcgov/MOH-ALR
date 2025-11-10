/*
    Created by: Pawan Atri
    Date: 2025-09-16
    User Story: EHIS-1425
    Title: Service class for Water license API integration
    Description: Handles callouts to water license endpoints and maps responses into wrapper classes
*/
public class PHOCSWaterLicenseCallout {

    public static PHOCSWLSWaterRightsWrapper getWaterRightsByLicence(String licenceNumber) {
        String baseUrl = System.Label.PHOCSWaterRightLicenseNumberURL;
        String endpoint = baseUrl.replace('{LicenseNumber}', licenceNumber);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if(res.getStatusCode() == 200) {
            return PHOCSWLSWaterRightsWrapper.parse(res.getBody());
        } else {
            throw new CalloutException('Error fetching water rights: ' + res.getBody());
        }
    }
}