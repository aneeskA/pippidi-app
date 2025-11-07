import 'dart:convert';

/// converts json to PODO class
List<TransliterationResponse> transliterationResponseFromJson(String str) {
  final jsonData = json.decode(str);
  return new List<TransliterationResponse>.from(
      jsonData.map((x) => TransliterationResponse.fromJson(x)));
}

/// converts back from PODO to json String
String transliterationResponseToJson(List<TransliterationResponse> data) {
  final dyn = new List<dynamic>.from(data.map((x) => x.toJson()));
  return json.encode(dyn);
}

/// PODO class
class TransliterationResponse {
  String sourceString;
  List<String> transliterationSuggestions;

  TransliterationResponse({
    this.sourceString = '',
    this.transliterationSuggestions = const [],
  });

  factory TransliterationResponse.fromJson(Map<String, dynamic> json) =>
      new TransliterationResponse(
        sourceString: json["ew"],
        transliterationSuggestions:
            new List<String>.from(json["hws"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "ew": sourceString,
        "hws": new List<String>.from(transliterationSuggestions.map((x) => x)),
      };
}
