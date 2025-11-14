public class PHOCSWaterPODCallout {
    public static PHOCSWLSWaterRightsWrapper getWaterRightsByPODNumber(String podNumber) {
        String baseUrl = System.Label.PHOCSWaterRightsPODNumberURL;
        String endpoint = baseUrl.replace('{PODNumber}', podNumber);
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