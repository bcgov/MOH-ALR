@IsTest
global class PHOCSMonerisTicketMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();

        // === Simulate valid Moneris response ===
        String body = JSON.serialize(new Map<String, Object>{
            'response' => new Map<String, Object>{
                'ticket' => '1760676466VKD7ZaaBL9L8MnSYLg9TiPVf6VJtRT',
                'response_code' => '001',
                'success' => 'true'
            }
        });

        res.setHeader('Content-Type', 'application/json');
        res.setBody(body);
        res.setStatusCode(200);

        return res;
    }
}