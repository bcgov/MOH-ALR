/*
    Created by: Pawan Atri
    Date: 2025-09-16
    User Story: EHIS-1425
    Title: Service class for GWells API integration
    Description: Handles callouts to Well endpoints and maps responses into wrapper classes
*/
public class PHOCSWellCallout {
    private static final String BASE_URL = System.Label.PHOCSGwellsBaseURL;
    
    /**
     * Get Well details by Well Tag Number
     * @param wellTagNumber The Well Tag Number to query
     * @return PHOCSWellResponseWrapper object
     */
    public static PHOCSWellResponseWrapper getWellDetails(String wellTagNumber) {
        String endpoint = BASE_URL + '/wells/' + EncodingUtil.urlEncode(wellTagNumber, 'UTF-8');
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setTimeout(120000); // 2 minutes timeout

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {            
            return (PHOCSWellResponseWrapper) JSON.deserialize(res.getBody(), PHOCSWellResponseWrapper.class);
        } else {            
            throw new CalloutException('Failed to fetch Well details. Status Code: ' + res.getStatusCode());
        }
    }
}