/******************************************************************************************************
 * Date 			: 08-05-2025 
 * Description		: To provide custom logic which is not possible via configuration
 * Developer 		: Rahul Patle
 * User Story 		: EHIS-188 | AC-4
 *****************************************************************************************************/
public class PHOCSCustomConfiguration {
   public class HtmlInput {
        @InvocableVariable(label='HTML Content' description='The HTML content to be stripped')
        public String htmlContent;
    }

    public class HtmlOutput {
        @InvocableVariable(label='Plain Text' description='The plain text extracted from HTML')
        public String plainText;
    }

    @InvocableMethod(label='Remove HTML Tags' description='Strips HTML tags from the provided content')
    public static List<HtmlOutput> removeHtmlTags(List<HtmlInput> inputs) {
        List<HtmlOutput> results = new List<HtmlOutput>();
        for (HtmlInput input : inputs) {
            HtmlOutput output = new HtmlOutput();
            // Decode the encoded HTML content
            String decodedHtml = decodeHtmlContent(input.htmlContent);
            // Strip HTML tags and assign to plainText
            output.plainText = decodedHtml != null ? decodedHtml.stripHtmlTags() : null;
            results.add(output);
        }
        return results;
    }

    private static String decodeHtmlContent(String encodedContent) {
        // Replace encoded components with their original values
        if (encodedContent != null) {
            encodedContent = encodedContent.replace('_HL_ENCODED_', '')
                                           .replace('_HL_', '<')
                                           .replace('_HL__self_HL_', 'target="_self">')
                                           .replace('_HL__blank_HL_', 'target="_blank">')
                                           .replace('_HL__top_HL_', 'target="_top">')
                                           .replace('_HL__parent_HL_', 'target="_parent">')
                                           .replace('HL_', '>').replace('/','');
        }
        return encodedContent;
    }
}