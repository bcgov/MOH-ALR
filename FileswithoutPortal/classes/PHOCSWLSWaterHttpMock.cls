@IsTest
global class PHOCSWLSWaterHttpMock implements HttpCalloutMock {
    
    global Boolean isBlankResponse = false;

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String endpoint = req.getEndpoint();

        if(endpoint.contains('WLS_WATER_RIGHTS_LICENCES_SV')) {
            // Mock response for Water Rights
            if(!isBlankResponse)
                res.setBody(PHOCSWLSWaterRightsWrapperTest.getResponse());
            else
                res.setBody(PHOCSWLSWaterRightsWrapperTest.getBlankResponse());
            
        } else if(endpoint.contains('WLS_WATER_RIGHTS_APPLICTNS_SV')) {
            // Mock response for Water Applications
            if(!isBlankResponse)
                res.setBody(PHOCSWLSWaterApplicationsWrapperTest.getResponse());
            else
                res.setBody(PHOCSWLSWaterApplicationsWrapperTest.getBlankResponse());
        }
        return res;
    }
}