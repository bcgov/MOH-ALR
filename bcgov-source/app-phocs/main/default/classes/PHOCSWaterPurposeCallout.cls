public class PHOCSWaterPurposeCallout {
    public static PHOCSWLSWaterRightsWrapper getWaterRightsByPurposeCode(String purposeCode) {
        String baseUrl = System.Label.PHOCSWaterRightsPurposeCodeURL;
        String endpoint = baseUrl.replace('{PurposeCode}', purposeCode);
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