@IsTest
global class PHOCSWaterRightsCommonMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();

        if(endpoint.contains('WLS_WATER_RIGHTS_LICENCES_SV')) {
            // Mock response for Water Rights
            res.setBody(PHOCSWLSWaterRightsWrapperTest.getResponse());
        } 
        if(endpoint.contains('WLS_WATER_RIGHTS_APPLICTNS_SV')) {
            // Mock response for Water Applications
            res.setBody(PHOCSWLSWaterApplicationsWrapperTest.getResponse());
        }
        if (endpoint.contains('/wells/')) {
            res.setBody(PHOCSWellResponseWrapperTest.getResponse());            
        }
        if (endpoint.contains('/aquifers/')) {
            res.setBody(PHOCSAquifersResponseWrapperTest.getResponse());
        }
        res.setStatusCode(200);
        return res;
    }
}