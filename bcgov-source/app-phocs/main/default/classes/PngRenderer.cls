/**********************************************************************************************
* @Author:      Accenture
* @Date:        28 Aug 2026
* @Description: The purpose of this class is to render Code 39 (or any Code128Encoder/
*               Code39Encoder-compatible) barcode data as a PNG image.
* @Revision(s): [Date] - [Change Reference] - [Changed By] - [Description]
                28 Aug - Barcode Generation - Accenture - Generate barcode PNG entirely in Apex.
                02 Sep - Code 39 Migration - Deepak - render(String) now encodes via
                Code39Encoder instead of Code128Encoder. Replaced the
                render(Code128Encoder.EncodingResult) overload with a symbology-agnostic
                render(String value, String modules) so PngRenderer no longer depends on a
                specific encoder's type -- any encoder producing a value/modules pair (Code128Encoder,
                Code39Encoder, or future symbologies) can feed it directly.
***********************************************************************************************/
public with sharing class PngRenderer {
    private static final String CLASS_NAME = 'PngRenderer';
    private static final String PNG_SIGNATURE = '89504E470D0A1A0A';
    private static final String HEX_DIGITS = '0123456789ABCDEF';
    private static final Integer MODULE_WIDTH = 2;
    private static final Integer BAR_HEIGHT = 80;
    private static final Integer QUIET_ZONE_MODULES = 10;
    private static final Integer TEXT_SCALE = 2;
    private static final Integer TEXT_GAP = 6;
    private static final Integer TOP_MARGIN = 8;
    private static final Integer BOTTOM_MARGIN = 8;
    private static final Integer FONT_SPACING = 1;
    private static final Integer ZLIB_MODULO = 65521;
    private static final Integer MAX_DEFLATE_BLOCK_SIZE = 65535;
    private static final List<Integer> CRC32_TABLE = buildCrc32Table();

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to encode the barcode value using Code39Encoder and
*              render it as a PNG image.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep 2026 - Code 39 Migration - Deepak - Encodes via Code39Encoder instead
*                     of Code128Encoder.
*/
    public static Blob render(String value) {
        try {
            if (String.isBlank(value)) {
                throw new IllegalArgumentException('Barcode value is required.');
            }

            Code39Encoder.EncodingResult encodingResult = Code39Encoder.encode(value);

            return render(encodingResult.value, encodingResult.modules);
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'render', null, ex);
            throw ex;
        }
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to render a barcode value and its module bit string
*              as a PNG image. This overload is symbology-agnostic: it accepts the value/modules
*              pair produced by Code128Encoder.EncodingResult, Code39Encoder.EncodingResult, or any
*              other encoder that produces a literal bar(1)/space(0) module bit string.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*                     02 Sep 2026 - Code 39 Migration - Deepak - Replaced the
*                     render(Code128Encoder.EncodingResult) overload with this
*                     render(String value, String modules) overload so PngRenderer no longer
*                     depends on a specific encoder's result type.
*/
    public static Blob render(String value, String modules) {
        try {
            if (String.isBlank(value)) {
                throw new IllegalArgumentException('Barcode value is required.');
            }

            if (String.isBlank(modules)) {
                throw new IllegalArgumentException('Barcode modules are required.');
            }

            validateFontCharacters(value);

            Integer width = calculateWidth(modules.length(), value.length());
            Integer height = calculateHeight();
            String rawImageHex = buildRawImageHex(modules, value, width, height);
            String pngHex = PNG_SIGNATURE + buildChunk('IHDR', buildIhdrDataHex(width, height)) + buildChunk('IDAT', buildZlibHex(rawImageHex)) + buildChunk('IEND', '');

            return EncodingUtil.convertFromHex(pngHex);
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'render', null, ex);
            throw ex;
        }
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to calculate the required barcode image width.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Integer calculateWidth(Integer moduleCount, Integer valueLength) {
        try {
            if (moduleCount == null || moduleCount <= 0) {
                throw new IllegalArgumentException('Module count must be greater than zero.');
            }

            if (valueLength == null || valueLength <= 0) {
                throw new IllegalArgumentException('Barcode value length must be greater than zero.');
            }

            Integer barcodeWidth = moduleCount * MODULE_WIDTH;
            Integer quietZoneWidth = QUIET_ZONE_MODULES * MODULE_WIDTH * 2;
            Integer textWidth = calculateTextWidth(valueLength);

            return Math.max(barcodeWidth + quietZoneWidth, textWidth + (TOP_MARGIN * 2));
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'calculateWidth', null, ex);
            throw ex;
        }
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to calculate the required barcode image height.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    public static Integer calculateHeight() {
        try {
            return TOP_MARGIN + BAR_HEIGHT + TEXT_GAP + (BarcodeBitmapFont.getHeight() * TEXT_SCALE) + BOTTOM_MARGIN;
        } catch (Exception ex) {
            LogService.logAndPublish(CLASS_NAME, 'calculateHeight', null, ex);
            throw ex;
        }
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to calculate the width required for human-readable barcode text.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Integer calculateTextWidth(Integer valueLength) {
        Integer glyphWidth = BarcodeBitmapFont.getWidth() * TEXT_SCALE;
        Integer glyphSpacing = FONT_SPACING * TEXT_SCALE;

        return (valueLength * (glyphWidth + glyphSpacing)) - glyphSpacing;
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to construct the raw grayscale PNG image data.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String buildRawImageHex(String modules, String value, Integer width, Integer height) {
        Integer quietZonePixels = QUIET_ZONE_MODULES * MODULE_WIDTH;
        Integer barcodeStartY = TOP_MARGIN;
        Integer barcodeEndY = barcodeStartY + BAR_HEIGHT;
        Integer textStartY = barcodeEndY + TEXT_GAP;
        Integer textHeight = BarcodeBitmapFont.getHeight() * TEXT_SCALE;
        Integer textWidth = calculateTextWidth(value.length());
        Integer textStartX = (width - textWidth) / 2;
        List<String> rowHexParts = new List<String>();

        for (Integer y = 0; y < height; y++) {
            rowHexParts.add(buildPackedRowHex(modules, value, width, y, quietZonePixels, barcodeStartY, barcodeEndY, textStartX, textStartY, textHeight));
        }

        return String.join(rowHexParts, '');
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to construct one packed PNG image row.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String buildPackedRowHex(String modules, String value, Integer width, Integer y, Integer quietZonePixels, Integer barcodeStartY, Integer barcodeEndY, Integer textStartX, Integer textStartY, Integer textHeight) {
        List<String> rowParts = new List<String>();
        String rowHex = '00';
        Integer currentByte = 255;
        Integer bitPosition = 7;
        Integer barcodeModuleCount = modules.length();
        Integer glyphWidth = BarcodeBitmapFont.getWidth();
        Integer glyphHeight = BarcodeBitmapFont.getHeight();
        Integer glyphAdvance = (glyphWidth + FONT_SPACING) * TEXT_SCALE;

        for (Integer x = 0; x < width; x++) {
            Boolean blackPixel = false;

            if (y >= barcodeStartY && y < barcodeEndY) {
                Integer barcodeX = x - quietZonePixels;

                if (barcodeX >= 0 && barcodeX < barcodeModuleCount * MODULE_WIDTH) {
                    Integer moduleIndex = barcodeX / MODULE_WIDTH;

                    if (modules.substring(moduleIndex, moduleIndex + 1) == '1') {
                        blackPixel = true;
                    }
                }
            } else if (y >= textStartY && y < textStartY + textHeight) {
                Integer relativeX = x - textStartX;
                Integer relativeY = y - textStartY;

                if (relativeX >= 0 && relativeX < calculateTextWidth(value.length())) {
                    Integer characterIndex = relativeX / glyphAdvance;
                    Integer characterOffset = Math.mod(relativeX, glyphAdvance);
                    Integer glyphColumn = characterOffset / TEXT_SCALE;
                    Integer glyphRow = relativeY / TEXT_SCALE;

                    if (characterIndex >= 0 && characterIndex < value.length() && glyphColumn < glyphWidth && glyphRow < glyphHeight) {
                        String character = value.substring(characterIndex, characterIndex + 1);
                        List<String> glyph = BarcodeBitmapFont.getGlyph(character);

                        if (glyph[glyphRow].substring(glyphColumn, glyphColumn + 1) == '1') {
                            blackPixel = true;
                        }
                    }
                }
            }

            if (blackPixel) {
                currentByte -= (1 << bitPosition);
            }

            if (bitPosition == 0) {
                rowHex += hexByte(currentByte);

                if (rowHex.length() >= 258) {
                    rowParts.add(rowHex);
                    rowHex = '';
                }

                currentByte = 255;
                bitPosition = 7;
            } else {
                bitPosition--;
            }
        }

        if (bitPosition != 7) {
            rowHex += hexByte(currentByte);
        }

        if (rowHex != '') {
            rowParts.add(rowHex);
        }

        return String.join(rowParts, '');
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to validate that all barcode characters are supported by the bitmap font.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static void validateFontCharacters(String value) {
        for (Integer i = 0; i < value.length(); i++) {
            String character = value.substring(i, i + 1);

            if (!BarcodeBitmapFont.supports(character)) {
                throw new IllegalArgumentException('Unsupported human-readable barcode character: ' + character);
            }
        }
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to construct the PNG IHDR chunk data.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String buildIhdrDataHex(Integer width, Integer height) {
        return uint32Hex(width) + uint32Hex(height) + '0100000000';
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to construct a PNG chunk including length and CRC.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String buildChunk(String type, String dataHex) {
        String typeHex = EncodingUtil.convertToHex(Blob.valueOf(type));
        String lengthHex = uint32Hex(dataHex.length() / 2);
        String crcHex = crc32Hex(typeHex + dataHex);

        return lengthHex + typeHex + dataHex + crcHex;
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to construct a zlib stream using stored DEFLATE blocks.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String buildZlibHex(String rawHex) {
        StringBuilderData data = new StringBuilderData();
        data.append('7801');

        Integer totalBytes = rawHex.length() / 2;
        Integer offset = 0;

        while (offset < totalBytes) {
            Integer blockLength = Math.min(MAX_DEFLATE_BLOCK_SIZE, totalBytes - offset);
            Boolean finalBlock = offset + blockLength == totalBytes;

            data.append(finalBlock ? '01' : '00');
            data.append(uint16LittleHex(blockLength));
            data.append(uint16LittleHex(65535 - blockLength));
            data.append(rawHex.substring(offset * 2, (offset + blockLength) * 2));

            offset += blockLength;
        }

        data.append(uint32Hex(adler32(rawHex)));

        return data.toStringValue();
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to calculate the Adler-32 checksum for the PNG image data.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @TestVisible
    private static Long adler32(String hexData) {
        Integer a = 1;
        Integer b = 0;

        for (Integer i = 0; i < hexData.length(); i += 2) {
            Integer byteValue = hexByteToInteger(hexData.substring(i, i + 2));
            a = Math.mod(a + byteValue, ZLIB_MODULO);
            b = Math.mod(b + a, ZLIB_MODULO);
        }

        return ((Long)b * 65536L) + (Long)a;
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to calculate the CRC-32 checksum for a PNG chunk.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    @TestVisible
    private static String crc32Hex(String hexData) {
        Integer crc = -1;

        for (Integer i = 0; i < hexData.length(); i += 2) {
            Integer byteValue = hexByteToInteger(hexData.substring(i, i + 2));
            Integer tableIndex = (crc ^ byteValue) & 255;
            crc = (crc >>> 8) ^ CRC32_TABLE[tableIndex];
        }

        crc = crc ^ -1;

        Long unsignedValue = crc;

        if (unsignedValue < 0) {
            unsignedValue += 4294967296L;
        }

        return uint32Hex(unsignedValue);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to construct the CRC-32 lookup table.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static List<Integer> buildCrc32Table() {
        List<Integer> table = new List<Integer>();
        Integer polynomial = -306674912;

        for (Integer i = 0; i < 256; i++) {
            Integer crc = i;

            for (Integer bit = 0; bit < 8; bit++) {
                if ((crc & 1) != 0) {
                    crc = (crc >>> 1) ^ polynomial;
                } else {
                    crc = crc >>> 1;
                }
            }

            table.add(crc);
        }

        return table;
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert a hexadecimal byte into an Integer.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Integer hexByteToInteger(String hexValue) {
        if (String.isBlank(hexValue) || hexValue.length() != 2) {
            throw new IllegalArgumentException('Invalid hexadecimal byte: ' + hexValue);
        }

        Integer high = hexDigitToInteger(hexValue.substring(0, 1));
        Integer low = hexDigitToInteger(hexValue.substring(1, 2));

        return (high * 16) + low;
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert a hexadecimal digit into an Integer.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static Integer hexDigitToInteger(String digit) {
        if (String.isBlank(digit) || digit.length() != 1) {
            throw new IllegalArgumentException('Invalid hexadecimal digit: ' + digit);
        }

        Integer value = digit.charAt(0);

        if (value >= 48 && value <= 57) {
            return value - 48;
        }

        if (value >= 65 && value <= 70) {
            return value - 55;
        }

        if (value >= 97 && value <= 102) {
            return value - 87;
        }

        throw new IllegalArgumentException('Invalid hexadecimal digit: ' + digit);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert an Integer to a 16-bit little-endian hexadecimal value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String uint16LittleHex(Integer value) {
        return hexByte(value & 255) + hexByte((value >>> 8) & 255);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert an Integer to a 32-bit big-endian hexadecimal value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String uint32Hex(Integer value) {
        Long longValue = value;

        return uint32Hex(longValue);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert a Long to a 32-bit big-endian hexadecimal value.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String uint32Hex(Long value) {
        Long unsignedValue = value;

        if (unsignedValue < 0) {
            unsignedValue += 4294967296L;
        }

        Integer b1 = (Integer)(unsignedValue / 16777216L);
        unsignedValue -= b1 * 16777216L;

        Integer b2 = (Integer)(unsignedValue / 65536L);
        unsignedValue -= b2 * 65536L;

        Integer b3 = (Integer)(unsignedValue / 256L);
        unsignedValue -= b3 * 256L;

        Integer b4 = (Integer)unsignedValue;

        return hexByte(b1) + hexByte(b2) + hexByte(b3) + hexByte(b4);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert an Integer into a two-character hexadecimal byte.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String hexByte(Integer value) {
        Integer high = (value >>> 4) & 15;
        Integer low = value & 15;

        return hexDigit(high) + hexDigit(low);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this method is to convert an Integer hexadecimal value into its digit representation.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private static String hexDigit(Integer value) {
        if (value < 0 || value > 15) {
            throw new IllegalArgumentException('Invalid hexadecimal digit value: ' + value);
        }

        return HEX_DIGITS.substring(value, value + 1);
    }

/**
* @author: Deepak
* @date: 28 Aug 2026
* @description: The purpose of this inner class is to efficiently construct large String values.
* @Modification Log: [Date] - [Change Reference] - [Changed By] - [Description]
*/
    private class StringBuilderData {
        private List<String> parts = new List<String>();

        private void append(String value) {
            parts.add(value);
        }

        private String toStringValue() {
            return String.join(parts, '');
        }
    }
}