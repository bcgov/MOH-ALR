@IsTest
global class PHOCSMonerisServerErrorMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'application/json');        
        res.setStatusCode(500);
        res.setStatus('Internal Server Error');
        res.setBody('{"error": "something went wrong"}');
        
        return res;
    }
}