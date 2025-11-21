@IsTest
public class PHOCSWaterRightsServerErrorMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(500);
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"Error": "Server Error"}');
        return res;
    }
}