/**********************************************************************************************
* @Author:      Accenture 
* @Date:        28 Aug 2026
* @Description: The purpose of this class is to encode a value using Code 128 Code Set B and
*               return the corresponding barcode symbol values, checksum, patterns and modules.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
*               01 Sep 2026 - Barcode Scan Fix - Deepak - Removed duplicated entry in
*               CODE128_PATTERNS (previously duplicated at index 70/71) that shifted every
*               pattern from index 71-106 out of alignment, corrupting Start Code B, the
*               checksum symbol, and the Stop Code so generated barcodes could not be scanned.
***********************************************************************************************/
public with sharing class Code128Encoder {
    private static final Integer START_CODE_B = 104;
    private static final Integer STOP_CODE = 106;
    private static final Integer MODULO = 103;
    private static final Integer ASCII_OFFSET = 32;
    
    private static final List<String> CODE128_PATTERNS = new List<String>{
        '11011001100','11001101100','11001100110','10010011000','10010001100','10001001100','10011001000','10011000100','10001100100','11001001000',
        '11001000100','11000100100','10110011100','10011011100','10011001110','10111001100','10011101100','10011100110','11001110010','11001011100',
        '11001001110','11011100100','11001110100','11101101110','11101001100','11100101100','11100100110','11101100100','11100110100','11100110010',
        '11011011000','11011000110','11000110110','10100011000','10001011000','10001000110','10110001000','10001101000','10001100010','11010001000',
        '11000101000','11000100010','10110111000','10110001110','10001101110','10111011000','10111000110','10001110110','11101110110','11010001110',
        '11000101110','11011101000','11011100010','11011101110','11101011000','11101000110','11100010110','11101101000','11101100010','11100011010',
        '11101111010','11001000010','11110001010','10100110000','10100001100','10010110000','10010000110','10000101100','10000100110','10110010000',
        '10110000100','10011010000','10011000010','10000110100','10000110010','11000010010','11001010000','11110111010','11000010100','10001111010',
        '10100111100','10010111100','10010011110','10111100100','10011110100','10011110010','11110100100','11110010100','11110010010','11011011110',
        '11011110110','11110110110','10101111000','10100011110','10001011110','10111101000','10111100010','11110101000','11110100010','10111011110',
        '10111101110','11101011110','11110101110','11010000100','11010010000','11010011100','11000111010'
    };
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this inner class is to store the Code 128 encoding result including
*              the barcode value, symbol values, checksum, patterns and combined module string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public class EncodingResult {
        public String value;
        public List<Integer> symbolValues;
        public Integer checksum;
        public List<String> patterns;
        public String modules;
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to encode the provided barcode value using Code 128
*              Code Set B and return the generated symbol values, checksum, patterns and modules.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static EncodingResult encode(String value) {
        validate(value);
        
        EncodingResult result = new EncodingResult();
        result.value = value;
        result.symbolValues = new List<Integer>();
        result.symbolValues.add(START_CODE_B);
        
        Integer checksum = START_CODE_B;
        Integer position = 1;
        
        for (Integer i = 0; i < value.length(); i++) {
            Integer symbolValue = value.charAt(i) - ASCII_OFFSET;
            result.symbolValues.add(symbolValue);
            checksum += symbolValue * position;
            position++;
        }
        
        result.checksum = Math.mod(checksum, MODULO);
        result.symbolValues.add(result.checksum);
        result.symbolValues.add(STOP_CODE);
        result.patterns = new List<String>();
        
        for (Integer symbolValue : result.symbolValues) {
            result.patterns.add(getPattern(symbolValue));
        }
        
        result.modules = String.join(result.patterns, '') + '11';
        
        return result;
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to calculate and return the Code 128 Code Set B
*              checksum value for the provided barcode value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Integer calculateChecksum(String value) {
        validate(value);
        
        Integer checksum = START_CODE_B;
        Integer position = 1;
        
        for (Integer i = 0; i < value.length(); i++) {
            checksum += (value.charAt(i) - ASCII_OFFSET) * position;
            position++;
        }
        
        return Math.mod(checksum, MODULO);
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to return the Code 128 barcode pattern corresponding
*              to the provided symbol value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String getPattern(Integer symbolValue) {
        if (symbolValue == null || symbolValue < 0 || symbolValue >= CODE128_PATTERNS.size()) {
            throw new IllegalArgumentException('Invalid Code 128 symbol value: ' + symbolValue);
        }
        
        return CODE128_PATTERNS[symbolValue];
    }
    
/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to validate that the provided barcode value is not blank
*              and contains only characters supported by Code 128 Code Set B.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void validate(String value) {
        if (String.isBlank(value)) {
            throw new IllegalArgumentException('Barcode value is required.');
        }
        
        for (Integer i = 0; i < value.length(); i++) {
            Integer asciiValue = value.charAt(i);
            
            if (asciiValue < 32 || asciiValue > 127) {
                throw new IllegalArgumentException('Code 128 Set B supports ASCII characters 32 through 127. Invalid character at position ' + i + '.');
            }
        }
    }
}