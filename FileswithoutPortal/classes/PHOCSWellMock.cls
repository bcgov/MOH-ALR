@IsTest
global class PHOCSWellMock implements HttpCalloutMock {
    
    global boolean isBlankResponse = false;
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        String endpoint = req.getEndpoint();
        
        // Decide which mock response to return based on endpoint
        if (endpoint.contains('/wells/')) {
            if(!isBlankResponse)
                res.setBody(PHOCSWellResponseWrapperTest.getResponse());
            else 
                res.setBody(PHOCSWellResponseWrapperTest.getBlankResponse());
            res.setStatusCode(200);
        } else {
            res.setStatusCode(404);
            res.setBody('{"error": "Not Found"}');
        }        
        return res;
    }
}