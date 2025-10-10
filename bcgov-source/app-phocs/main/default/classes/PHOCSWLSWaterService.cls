public class PHOCSWLSWaterService {
    // Fetch Water Rights by Licence Number
    public static PHOCSWLSWaterRightsWrapper getWaterRightsByLicence(String licenceNumber) {
        String endpoint = 'https://openmaps.gov.bc.ca/geo/pub/WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV/ows' +
            '?service=WFS&version=2.0.0&request=GetFeature' +
            '&typeNames=pub:WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_LICENCES_SV' +
            '&outputFormat=application/json' +
            '&CQL_FILTER=LICENCE_NUMBER=%27' + licenceNumber + '%27';
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
        String endpoint = 'https://openmaps.gov.bc.ca/geo/pub/WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_APPLICTNS_SV/ows' +
            '?service=WFS&version=2.0.0&request=GetFeature' +
            '&outputFormat=application/json' +
            '&CQL_FILTER=APPLICATION_JOB_NUMBER=%27' + applicationJobNumber + '%27' +
            '&typeNames=pub:WHSE_WATER_MANAGEMENT.WLS_WATER_RIGHTS_APPLICTNS_SV';
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