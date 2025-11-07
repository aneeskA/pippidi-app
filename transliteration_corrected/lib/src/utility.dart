import 'languages.dart';

/// Utility class used for internal use...
class Utility {
  /// Base URL
  static final String transliterationBaseURL =
      'https://www.google.com/transliterate/all';

  /// Converts Enums to Google Language Codes
  static String getLanguageCode(Languages languageCode) {
    switch (languageCode) {
      case Languages.AMHARIC:
        return 'am';
      case Languages.ARABIC:
        return 'ar';
      case Languages.BENGALI:
        return 'bn';
      case Languages.CHINESE:
        return 'zh';
      case Languages.GREEK:
        return 'el';
      case Languages.GUJARATI:
        return 'gu';
      case Languages.HINDI:
        return 'hi';
      case Languages.KANNADA:
        return 'kn';
      case Languages.MALAYALAM:
        return 'ml';
      case Languages.MARATHI:
        return 'mr';
      case Languages.NEPALI:
        return 'ne';
      case Languages.ORIYA:
        return 'or';
      case Languages.PERSIAN:
        return 'fa';
      case Languages.PUNJABI:
        return 'pa';
      case Languages.RUSSIAN:
        return 'ru';
      case Languages.SANSKRIT:
        return 'sa';
      case Languages.SINHALESE:
        return 'si';
      case Languages.SERBIAN:
        return 'sr';
      case Languages.TAMIL:
        return 'ta';
      case Languages.TELUGU:
        return 'te';
      case Languages.TIGRINYA:
        return 'ti';
      case Languages.URDU:
        return 'ur';
      default:
        return 'en';
    }
  }
}
