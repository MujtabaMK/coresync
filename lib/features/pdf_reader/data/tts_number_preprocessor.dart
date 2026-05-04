/// Preprocesses text for TTS so that plain numbers are read digit-by-digit
/// while currency amounts (preceded by ₹, $, etc.) are read naturally.
///
/// Example:
///   "Page 921 costs ₹9,200" →
///   TTS speaks: "Page 9 2 1 costs ₹9,200"
///   (so TTS reads "nine two one" for 921 and "nine thousand two hundred" for ₹9,200)
///
/// Returns a [TtsPreprocessed] containing the processed text and an offset
/// mapping so TTS progress callbacks can be translated back to the original
/// text positions for word highlighting.
class TtsPreprocessed {
  const TtsPreprocessed({
    required this.text,
    required this.offsetMapping,
  });

  /// The text to send to TTS engine.
  final String text;

  /// Maps each character index in [text] back to the corresponding index in
  /// the original text. Used to convert TTS progress offsets to original
  /// offsets for highlight positioning.
  final List<int> offsetMapping;

  /// Converts a character offset reported by the TTS engine (into [text])
  /// back to the corresponding offset in the original unprocessed text.
  int toOriginalOffset(int processedOffset) {
    if (offsetMapping.isEmpty) return processedOffset;
    if (processedOffset >= offsetMapping.length) return offsetMapping.last;
    return offsetMapping[processedOffset];
  }
}

/// Currency symbols that indicate a following number should be read as a
/// whole amount (e.g. "nine lakh two thousand") rather than digit-by-digit.
const _currencySymbols = {
  '\u20B9', // ₹ Indian Rupee
  '\$', // $ Dollar
  '\u20AC', // € Euro
  '\u00A3', // £ Pound
  '\u00A5', // ¥ Yen/Yuan
  '\u20A9', // ₩ Won
  '\u20BD', // ₽ Ruble
  '\u20AB', // ₫ Dong
  '\u20A6', // ₦ Naira
  '\u20B5', // ₵ Cedi
};

/// Preprocess [original] text for TTS digit-by-digit number reading.
///
/// Numbers NOT preceded by a currency symbol have spaces inserted between
/// digits so the TTS engine reads each digit individually.
/// Numbers preceded by a currency symbol are left intact for natural reading.
TtsPreprocessed preprocessTtsNumbers(String original) {
  if (original.isEmpty) {
    return const TtsPreprocessed(text: '', offsetMapping: []);
  }

  final buffer = StringBuffer();
  final mapping = <int>[];

  int i = 0;
  while (i < original.length) {
    if (_isDigit(original.codeUnitAt(i))) {
      // Found start of a number — determine its full extent.
      final numStart = i;
      int numEnd = i;
      while (numEnd < original.length && _isNumberChar(original, numEnd)) {
        numEnd++;
      }
      // Trim trailing separators (e.g. "100." at end of sentence).
      while (numEnd > numStart && !_isDigit(original.codeUnitAt(numEnd - 1))) {
        numEnd--;
      }

      // Look back past whitespace for a currency symbol.
      bool hasCurrency = false;
      int lookBack = numStart - 1;
      while (lookBack >= 0 && original[lookBack] == ' ') {
        lookBack--;
      }
      if (lookBack >= 0 && _currencySymbols.contains(original[lookBack])) {
        hasCurrency = true;
      }

      if (hasCurrency) {
        // Keep number intact — TTS reads it naturally as a currency amount.
        for (int j = numStart; j < numEnd; j++) {
          buffer.writeCharCode(original.codeUnitAt(j));
          mapping.add(j);
        }
      } else {
        // Space-separate digits for digit-by-digit reading.
        // Skip commas/dots/spaces within the number.
        bool firstDigit = true;
        for (int j = numStart; j < numEnd; j++) {
          if (_isDigit(original.codeUnitAt(j))) {
            if (!firstDigit) {
              buffer.write(' ');
              mapping.add(j);
            }
            buffer.writeCharCode(original.codeUnitAt(j));
            mapping.add(j);
            firstDigit = false;
          }
          // Non-digit separators (commas, dots) are skipped in output.
        }
      }
      i = numEnd;
    } else {
      buffer.writeCharCode(original.codeUnitAt(i));
      mapping.add(i);
      i++;
    }
  }

  return TtsPreprocessed(text: buffer.toString(), offsetMapping: mapping);
}

bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57; // '0'-'9'

/// Returns true if [index] in [text] is part of a number:
/// either a digit, or a separator (comma/dot) followed by a digit.
bool _isNumberChar(String text, int index) {
  final code = text.codeUnitAt(index);
  if (_isDigit(code)) return true;
  // Comma or dot acting as thousands/decimal separator (must be followed by digit).
  if ((code == 44 || code == 46) && // ',' or '.'
      index + 1 < text.length &&
      _isDigit(text.codeUnitAt(index + 1))) {
    return true;
  }
  return false;
}