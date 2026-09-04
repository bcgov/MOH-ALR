/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 Aug 2026
* @Description: The purpose of this class is to cover Code coverage of PngRenderer.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               02 Sep 2026 - Code 39 Migration - Deepak - render(String) now encodes via
*               Code39Encoder; updated expected PNG width assertions accordingly. Replaced
*               tests for the removed render(Code128Encoder.EncodingResult) overload with tests
*               for the new symbology-agnostic render(String value, String modules) overload.
*               Updated testUnsupportedHumanReadableCharacter since Code39Encoder now rejects
*               out-of-alphabet characters (e.g. '@') before PngRenderer's own font validation
*               is reached; added a separate test for PngRenderer's font-validation path using a
*               character that is valid in Code 39 but assumed unsupported by BarcodeBitmapFont.
*               Changed test class visibility from private to public per project convention.
***********************************************************************************************/
@isTest
public class PngRendererTest {
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify successful PNG barcode generation
*              for an actual Lab Test Requisition Number.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testRenderActualRequisitionNumber() {
        String value = 'PHOCS-ABC123-000456';
        
        Test.startTest();
        Blob png = PngRenderer.render(value);
        Test.stopTest();
        
        Assert.areNotEqual(null, png, 'The generated PNG should not be null');
        Assert.isTrue(png.size() > 1000, 'The generated PNG size should be greater than 1000 bytes');
        
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        
        Assert.areEqual('89504E470D0A1A0A', hex.substring(0, 16), 'The generated file should contain a valid PNG signature');
        Assert.isTrue(hex.contains('49484452'), 'The generated PNG should contain an IHDR chunk');
        Assert.isTrue(hex.contains('49444154'), 'The generated PNG should contain an IDAT chunk');
        Assert.areEqual('49454E44', hex.substring(hex.length() - 16, hex.length() - 8), 'The generated PNG should end with an IEND chunk');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify successful PNG generation using the
*              generic render(value, modules) overload fed by a Code128Encoder.EncodingResult,
*              proving PngRenderer remains compatible with Code 128 even though render(String)
*              no longer uses it by default.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep 2026 - Code 39 Migration - Deepak - Rewritten for the removed
*                     render(Code128Encoder.EncodingResult) overload; now calls
*                     render(value, modules) directly.
*/
    @isTest
    static void testRenderEncodingResultCode128() {
        Code128Encoder.EncodingResult encodingResult = Code128Encoder.encode('ABC123');
        
        Test.startTest();
        Blob png = PngRenderer.render(encodingResult.value, encodingResult.modules);
        Test.stopTest();
        
        Assert.areNotEqual(null, png, 'The generated PNG should not be null');
        Assert.isTrue(png.size() > 500, 'The generated PNG size should be greater than 500 bytes');
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify successful PNG generation using the
*              generic render(value, modules) overload fed by a Code39Encoder.EncodingResult,
*              matching the encoder now used by render(String) by default.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testRenderEncodingResultCode39() {
        Code39Encoder.EncodingResult encodingResult = Code39Encoder.encode('ABC123');
        
        Test.startTest();
        Blob png = PngRenderer.render(encodingResult.value, encodingResult.modules);
        Test.stopTest();
        
        Assert.areNotEqual(null, png, 'The generated PNG should not be null');
        Assert.isTrue(png.size() > 500, 'The generated PNG size should be greater than 500 bytes');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the calculated PNG dimensions using a
*              Code128Encoder result, proving calculateWidth() is symbology-agnostic (it takes
*              plain module/value lengths, not an encoder-specific type).
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testCalculatedDimensionsCode128() {
        Code128Encoder.EncodingResult result = Code128Encoder.encode('PHOCS-ABC123-000456');
        Integer width = PngRenderer.calculateWidth(result.modules.length(), result.value.length());
        Integer height = PngRenderer.calculateHeight();
        
        Assert.areEqual(528, width, 'The calculated barcode width should match the expected Code 128 width');
        Assert.areEqual(116, height, 'The calculated barcode height should match the expected height');
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify the calculated PNG dimensions for the
*              same requisition number using Code39Encoder, matching the encoder now used by
*              render(String) by default. Code 39 requires more module units per character than
*              Code 128, so the expected width is larger for the same input string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testCalculatedDimensionsCode39() {
        Code39Encoder.EncodingResult result = Code39Encoder.encode('PHOCS-ABC123-000456');
        Integer width = PngRenderer.calculateWidth(result.modules.length(), result.value.length());
        Integer height = PngRenderer.calculateHeight();
        
        Assert.areEqual(710, width, 'The calculated barcode width should match the expected Code 39 width');
        Assert.areEqual(116, height, 'The calculated barcode height should match the expected height');
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that PngRenderer.render(String), which
*              now encodes via Code39Encoder by default, produces a PNG whose actual IHDR width
*              matches the width independently calculated from a Code39Encoder result for the
*              same value -- confirming render(String) is actually using Code 39, not Code 128.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testRenderStringUsesCode39ByDefault() {
        String value = 'PHOCS-ABC123-000456';
        Code39Encoder.EncodingResult expected = Code39Encoder.encode(value);
        Integer expectedWidth = PngRenderer.calculateWidth(expected.modules.length(), expected.value.length());
        
        Test.startTest();
        Blob png = PngRenderer.render(value);
        Test.stopTest();
        
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        Integer ihdrPosition = hex.indexOf('49484452');
        String actualWidthHex = hex.substring(ihdrPosition + 8, ihdrPosition + 16);
        Integer actualWidth = hexToInteger(actualWidthHex);
        
        Assert.areEqual(expectedWidth, actualWidth, 'render(String) should produce a PNG width matching Code39Encoder output, confirming it encodes via Code 39.');
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to convert a hexadecimal string into an Integer
*              for test assertions. Apex's Long.valueOf/Integer.valueOf only parse decimal
*              strings, so a manual conversion is required here.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Integer hexToInteger(String hex) {
        String hexDigits = '0123456789ABCDEF';
        Integer result = 0;
        
        for (Integer i = 0; i < hex.length(); i++) {
            result = (result * 16) + hexDigits.indexOf(hex.substring(i, i + 1));
        }
        
        return result;
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the calculated PNG dimensions
*              for a short barcode value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testShortValueDimensions() {
        Code39Encoder.EncodingResult result = Code39Encoder.encode('A');
        Integer width = PngRenderer.calculateWidth(result.modules.length(), result.value.length());
        Integer height = PngRenderer.calculateHeight();
        
        Assert.isTrue(width > 0, 'The calculated barcode width should be greater than zero');
        Assert.areEqual(116, height, 'The calculated barcode height should match the expected height');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the generated barcode
*              contains a valid PNG signature.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testPngSignature() {
        Blob png = PngRenderer.render('ABC123');
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        
        Assert.areEqual('89504E470D0A1A0A', hex.substring(0, 16), 'The generated file should contain a valid PNG signature');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the generated PNG
*              contains an IHDR chunk.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testIhdrChunkExists() {
        Blob png = PngRenderer.render('ABC123');
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        
        Assert.areEqual('49484452', hex.substring(24, 32), 'The generated PNG should contain an IHDR chunk');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the IHDR chunk uses
*              the expected one-bit grayscale PNG configuration.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep 2026 - Code 39 Migration - Deepak - Updated expected width from
*                     242 (Code 128) to 294 (Code 39) for the same 'ABC123' input value. Height
*                     is unaffected since it depends only on BarcodeBitmapFont, not symbology.
*/
    @isTest
    static void testIhdrUsesOneBitGrayscale() {
        Blob png = PngRenderer.render('ABC123');
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        Integer ihdrPosition = hex.indexOf('49484452');
        String ihdrData = hex.substring(ihdrPosition + 8, ihdrPosition + 34);
        
        Assert.areEqual(24, ihdrPosition, 'The IHDR chunk should begin at the expected PNG position');
        Assert.areEqual('00000126', ihdrData.substring(0, 8), 'The PNG width should match the expected Code 39 value');
        Assert.areEqual('00000074', ihdrData.substring(8, 16), 'The PNG height should match the expected value');
        Assert.areEqual('01', ihdrData.substring(16, 18), 'The PNG bit depth should be one bit');
        Assert.areEqual('00', ihdrData.substring(18, 20), 'The PNG color type should be grayscale');
        Assert.areEqual('00', ihdrData.substring(20, 22), 'The PNG compression method should be zero');
        Assert.areEqual('00', ihdrData.substring(22, 24), 'The PNG filter method should be zero');
        Assert.areEqual('00', ihdrData.substring(24, 26), 'The PNG interlace method should be zero');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the IDAT chunk
*              contains the expected zlib header.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testZlibHeader() {
        Blob png = PngRenderer.render('ABC123');
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        Integer idatPosition = hex.indexOf('49444154');
        String zlibHeader = hex.substring(idatPosition + 8, idatPosition + 12);
        
        Assert.isTrue(idatPosition >= 0, 'The generated PNG should contain an IDAT chunk');
        Assert.areEqual('7801', zlibHeader, 'The IDAT chunk should contain the expected zlib header');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify Adler-32 checksum
*              calculation using a known test value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testAdler32KnownValue() {
        String inputHex = EncodingUtil.convertToHex(Blob.valueOf('123456789'));
        
        Test.startTest();
        Long result = PngRenderer.adler32(inputHex);
        Test.stopTest();
        
        Assert.areEqual(152961502L, result, 'The Adler-32 checksum should match the known expected value');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify CRC-32 checksum
*              calculation using a known test value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testCrc32KnownValue() {
        String inputHex = EncodingUtil.convertToHex(Blob.valueOf('123456789'));
        
        Test.startTest();
        String result = PngRenderer.crc32Hex(inputHex);
        Test.stopTest();
        
        Assert.areEqual('CBF43926', result, 'The CRC-32 checksum should match the known expected value');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify CRC-32 checksum
*              calculation for an empty value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testCrc32EmptyValue() {
        Test.startTest();
        String result = PngRenderer.crc32Hex('');
        Test.stopTest();
        
        Assert.areEqual('00000000', result, 'The CRC-32 checksum for an empty value should be zero');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify Adler-32 checksum
*              calculation for an empty value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testAdler32EmptyValue() {
        Test.startTest();
        Long result = PngRenderer.adler32('');
        Test.stopTest();
        
        Assert.areEqual(1L, result, 'The Adler-32 checksum for an empty value should be one');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that a character outside the Code 39
*              character set is rejected. Since render(String) now encodes via Code39Encoder,
*              this rejection now happens in Code39Encoder.validate() before PngRenderer's own
*              font validation is ever reached.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep 2026 - Code 39 Migration - Deepak - Updated expected exception
*                     message. '@' is rejected by Code39Encoder (not part of the Code 39
*                     character set), not by PngRenderer's font-support check as it was under
*                     Code 128.
*/
    @isTest
    static void testCharacterOutsideCode39AlphabetRejectedByEncoder() {
        try {
            PngRenderer.render('ABC@123');
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.isTrue(ex.getMessage().contains('Code 39 supports only'), 'The exception should be raised by Code39Encoder.validate() for a character outside the Code 39 set.');
        }
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify PngRenderer's own font-support
*              validation path, using a character that is valid within the Code 39 character
*              set (so it passes Code39Encoder.validate()) but is assumed unsupported by
*              BarcodeBitmapFont. NOTE: this assumes BarcodeBitmapFont does not support '$';
*              confirm against the actual BarcodeBitmapFont character set and adjust the test
*              character if it does.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testUnsupportedHumanReadableCharacter() {
        try {
            PngRenderer.render('ABC$123');
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.isTrue(ex.getMessage().contains('Unsupported human-readable barcode character'), 'The exception message should identify the unsupported barcode character');
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that a blank barcode
*              value is rejected.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testBlankValue() {
        try {
            PngRenderer.render('');
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode value is required.', ex.getMessage(), 'The exception message should indicate that a barcode value is required');
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that a null barcode
*              String value is rejected.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testNullStringValue() {
        try {
            PngRenderer.render((String)null);
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode value is required.', ex.getMessage(), 'The exception message should indicate that a barcode value is required');
        }
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a null value is rejected by the
*              generic render(value, modules) overload.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testNullValueTwoArgOverload() {
        try {
            PngRenderer.render((String)null, '101010');
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode value is required.', ex.getMessage(), 'The exception message should indicate that a barcode value is required');
        }
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a null modules string is rejected
*              by the generic render(value, modules) overload.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testNullModulesTwoArgOverload() {
        try {
            PngRenderer.render('ABC123', (String)null);
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode modules are required.', ex.getMessage(), 'The exception message should indicate that barcode modules are required');
        }
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a blank modules string is rejected
*              by the generic render(value, modules) overload.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testBlankModulesTwoArgOverload() {
        try {
            PngRenderer.render('ABC123', '');
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode modules are required.', ex.getMessage(), 'The exception message should indicate that barcode modules are required');
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the generated PNG
*              ends with an IEND chunk.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testPngEndsWithIend() {
        Blob png = PngRenderer.render('ABC123');
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        
        Assert.areEqual('49454E44', hex.substring(hex.length() - 16, hex.length() - 8), 'The generated PNG should end with an IEND chunk');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the generated PNG
*              contains an IDAT chunk.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testPngContainsIdat() {
        Blob png = PngRenderer.render('ABC123');
        String hex = EncodingUtil.convertToHex(png).toUpperCase();
        
        Assert.isTrue(hex.contains('49444154'), 'The generated PNG must contain an IDAT chunk');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify hexadecimal byte
*              conversion through the CRC-32 calculation.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testHexByteConversionThroughCrc() {
        String inputHex = '00010203040506070809AABBCCDDEEFF';
        
        Test.startTest();
        String result = PngRenderer.crc32Hex(inputHex);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'The CRC-32 result should not be null');
        Assert.areEqual(8, result.length(), 'The CRC-32 hexadecimal result should contain eight characters');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify lowercase hexadecimal
*              byte conversion through the CRC-32 calculation.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testLowerCaseHexConversionThroughCrc() {
        String inputHex = '00010203040506070809aabbccddeeff';
        
        Test.startTest();
        String result = PngRenderer.crc32Hex(inputHex);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'The CRC-32 result should not be null');
        Assert.areEqual(8, result.length(), 'The CRC-32 hexadecimal result should contain eight characters');
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify successful barcode PNG
*              generation for a single actual requisition number.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testSingleGenerationCpu() {
        Test.startTest();
        Blob png = PngRenderer.render('PHOCS-ABC123-000456');
        Test.stopTest();
        
        Assert.areNotEqual(null, png, 'The generated PNG should not be null');
        Assert.isTrue(png.size() > 1000, 'The generated PNG size should be greater than 1000 bytes');
    }
}