import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import 'package:transliteration/response/transliteration_response.dart';
import 'package:transliteration/src/utility.dart';
import 'package:transliteration/transliteration.dart';

/// The Fundamental class that provides static method to transliterate given string.
class Transliteration {
  /// This function transliterates english text to the given language code.
  /// Exception will be thrown if user is not connected to internet or server is not responding.
  /// Returns Input String and top 5 suggestions in a list for transliteration.
  static Future<TransliterationResponse?> transliterate(
    String inputString,
    Languages languageCode,
  ) async {
    TransliterationResponse _transliterationResponse =
        new TransliterationResponse();
    String srcLanCode = Utility.getLanguageCode(Languages.ENGLISH);
    String descLanCode = Utility.getLanguageCode(languageCode);
    String lowerCaseSrcString = inputString.toLowerCase();
    final transliterationURL =
        '${Utility.transliterationBaseURL}?langpair=$srcLanCode|$descLanCode&text=$lowerCaseSrcString';
    try {
      Response _response = await http.get(Uri.parse(transliterationURL));
      List<TransliterationResponse> _transliterationResponseList =
          transliterationResponseFromJson(_response.body.toString());
      _transliterationResponse.transliterationSuggestions =
          _transliterationResponseList.first.transliterationSuggestions;
      _transliterationResponse.sourceString =
          _transliterationResponseList.first.sourceString;
      return _transliterationResponse;
    } catch (e) {
      print('Exception : $e');
    }
    return null;
  }
}
