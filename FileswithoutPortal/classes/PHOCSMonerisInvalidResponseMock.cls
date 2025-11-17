@IsTest
global class PHOCSMonerisInvalidResponseMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        
        res.setHeader('Content-Type', 'application/json');        
        res.setStatusCode(200);
        res.setBody('{"unexpected":"structure"}');
        
        return res;
    }
}