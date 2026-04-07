/**********************************************************************************************
* @Author:Accenture_PHOCS   
* @Date:      
* @Description: The purpose of this Class is to test Geocoder integration for PHOCS Accounts
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]  
                           EHIS-718               Vasanthi    Initial Version
***********************************************************************************************/
@isTest
private class GeocodeAddressQueueableTest {

    // Mock response to simulate geocode API
    private class GeocodeMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
			res.setBody(
            '{' +
              '"features": [' +
               '{' +
                  '"geometry": {' +
                       '"coordinates": [-123.123456, 49.123456]' +
                   '},' +
                '   "properties": {' +
                    '"postalCode": "V1V1V1",' +
                    '"fullAddress": "123 Mock St, Vancouver, BC"' +
                    '}' +
                 '}' +
               ']' +
            '}'
          );

            return res;
        }
    }

    @isTest
    static void testTriggerHandlerAndQueueableIntegration() {
        Id facilityRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Facility').getRecordTypeId();
        // Create test Account
        Account acct = new Account(
            Name = 'Trigger Test Account',
            RecordTypeId = facilityRtId,
            Physical_Address__Street__s = '456 Old Rd',
            Physical_Address__City__s = 'Oldtown',
            Physical_Address__StateCode__s = 'BC',
            Physical_Address__CountryCode__s = 'CA'
        );
        insert acct;

        // Set callout mock
        Test.setMock(HttpCalloutMock.class, new GeocodeMockResponse());

        Test.startTest();
        // Update the address to trigger the handler logic
        acct.Physical_Address__Street__s = '123 Mock St';
        acct.Physical_Address__City__s = 'Vancouver';
        update acct;
        Test.stopTest();

        // Validate that the geocoding job updated the record
        Account updated = [SELECT PhysicalLocation__Latitude__s, PhysicalLocation__Longitude__s, 
                                  Physical_Address__Street__s, Physical_Address__City__s, 
                                  Physical_Address__StateCode__s
                           FROM Account
                           WHERE Id = :acct.Id];

        System.assertEquals(49.123456, updated.PhysicalLocation__Latitude__s);
        System.assertEquals(-123.123456, updated.PhysicalLocation__Longitude__s);
        System.assertEquals('123 Mock St', updated.Physical_Address__Street__s);
        System.assertEquals('Vancouver', updated.Physical_Address__City__s);
        System.assertEquals('BC', updated.Physical_Address__StateCode__s);
    }
}