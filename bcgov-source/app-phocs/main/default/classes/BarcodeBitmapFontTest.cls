/**********************************************************************************************
* @Author:      Accenture
* @Date:        02 Sep 2026
* @Description: The purpose of this test class is to validate the functionality of the
*               BarcodeBitmapFont class, including glyph dimensions, supported characters,
*               glyph definitions, unsupported characters, and null character handling.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@IsTest
private class BarcodeBitmapFontTest {
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this test method is to verify that the bitmap font returns
*              the expected fixed glyph width and height.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testFontDimensions() {
        System.assertEquals(5, BarcodeBitmapFont.getWidth(), 'The bitmap font glyph width should be 5 pixels.');
        System.assertEquals(7, BarcodeBitmapFont.getHeight(), 'The bitmap font glyph height should be 7 pixels.');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this test method is to verify that every supported bitmap
*              font character has a valid glyph with the expected dimensions and contains
*              only valid binary pixel values.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testAllSupportedCharacters() {
        String characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789- ';
        
        for (Integer i = 0; i < characters.length(); i++) {
            String character = characters.substring(i, i + 1);
            System.assertEquals(true, BarcodeBitmapFont.supports(character), 'The bitmap font should support character: ' + character);
            
            List<String> glyph = BarcodeBitmapFont.getGlyph(character);
            System.assertEquals(7, glyph.size(), 'The bitmap font glyph should contain 7 rows for character: ' + character);
            
            for (String row : glyph) {
                System.assertEquals(5, row.length(), 'The bitmap font glyph row should contain 5 pixels for character: ' + character);
                
                for (Integer column = 0; column < row.length(); column++) {
                    Integer pixel = row.charAt(column);
                    System.assert(pixel == 48 || pixel == 49, 'The bitmap font glyph should contain only binary pixel values for character: ' + character);
                }
            }
        }
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this test method is to verify representative glyph definitions
*              for alphabetic, numeric, hyphen, and space characters.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testRepresentativeGlyphs() {
        System.assertEquals(new List<String>{'01110','10001','10001','11111','10001','10001','10001'}, BarcodeBitmapFont.getGlyph('A'), 'The bitmap glyph for A should match the expected definition.');
        System.assertEquals(new List<String>{'01110','10001','10011','10101','11001','10001','01110'}, BarcodeBitmapFont.getGlyph('0'), 'The bitmap glyph for 0 should match the expected definition.');
        System.assertEquals(new List<String>{'00000','00000','00000','11111','00000','00000','00000'}, BarcodeBitmapFont.getGlyph('-'), 'The bitmap glyph for the hyphen should match the expected definition.');
        System.assertEquals(new List<String>{'00000','00000','00000','00000','00000','00000','00000'}, BarcodeBitmapFont.getGlyph(' '), 'The bitmap glyph for the space character should match the expected definition.');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this test method is to verify that unsupported characters are
*              correctly identified and that requesting their glyph throws an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testUnsupportedCharacter() {
        System.assertEquals(false, BarcodeBitmapFont.supports('@'), 'The bitmap font should not support the @ character.');
        
        try {
            BarcodeBitmapFont.getGlyph('@');
            System.assert(false, 'Expected IllegalArgumentException for an unsupported bitmap font character.');
        } catch (IllegalArgumentException ex) {
            System.assert(ex.getMessage().contains('Unsupported bitmap font character'), 'The exception message should identify the unsupported bitmap font character.');
        }
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this test method is to verify that null characters are not
*              supported and that requesting a glyph for a null character throws an exception.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNullCharacter() {
        System.assertEquals(false, BarcodeBitmapFont.supports(null), 'The bitmap font should not support a null character.');
        
        try {
            BarcodeBitmapFont.getGlyph(null);
            System.assert(false, 'Expected IllegalArgumentException for a null bitmap font character.');
        } catch (IllegalArgumentException ex) {
            System.assertEquals('Font character cannot be null.', ex.getMessage(), 'The exception message should identify that the bitmap font character cannot be null.');
        }
    }
}