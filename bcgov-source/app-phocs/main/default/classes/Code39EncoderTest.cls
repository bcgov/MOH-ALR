/**********************************************************************************************
* @Author:      Accenture
* @Date:        02 Sep 2026
* @Description: The purpose of this class is to cover code coverage of Code39Encoder and validate
*               Code 39 encoding, Modulo-43 checksum calculation, barcode patterns, supported
*               characters and exception scenarios.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
@IsTest
private class Code39EncoderTest {
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify successful Code 39 encoding without a
*              Modulo-43 checksum for a simple supported barcode value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testEncodeWithoutChecksum() {
        String value = 'ABC123';
        
        Test.startTest();
        Code39Encoder.EncodingResult result = Code39Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(value, result.value, 'The encoded value should match the input value');
        Assert.areEqual(false, result.checksumIncluded, 'Checksum should not be included by default');
        Assert.areEqual(null, result.checksum, 'Checksum should be null when checksum generation is not requested');
        Assert.areEqual(null, result.checksumCharacter, 'Checksum character should be null when checksum generation is not requested');
        Assert.areEqual(value.length() + 2, result.symbols.size(), 'Symbol count should include the start and stop characters');
        Assert.areEqual(value.length() + 2, result.patterns.size(), 'Pattern count should match the symbol count');
        Assert.areEqual('*', result.symbols[0], 'The first symbol should be the Code 39 start character');
        Assert.areEqual('*', result.symbols[result.symbols.size() - 1], 'The last symbol should be the Code 39 stop character');
        Assert.areEqual((result.symbols.size() * 15) + (result.symbols.size() - 1), result.modules.length(), 'Module length should include symbol patterns and inter-character gaps');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify successful Code 39 encoding with a
*              Modulo-43 checksum character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testEncodeWithChecksum() {
        String value = 'PHOCS-ABC123-000456';
        
        Test.startTest();
        Code39Encoder.EncodingResult result = Code39Encoder.encode(value, true);
        Test.stopTest();
        
        Assert.areEqual(value, result.value, 'The encoded value should match the input value');
        Assert.areEqual(true, result.checksumIncluded, 'Checksum should be included when requested');
        Assert.areEqual(17, result.checksum, 'The Modulo-43 checksum should match the expected value');
        Assert.areEqual('H', result.checksumCharacter, 'The checksum character should match the expected Code 39 character');
        Assert.areEqual(value.length() + 3, result.symbols.size(), 'Symbol count should include start, checksum and stop characters');
        Assert.areEqual(value.length() + 3, result.patterns.size(), 'Pattern count should match the symbol count');
        Assert.areEqual('*', result.symbols[0], 'The first symbol should be the Code 39 start character');
        Assert.areEqual('H', result.symbols[result.symbols.size() - 2], 'The checksum character should appear before the stop character');
        Assert.areEqual('*', result.symbols[result.symbols.size() - 1], 'The last symbol should be the Code 39 stop character');
        Assert.areEqual((result.symbols.size() * 15) + (result.symbols.size() - 1), result.modules.length(), 'Module length should include symbol patterns and inter-character gaps');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify Modulo-43 checksum calculation for a
*              known Code 39 barcode value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testCalculateChecksum() {
        String value = 'ABC123';
        Integer expectedChecksum = Math.mod(10 + 11 + 12 + 1 + 2 + 3, 43);
        
        Test.startTest();
        Integer actualChecksum = Code39Encoder.calculateChecksum(value);
        Test.stopTest();
        
        Assert.areEqual(expectedChecksum, actualChecksum, 'The calculated checksum should match the expected Modulo-43 value');
        Assert.areEqual(39, actualChecksum, 'The checksum should match the expected Code 39 checksum value');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify Modulo-43 checksum calculation when the
*              result resolves to the first checksum character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testChecksumModulo43Boundary() {
        String value = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%';
        
        Test.startTest();
        Integer checksum = Code39Encoder.calculateChecksum(value);
        Test.stopTest();
        
        Assert.areEqual(0, checksum, 'The checksum should resolve to zero when the total is divisible by 43');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify successful encoding of all standard
*              supported Code 39 data characters.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testAllSupportedCharacters() {
        String value = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%';
        
        Test.startTest();
        Code39Encoder.EncodingResult result = Code39Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(value, result.value, 'The encoded value should match all supported input characters');
        Assert.areEqual(value.length() + 2, result.symbols.size(), 'Symbol count should include start and stop characters');
        Assert.areEqual(value.length() + 2, result.patterns.size(), 'Pattern count should match the symbol count');
        Assert.areEqual('*', result.symbols[0], 'The first symbol should be the Code 39 start character');
        Assert.areEqual('*', result.symbols[result.symbols.size() - 1], 'The last symbol should be the Code 39 stop character');
        
        for (Integer i = 0; i < value.length(); i++) {
            Assert.areEqual(value.substring(i, i + 1), result.symbols[i + 1], 'The encoded symbol should match the input character at position ' + i);
            Assert.areEqual(15, result.patterns[i + 1].length(), 'Each Code 39 symbol pattern should contain 15 modules');
        }
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that the Code 39 start and stop pattern
*              is returned correctly.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testStartStopPattern() {
        Test.startTest();
        String pattern = Code39Encoder.getPattern('*');
        Test.stopTest();
        
        Assert.areEqual('100010111011101', pattern, 'The Code 39 start and stop pattern should match the expected pattern');
        Assert.areEqual(15, pattern.length(), 'The Code 39 start and stop pattern should contain 15 modules');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a known numeric Code 39 symbol
*              returns the expected barcode pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNumericPattern() {
        Test.startTest();
        String pattern = Code39Encoder.getPattern('0');
        Test.stopTest();
        
        Assert.areEqual('101000111011101', pattern, 'The Code 39 pattern for zero should match the expected pattern');
        Assert.areEqual(15, pattern.length(), 'The Code 39 numeric pattern should contain 15 modules');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a known alphabetic Code 39 symbol
*              returns the expected barcode pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testAlphabeticPattern() {
        Test.startTest();
        String pattern = Code39Encoder.getPattern('A');
        Test.stopTest();
        
        Assert.areEqual('111010100010111', pattern, 'The Code 39 pattern for A should match the expected pattern');
        Assert.areEqual(15, pattern.length(), 'The Code 39 alphabetic pattern should contain 15 modules');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that every supported Code 39 symbol
*              returns a valid 15-module barcode pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testAllCode39Patterns() {
        String supportedCharacters = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%*';
        
        for (Integer i = 0; i < supportedCharacters.length(); i++) {
            String symbol = supportedCharacters.substring(i, i + 1);
            String pattern = Code39Encoder.getPattern(symbol);
            
            Assert.areNotEqual(null, pattern, 'A pattern should exist for Code 39 symbol ' + symbol);
            Assert.areEqual(15, pattern.length(), 'The pattern should contain 15 modules for Code 39 symbol ' + symbol);
            Assert.isTrue(pattern.contains('1'), 'The pattern should contain bar modules for Code 39 symbol ' + symbol);
            Assert.isTrue(pattern.contains('0'), 'The pattern should contain space modules for Code 39 symbol ' + symbol);
        }
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that Code 39 encoding correctly inserts
*              an inter-character gap between each barcode symbol pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testInterCharacterGaps() {
        String value = 'AB';
        
        Test.startTest();
        Code39Encoder.EncodingResult result = Code39Encoder.encode(value);
        Test.stopTest();
        
        Assert.areEqual(4, result.symbols.size(), 'The symbol list should include start, data characters and stop');
        Integer expectedModuleLength = (result.patterns.size() * 15) + (result.patterns.size() - 1);
        Assert.areEqual(expectedModuleLength, result.modules.length(), 'The module string should contain all Code 39 patterns and inter-character gaps');
        Assert.areEqual((4 * 15) + 3, result.modules.length(), 'The module string should include three inter-character gaps');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that the expected barcode module sequence
*              begins with the Code 39 start character pattern.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testModuleStartsWithStartPattern() {
        Test.startTest();
        Code39Encoder.EncodingResult result = Code39Encoder.encode('A');
        Test.stopTest();
        
        Assert.isTrue(result.modules.startsWith('100010111011101'), 'The module string should begin with the Code 39 start pattern');
        Assert.isTrue(result.modules.endsWith('100010111011101'), 'The module string should end with the Code 39 stop pattern');
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that an invalid Code 39 symbol produces
*              the expected IllegalArgumentException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testInvalidSymbol() {
        Test.startTest();
        
        try {
            Code39Encoder.getPattern('@');
            Assert.fail('An IllegalArgumentException should be thrown for an invalid Code 39 symbol');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.isTrue(exceptionObject.getMessage().contains('Invalid Code 39 symbol'), 'The exception message should identify the invalid Code 39 symbol');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a null Code 39 symbol produces the
*              expected IllegalArgumentException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNullSymbol() {
        Test.startTest();
        
        try {
            Code39Encoder.getPattern(null);
            Assert.fail('An IllegalArgumentException should be thrown for a null Code 39 symbol');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.isTrue(exceptionObject.getMessage().contains('Invalid Code 39 symbol'), 'The exception message should identify the invalid Code 39 symbol');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a blank barcode value produces the
*              expected IllegalArgumentException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testBlankValue() {
        Test.startTest();
        
        try {
            Code39Encoder.encode('');
            Assert.fail('An IllegalArgumentException should be thrown for a blank barcode value');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.areEqual('Barcode value is required.', exceptionObject.getMessage(), 'The exception message should identify that a barcode value is required');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a null barcode value produces the
*              expected IllegalArgumentException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testNullValue() {
        Test.startTest();
        
        try {
            Code39Encoder.encode(null);
            Assert.fail('An IllegalArgumentException should be thrown for a null barcode value');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.areEqual('Barcode value is required.', exceptionObject.getMessage(), 'The exception message should identify that a barcode value is required');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a lowercase character, which is not
*              supported by standard Code 39, produces the expected IllegalArgumentException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testLowerCaseCharacter() {
        Test.startTest();
        
        try {
            Code39Encoder.encode('ABCabc123');
            Assert.fail('An IllegalArgumentException should be thrown for a lowercase Code 39 character');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.isTrue(exceptionObject.getMessage().contains('Code 39 supports only'), 'The exception message should identify the supported Code 39 characters');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that an unsupported special character
*              produces the expected IllegalArgumentException.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testUnsupportedCharacter() {
        Test.startTest();
        
        try {
            Code39Encoder.encode('ABC@123');
            Assert.fail('An IllegalArgumentException should be thrown for an unsupported Code 39 character');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.isTrue(exceptionObject.getMessage().contains('Code 39 supports only'), 'The exception message should identify the supported Code 39 characters');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that the reserved Code 39 start and stop
*              character cannot be used as part of the barcode data value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testReservedStartStopCharacter() {
        Test.startTest();
        
        try {
            Code39Encoder.encode('ABC*123');
            Assert.fail('An IllegalArgumentException should be thrown when the reserved start and stop character is used');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.isTrue(exceptionObject.getMessage().contains('reserved for Code 39 start/stop'), 'The exception message should identify the reserved start and stop character');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that calculateChecksum also validates
*              unsupported Code 39 input values.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testChecksumUnsupportedCharacter() {
        Test.startTest();
        
        try {
            Code39Encoder.calculateChecksum('ABC@123');
            Assert.fail('An IllegalArgumentException should be thrown for an unsupported checksum character');
        } catch (IllegalArgumentException exceptionObject) {
            Assert.isTrue(exceptionObject.getMessage().contains('Code 39 supports only'), 'The exception message should identify the supported Code 39 characters');
        }
        
        Test.stopTest();
    }
    
    /**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to verify that a checksum character is correctly
*              inserted between the barcode data and Code 39 stop character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @IsTest
    static void testChecksumCharacterPlacement() {
        String value = 'A';
        
        Test.startTest();
        Code39Encoder.EncodingResult result = Code39Encoder.encode(value, true);
        Test.stopTest();
        
        Assert.areEqual(4, result.symbols.size(), 'The symbol list should include start, data, checksum and stop characters');
        Assert.areEqual(10, result.checksum, 'The checksum value for A should match the expected Modulo-43 value');
        Assert.areEqual('A', result.checksumCharacter, 'The checksum character for A should match the expected Code 39 character');
        Assert.areEqual('*', result.symbols[0], 'The first symbol should be the Code 39 start character');
        Assert.areEqual('A', result.symbols[1], 'The second symbol should be the barcode data character');
        Assert.areEqual('A', result.symbols[2], 'The checksum character should be added before the stop character');
        Assert.areEqual('*', result.symbols[3], 'The final symbol should be the Code 39 stop character');
    }
}