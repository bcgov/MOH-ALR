/**********************************************************************************************
* @Author:      Accenture
* @Date:        02 Sep 2026
* @Description: The purpose of this class is to provide bitmap font definitions used to render
*               human-readable barcode values in generated barcode PNG images. The class provides
*               fixed 5x7 bitmap glyphs for supported uppercase alphabetic characters, numeric
*               characters, spaces, and hyphens.
*
*               Each glyph is represented as a list of seven strings, where each string represents
*               one row of the glyph. A value of '1' represents a filled pixel and a value of '0'
*               represents an empty pixel.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public with sharing class BarcodeBitmapFont {
    private static final Integer GLYPH_WIDTH = 5;
    private static final Integer GLYPH_HEIGHT = 7;
    private static final Map<String, List<String>> GLYPHS = buildGlyphs();
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to return the fixed width, in pixels, of each
*              bitmap font glyph.
* @return Width of each bitmap font glyph.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Integer getWidth() {
        return GLYPH_WIDTH;
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to return the fixed height, in pixels, of each
*              bitmap font glyph.
* @return Height of each bitmap font glyph.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Integer getHeight() {
        return GLYPH_HEIGHT;
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to return the bitmap glyph definition for the
*              provided supported character.
*
*              Each returned list contains seven rows. Each row contains five characters where
*              '1' represents a filled pixel and '0' represents an empty pixel.
* @param character Character for which the bitmap glyph is required.
* @return List of bitmap rows representing the requested character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static List<String> getGlyph(String character) {
        if (character == null) {
            throw new IllegalArgumentException('Font character cannot be null.');
        }
        
        List<String> glyph = GLYPHS.get(character);
        
        if (glyph == null) {
            throw new IllegalArgumentException('Unsupported bitmap font character: ' + character);
        }
        
        return glyph;
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to determine whether the provided character is
*              supported by the bitmap font.
* @param character Character to validate against the supported bitmap font characters.
* @return True when the character is supported; otherwise false.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Boolean supports(String character) {
        return character != null && GLYPHS.containsKey(character);
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to build and return the complete collection of
*              supported 5x7 bitmap font glyph definitions used when rendering human-readable
*              barcode values.
*
*              The supported character set includes uppercase alphabetic characters A-Z,
*              numeric characters 0-9, spaces, and hyphens.
* @return Map containing the supported characters and their corresponding 5x7 bitmap glyphs.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Map<String, List<String>> buildGlyphs() {
        Map<String, List<String>> glyphs = new Map<String, List<String>>();
        
        glyphs.put(' ', new List<String>{'00000','00000','00000','00000','00000','00000','00000'});
        glyphs.put('-', new List<String>{'00000','00000','00000','11111','00000','00000','00000'});
        
        glyphs.put('A', new List<String>{'01110','10001','10001','11111','10001','10001','10001'});
        glyphs.put('B', new List<String>{'11110','10001','10001','11110','10001','10001','11110'});
        glyphs.put('C', new List<String>{'01111','10000','10000','10000','10000','10000','01111'});
        glyphs.put('D', new List<String>{'11110','10001','10001','10001','10001','10001','11110'});
        glyphs.put('E', new List<String>{'11111','10000','10000','11110','10000','10000','11111'});
        glyphs.put('F', new List<String>{'11111','10000','10000','11110','10000','10000','10000'});
        glyphs.put('G', new List<String>{'01111','10000','10000','10111','10001','10001','01111'});
        glyphs.put('H', new List<String>{'10001','10001','10001','11111','10001','10001','10001'});
        glyphs.put('I', new List<String>{'11111','00100','00100','00100','00100','00100','11111'});
        glyphs.put('J', new List<String>{'00111','00010','00010','00010','10010','10010','01100'});
        glyphs.put('K', new List<String>{'10001','10010','10100','11000','10100','10010','10001'});
        glyphs.put('L', new List<String>{'10000','10000','10000','10000','10000','10000','11111'});
        glyphs.put('M', new List<String>{'10001','11011','10101','10101','10001','10001','10001'});
        glyphs.put('N', new List<String>{'10001','11001','10101','10011','10001','10001','10001'});
        glyphs.put('O', new List<String>{'01110','10001','10001','10001','10001','10001','01110'});
        glyphs.put('P', new List<String>{'11110','10001','10001','11110','10000','10000','10000'});
        glyphs.put('Q', new List<String>{'01110','10001','10001','10001','10101','10010','01101'});
        glyphs.put('R', new List<String>{'11110','10001','10001','11110','10100','10010','10001'});
        glyphs.put('S', new List<String>{'01111','10000','10000','01110','00001','00001','11110'});
        glyphs.put('T', new List<String>{'11111','00100','00100','00100','00100','00100','00100'});
        glyphs.put('U', new List<String>{'10001','10001','10001','10001','10001','10001','01110'});
        glyphs.put('V', new List<String>{'10001','10001','10001','10001','10001','01010','00100'});
        glyphs.put('W', new List<String>{'10001','10001','10001','10101','10101','11011','10001'});
        glyphs.put('X', new List<String>{'10001','10001','01010','00100','01010','10001','10001'});
        glyphs.put('Y', new List<String>{'10001','10001','01010','00100','00100','00100','00100'});
        glyphs.put('Z', new List<String>{'11111','00001','00010','00100','01000','10000','11111'});
        
        glyphs.put('0', new List<String>{'01110','10001','10011','10101','11001','10001','01110'});
        glyphs.put('1', new List<String>{'00100','01100','00100','00100','00100','00100','01110'});
        glyphs.put('2', new List<String>{'01110','10001','00001','00010','00100','01000','11111'});
        glyphs.put('3', new List<String>{'11110','00001','00001','01110','00001','00001','11110'});
        glyphs.put('4', new List<String>{'00010','00110','01010','10010','11111','00010','00010'});
        glyphs.put('5', new List<String>{'11111','10000','10000','11110','00001','00001','11110'});
        glyphs.put('6', new List<String>{'01110','10000','10000','11110','10001','10001','01110'});
        glyphs.put('7', new List<String>{'11111','00001','00010','00100','01000','01000','01000'});
        glyphs.put('8', new List<String>{'01110','10001','10001','01110','10001','10001','01110'});
        glyphs.put('9', new List<String>{'01110','10001','10001','01111','00001','00001','01110'});
        
        return glyphs;
    }
}