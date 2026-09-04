/**********************************************************************************************
* @Author:      Accenture 
* @Date:        02 Sep 2026
* @Description: The purpose of this class is to encode a value using Code 39 and return the
*               corresponding barcode symbol patterns, optional Modulo-43 checksum, and
*               combined module string.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
***********************************************************************************************/
public with sharing class Code39Encoder {
    private static final String START_STOP_CHARACTER = '*';
    private static final String INTER_CHARACTER_GAP = '0';
    private static final Integer MODULO = 43;
    
    private static final String CHECKSUM_CHARACTERS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%';
    
    private static final Map<String, String> CODE39_PATTERNS = new Map<String, String>{
        '0' => '101000111011101', '1' => '111010001010111', '2' => '101110001010111', '3' => '111011100010101',
        '4' => '101000111010111', '5' => '111010001110101', '6' => '101110001110101', '7' => '101000101110111',
        '8' => '111010001011101', '9' => '101110001011101', 'A' => '111010100010111', 'B' => '101110100010111',
        'C' => '111011101000101', 'D' => '101011100010111', 'E' => '111010111000101', 'F' => '101110111000101',
        'G' => '101010001110111', 'H' => '111010100011101', 'I' => '101110100011101', 'J' => '101011100011101',
        'K' => '111010101000111', 'L' => '101110101000111', 'M' => '111011101010001', 'N' => '101011101000111',
        'O' => '111010111010001', 'P' => '101110111010001', 'Q' => '101010111000111', 'R' => '111010101110001',
        'S' => '101110101110001', 'T' => '101011101110001', 'U' => '111000101010111', 'V' => '100011101010111',
        'W' => '111000111010101', 'X' => '100010111010111', 'Y' => '111000101110101', 'Z' => '100011101110101',
        '-' => '100010101110111', '.' => '111000101011101', ' ' => '100011101011101', '$' => '100010001000101',
        '/' => '100010001010001', '+' => '100010100010001', '%' => '101000100010001', '*' => '100010111011101'
    };
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this inner class is to store the Code 39 encoding result including
*              the barcode value, symbol patterns, optional checksum, and combined module string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public class EncodingResult {
        public String value;
        public Boolean checksumIncluded;
        public Integer checksum;
        public String checksumCharacter;
        public List<String> symbols;
        public List<String> patterns;
        public String modules;
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to encode the provided barcode value using Code 39
*              without a Modulo-43 checksum character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static EncodingResult encode(String value) {
        return encode(value, false);
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to encode the provided barcode value using Code 39
*              and return the generated symbols, optional checksum, patterns and modules.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static EncodingResult encode(String value, Boolean includeChecksum) {
        validate(value);
        
        EncodingResult result = new EncodingResult();
        result.value = value;
        result.checksumIncluded = includeChecksum;
        result.symbols = new List<String>();
        result.symbols.add(START_STOP_CHARACTER);
        
        for (Integer i = 0; i < value.length(); i++) {
            result.symbols.add(value.substring(i, i + 1));
        }
        
        if (includeChecksum) {
            result.checksum = calculateChecksum(value);
            result.checksumCharacter = CHECKSUM_CHARACTERS.substring(result.checksum, result.checksum + 1);
            result.symbols.add(result.checksumCharacter);
        }
        
        result.symbols.add(START_STOP_CHARACTER);
        result.patterns = new List<String>();
        
        for (String symbol : result.symbols) {
            result.patterns.add(getPattern(symbol));
        }
        
        result.modules = String.join(result.patterns, INTER_CHARACTER_GAP);
        
        return result;
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to calculate and return the Code 39 Modulo-43
*              checksum value for the provided barcode value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Integer calculateChecksum(String value) {
        validate(value);
        
        Integer total = 0;
        
        for (Integer i = 0; i < value.length(); i++) {
            String character = value.substring(i, i + 1);
            total += CHECKSUM_CHARACTERS.indexOf(character);
        }
        
        return Math.mod(total, MODULO);
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to return the Code 39 barcode pattern corresponding
*              to the provided symbol character.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static String getPattern(String symbol) {
        if (symbol == null || symbol.length() != 1 || !CODE39_PATTERNS.containsKey(symbol)) {
            throw new IllegalArgumentException('Invalid Code 39 symbol: ' + symbol);
        }
        
        return CODE39_PATTERNS.get(symbol);
    }
    
/**
* @author: Deepak
* @date: 02 Sep 2026
* @description: The purpose of this method is to validate that the provided barcode value is not
*              blank and contains only characters supported by the standard Code 39 character set.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void validate(String value) {
        if (String.isBlank(value)) {
            throw new IllegalArgumentException('Barcode value is required.');
        }
        
        for (Integer i = 0; i < value.length(); i++) {
            String character = value.substring(i, i + 1);
            
            if (character == START_STOP_CHARACTER) {
                throw new IllegalArgumentException('Character \'*\' is reserved for Code 39 start/stop and is not permitted at position ' + i + '.');
            }
            
            if (!CODE39_PATTERNS.containsKey(character)) {
                throw new IllegalArgumentException('Code 39 supports only 0-9, A-Z, and - . space $ / + %. Invalid character at position ' + i + '.');
            }
        }
    }
}