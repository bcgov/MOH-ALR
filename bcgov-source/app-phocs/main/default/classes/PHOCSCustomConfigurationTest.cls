@isTest
public class PHOCSCustomConfigurationTest {

    @isTest
    public static void testRemoveHtmlTags() {
        // Prepare the test input data
        List<PHOCSCustomConfiguration.HtmlInput> testInputs = new List<PHOCSCustomConfiguration.HtmlInput>();
        
        // Create test case 1: A valid encoded HTML string
        PHOCSCustomConfiguration.HtmlInput input1 = new PHOCSCustomConfiguration.HtmlInput();
        input1.htmlContent = '_HL_ENCODED_/001bZ000008XMq5QAG_HL_Vancouver Coastal_HL__self_HL_';
        testInputs.add(input1);
        
        // Create test case 2: Another HTML string with HTML tags
        PHOCSCustomConfiguration.HtmlInput input2 = new PHOCSCustomConfiguration.HtmlInput();
        input2.htmlContent = '_HL_ENCODED_/001bZ000008XMq5QAG_HL_Hello World_HL__blank_HL_';
        testInputs.add(input2);

        // Create test case 3: Input with no HTML tags
        PHOCSCustomConfiguration.HtmlInput input3 = new PHOCSCustomConfiguration.HtmlInput();
        input3.htmlContent = '_HL_ENCODED_/001bZ000008XMq5QAG_HL_Test String_HL__top_HL_';
        testInputs.add(input3);
        
        // Create test case 4: Empty input
        PHOCSCustomConfiguration.HtmlInput input4 = new PHOCSCustomConfiguration.HtmlInput();
        input4.htmlContent = '';
        testInputs.add(input4);

        // Execute the method
        Test.startTest();
        List<PHOCSCustomConfiguration.HtmlOutput> results = PHOCSCustomConfiguration.removeHtmlTags(testInputs);
        Test.stopTest();
        
        // Assert results
        System.assertEquals(results.size(), 4, 'There should be 4 results');

       
    }
}