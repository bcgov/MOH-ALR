@IsTest
global class PHOCSWLSWaterHttpMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();

        if(endpoint.contains('WLS_WATER_RIGHTS_LICENCES_SV')) {
            // Mock response for Water Rights
            res.setBody(PHOCSWLSWaterRightsWrapperTest.getResponse());
        } else if(endpoint.contains('WLS_WATER_RIGHTS_APPLICTNS_SV')) {
            // Mock response for Water Applications
            res.setBody(PHOCSWLSWaterApplicationsWrapperTest.getResponse());
        }
        return res;
    }
}