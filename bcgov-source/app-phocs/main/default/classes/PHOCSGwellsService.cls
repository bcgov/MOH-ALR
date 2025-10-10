/*
    Created by: Pawan Atri
    Date: 2025-09-16
    User Story: EHIS-1425
    Title: Service class for GWells API integration
    Description: Handles callouts to Well and Aquifer endpoints and maps responses into wrapper classes
*/

public with sharing class PHOCSGwellsService {
    
    private static final String BASE_URL = 'https://apps.nrs.gov.bc.ca/gwells/api/v2';
    
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
            System.debug('==== Well API Response: ' + res.getBody());
            return (PHOCSWellResponseWrapper) JSON.deserialize(res.getBody(), PHOCSWellResponseWrapper.class);
        } else {
            System.debug('**** Failed Well API Call. Status: ' + res.getStatus() + ' Body: ' + res.getBody());
            throw new CalloutException('Failed to fetch Well details. Status Code: ' + res.getStatusCode());
        }
    }

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
            System.debug('==== Aquifer API Response: ' + res.getBody());
            return (PHOCSAquifersResponseWrapper) JSON.deserialize(res.getBody(), PHOCSAquifersResponseWrapper.class);
        } else {
            System.debug('**** Failed Aquifer API Call. Status: ' + res.getStatus() + ' Body: ' + res.getBody());
            throw new CalloutException('Failed to fetch Aquifer details. Status Code: ' + res.getStatusCode());
        }
    }
}