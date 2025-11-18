@IsTest
global class PHOCSAquiferMock implements HttpCalloutMock {
    
    global Boolean isBlankResponse = false;
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        String endpoint = req.getEndpoint();
        
        // Decide which mock response to return based on endpoint
        if (endpoint.contains('/aquifers/')) {
            if(!isBlankResponse)
                res.setBody(PHOCSAquifersResponseWrapperTest.getResponse());
            else
                res.setBody(PHOCSAquifersResponseWrapperTest.getBlankResponse());
            res.setStatusCode(200);
        } else {
            res.setStatusCode(404);
            res.setBody('{"error": "Not Found"}');
        }        
        return res;
    }
}