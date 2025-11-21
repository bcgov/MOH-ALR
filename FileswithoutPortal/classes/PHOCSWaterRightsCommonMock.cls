@IsTest
public class PHOCSWaterRightsCommonMock implements HttpCalloutMock {
    
    public Boolean isBlankResponse = false;
    
    public HTTPResponse respond(HTTPRequest req) {
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
        } 
        if(endpoint.contains('WLS_WATER_RIGHTS_APPLICTNS_SV')) {
            // Mock response for Water Applications
            if(!isBlankResponse)
                res.setBody(PHOCSWLSWaterApplicationsWrapperTest.getResponse());
            else
                res.setBody(PHOCSWLSWaterApplicationsWrapperTest.getBlankResponse());
        }
        if (endpoint.contains('/wells/')) {
            if(!isBlankResponse)
                res.setBody(PHOCSWellResponseWrapperTest.getResponse());   
            else
                res.setBody(PHOCSWellResponseWrapperTest.getBlankResponse());  
        }
        if (endpoint.contains('/aquifers/')) {
            if(!isBlankResponse)
                res.setBody(PHOCSAquifersResponseWrapperTest.getResponse());
            else
                res.setBody(PHOCSAquifersResponseWrapperTest.getBlankResponse());
        }
        return res;
    }
}