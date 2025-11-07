import 'package:transliteration/response/transliteration_response.dart';
import 'package:transliteration/transliteration.dart';

Future<void> getTransliteration() async {
  TransliterationResponse? _response =
      await Transliteration.transliterate("Hello", Languages.HINDI);
  print(_response?.transliterationSuggestions);
}

void main() {
  getTransliteration();
}
