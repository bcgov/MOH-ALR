@isTest
public class PHOCSPortalContactControllerTest {
    @IsTest
    static void testGetPortalContactDetails() {
        
        Test.startTest();
        
        Id contactId = PHOCSPortalContactController.getPortalContactDetails();
        
        Test.stopTest();
        
        System.assertEquals(null, contactId);
    }
}