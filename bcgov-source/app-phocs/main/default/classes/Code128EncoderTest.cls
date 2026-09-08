/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 Aug 2026
* @Description: The purpose of this class is to cover Code coverage of Code128Encoder.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@isTest
public class Code128EncoderTest {
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify Code 128 Code Set B encoding for a simple
*              barcode value and validate the generated symbol values, checksum, patterns and modules.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testEncodeSimpleCode128BValue() {
        String value = 'ABC123';
        
        Test.startTest();
        Code128Encoder.EncodingResult result = Code128Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(value, result.value);
        Assert.areEqual(9, result.symbolValues.size());
        Assert.areEqual(104, result.symbolValues[0]);
        Assert.areEqual(33, result.symbolValues[1]);
        Assert.areEqual(34, result.symbolValues[2]);
        Assert.areEqual(35, result.symbolValues[3]);
        Assert.areEqual(17, result.symbolValues[4]);
        Assert.areEqual(18, result.symbolValues[5]);
        Assert.areEqual(19, result.symbolValues[6]);
        Assert.areEqual(67, result.symbolValues[7]);
        Assert.areEqual(106, result.symbolValues[8]);
        Assert.areEqual(67, result.checksum);
        Assert.areEqual(9, result.patterns.size());
        Assert.areEqual(101, result.modules.length());
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify Code 128 encoding for an actual Lab Test
*              Requisition Number and validate the generated barcode encoding result.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testEncodeActualRequisitionNumber() {
        String value = 'PHOCS-ABC123-000456';
        
        Test.startTest();
        Code128Encoder.EncodingResult result = Code128Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(value, result.value);
        Assert.areEqual(value.length() + 3, result.symbolValues.size());
        Assert.areEqual(104, result.symbolValues[0]);
        Assert.areEqual(106, result.symbolValues[result.symbolValues.size() - 1]);
        Assert.areEqual(Code128Encoder.calculateChecksum(value), result.checksum);
        Assert.areEqual(result.symbolValues.size(), result.patterns.size());
        Assert.areEqual((result.symbolValues.size() * 11) + 2, result.modules.length());
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the Code 128 checksum calculation for
*              a barcode value using the Code Set B checksum formula.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testChecksumCalculation() {
        String value = 'ABC123';
        Integer expectedChecksum = Math.mod(104 + (33 * 1) + (34 * 2) + (35 * 3) + (17 * 4) + (18 * 5) + (19 * 6), 103);
        
        Test.startTest();
        Integer actualChecksum = Code128Encoder.calculateChecksum(value);
        Test.stopTest();
        
        Assert.areEqual(expectedChecksum, actualChecksum);
        Assert.areEqual(67, actualChecksum);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the checksum calculation for a single
*              Code 128 Code Set B character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testSingleCharacterChecksum() {
        String value = 'A';
        
        Test.startTest();
        Integer checksum = Code128Encoder.calculateChecksum(value);
        Test.stopTest();
        
        Assert.areEqual(34, checksum);
        Assert.areEqual(Math.mod(104 + (33 * 1), 103), checksum);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the space character is correctly
*              encoded using Code 128 Code Set B.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testSpaceCharacter() {
        String value = ' A';
        
        Test.startTest();
        Code128Encoder.EncodingResult result = Code128Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(0, result.symbolValues[1]);
        Assert.areEqual(33, result.symbolValues[2]);
        Assert.areEqual(104, result.symbolValues[0]);
        Assert.areEqual(106, result.symbolValues[result.symbolValues.size() - 1]);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that ASCII character 127 is correctly
*              supported and encoded using Code 128 Code Set B.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testAscii127Character() {
        String value = String.fromCharArray(new List<Integer>{127});
        
        Test.startTest();
        Code128Encoder.EncodingResult result = Code128Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(95, result.symbolValues[1]);
        Assert.areEqual(104, result.symbolValues[0]);
        Assert.areEqual(106, result.symbolValues[result.symbolValues.size() - 1]);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that all supported requisition characters
*              are correctly encoded using Code 128 Code Set B.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testAllSupportedRequisitionCharacters() {
        String value = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-';
        
        Test.startTest();
        Code128Encoder.EncodingResult result = Code128Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(value.length() + 3, result.symbolValues.size());
        Assert.areEqual(value.length() + 3, result.patterns.size());
        
        for (Integer i = 0; i < value.length(); i++) {
            Assert.areEqual(value.charAt(i) - 32, result.symbolValues[i + 1]);
        }
        
        Assert.areEqual(104, result.symbolValues[0]);
        Assert.areEqual(106, result.symbolValues[result.symbolValues.size() - 1]);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that all Code 128 symbol values have
*              valid barcode patterns containing both bars and spaces.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testAllCode128PatternsExist() {
        for (Integer i = 0; i <= 106; i++) {
            String pattern = Code128Encoder.getPattern(i);
            
            Assert.areNotEqual(null, pattern);
            Assert.areEqual(11, pattern.length(), 'Unexpected pattern length for symbol ' + i);
            Assert.isTrue(pattern.contains('1'), 'Pattern must contain bars for symbol ' + i);
            Assert.isTrue(pattern.contains('0'), 'Pattern must contain spaces for symbol ' + i);
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the Code 128 pattern table contains
*              valid patterns for all 107 Code 128 symbol values.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testPatternTableContainsExactly107Entries() {
        Integer validPatternCount = 0;
        
        for (Integer i = 0; i <= 106; i++) {
            if (Code128Encoder.getPattern(i) != null) {
                validPatternCount++;
            }
        }
        
        Assert.areEqual(107, validPatternCount);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the Code 128 stop symbol pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testStopPattern() {
        String pattern = Code128Encoder.getPattern(106);
        
        Assert.areEqual(11, pattern.length());
        Assert.areEqual('11000111010', pattern);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the complete Code 128 stop pattern
*              including the final termination bars.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testCompleteStopPattern() {
        Code128Encoder.EncodingResult result = Code128Encoder.encode('A');
        String stopPattern = result.patterns[result.patterns.size() - 1];
        
        Assert.areEqual('11000111010', stopPattern);
        Assert.areEqual('1100011101011', stopPattern + '11');
        Assert.areEqual('11', result.modules.substring(result.modules.length() - 2));
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the Code 128 Start Code B pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testStartCodeBPattern() {
        String pattern = Code128Encoder.getPattern(104);
        
        Assert.areEqual(11, pattern.length());
        Assert.areEqual('11010010000', pattern);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the Code 128 Start Code A pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testStartCodeAPattern() {
        String pattern = Code128Encoder.getPattern(103);
        
        Assert.areEqual(11, pattern.length());
        Assert.areEqual('11010000100', pattern);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify the Code 128 Start Code C pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testStartCodeCPattern() {
        String pattern = Code128Encoder.getPattern(105);
        
        Assert.areEqual(11, pattern.length());
        Assert.areEqual('11010011100', pattern);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that an exception is thrown for an
*              invalid Code 128 symbol value greater than the supported range.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testInvalidSymbolValue() {
        try {
            Code128Encoder.getPattern(107);
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.isTrue(ex.getMessage().contains('Invalid Code 128 symbol value'));
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that an exception is thrown for a
*              negative Code 128 symbol value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testNegativeSymbolValue() {
        try {
            Code128Encoder.getPattern(-1);
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.isTrue(ex.getMessage().contains('Invalid Code 128 symbol value'));
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that an exception is thrown when a blank
*              barcode value is provided for encoding.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testBlankValue() {
        try {
            Code128Encoder.encode('');
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode value is required.', ex.getMessage());
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that an exception is thrown when a null
*              barcode value is provided for encoding.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testNullValue() {
        try {
            Code128Encoder.encode(null);
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.areEqual('Barcode value is required.', ex.getMessage());
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that an exception is thrown when a
*              character outside the supported Code 128 Code Set B ASCII range is provided.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testUnsupportedCharacter() {
        String value = 'ABC' + String.fromCharArray(new List<Integer>{31});
        
        try {
            Code128Encoder.encode(value);
            Assert.fail('Expected IllegalArgumentException.');
        } catch (IllegalArgumentException ex) {
            Assert.isTrue(ex.getMessage().contains('ASCII characters 32 through 127'));
        }
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to verify that the calculated Code 128 checksum
*              remains within the valid modulo 103 range.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @isTest
    static void testChecksumModulo103() {
        String value = 'PHOCS-ABC123-000456';
        Integer checksum = Code128Encoder.calculateChecksum(value);
        
        Assert.isTrue(checksum >= 0);
        Assert.isTrue(checksum <= 102);
    }
}