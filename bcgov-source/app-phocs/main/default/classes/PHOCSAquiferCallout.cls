/*
    Created by: Pawan Atri
    Created Date: 16-Sept-2025
    User Story: EHIS-1425
    Title: Service class for Aquifer API integration
    Description: Handles callouts to Aquifer endpoints and maps responses into wrapper classes
*/
public class PHOCSAquiferCallout {
    private static final String BASE_URL = System.Label.PHOCSGwellsBaseURL;
    
    /**
     * Get Aquifer details by Aquifer Number
     * @param aquiferNumber The Aquifer Number to query
     * @return PHOCSAquifersResponseWrapper object
     */
    public static PHOCSAquifersResponseWrapper getAquiferDetails(String aquiferNumber) {
        String endpoint = BASE_URL + '/aquifers/' + EncodingUtil.urlEncode(aquiferNumber, 'UTF-8');
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); // 2 minutes timeout

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {            
            return PHOCSAquifersResponseWrapper.parseJson(res.getBody());
        } else {
            throw new CalloutException('Failed to fetch Aquifer details. Status Code: ' + res.getStatusCode());
        }
    }
}