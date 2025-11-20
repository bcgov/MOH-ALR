/*
    Created by: Pawan Atri
    Date: 2025-09-16
    User Story: EHIS-1425
    Title: Service class for Water license API integration
    Description: Handles callouts to water application license endpoints and maps responses into wrapper classes
*/
public class PHOCSWaterApplicationCallout {

    public static PHOCSWLSWaterApplicationsWrapper getWaterApplicationsByJob(String applicationJobNumber, String podNumber, String purposeCode) {
		String baseUrl = System.Label.PHOCSWaterRightApplicationNumberURL;
        String endpoint = baseUrl.replace('{ApplicationNumber}', applicationJobNumber);
        endpoint = endpoint.replace('{PODNumber}', podNumber);
        endpoint = endpoint.replace('{PurposeCode}', purposeCode);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if(res.getStatusCode() == 200) {
            return PHOCSWLSWaterApplicationsWrapper.parse(res.getBody());
        } else {
            throw new CalloutException('Error fetching water applications: ' + res.getBody());
        }
    }
}