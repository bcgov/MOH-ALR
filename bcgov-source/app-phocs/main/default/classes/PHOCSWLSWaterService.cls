public class PHOCSWLSWaterService {
    // Fetch Water Rights by Licence Number
    public static PHOCSWLSWaterRightsWrapper getWaterRightsByLicence(String licenceNumber) {
        // Get URL from Custom Label
		String baseUrl = System.Label.PHOCSWaterRightLicenseNumberURL;
        // Replace placeholder with actual value
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
    
    // Fetch Water Applications by Application Job Number
    public static PHOCSWLSWaterApplicationsWrapper getWaterApplicationsByJob(String applicationJobNumber) {
        // Get URL from Custom Label
		String baseUrl = System.Label.PHOCSWaterRightApplicationNumberURL;
        // Replace placeholder with actual value
        String endpoint = baseUrl.replace('{ApplicationNumber}', applicationJobNumber);
        
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