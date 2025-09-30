@IsTest
global class PHOCSGwellsServiceMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        String endpoint = req.getEndpoint();
        
        // Decide which mock response to return based on endpoint
        if (endpoint.contains('/wells/')) {
            res.setBody(PHOCSWellResponseWrapperTest.getResponse());
            res.setStatusCode(200);
        } else if (endpoint.contains('/aquifers/')) {
            res.setBody(PHOCSAquifersResponseWrapperTest.getResponse());
            res.setStatusCode(200);
        } else {
            res.setStatusCode(404);
            res.setBody('{"error": "Not Found"}');
        }        
        return res;
    }
}