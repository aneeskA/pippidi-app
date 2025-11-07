import 'package:upgrader/upgrader.dart';

class MalayalamMessages extends UpgraderMessages {
  /// Override the message function to provide custom language localization.
  @override
  String? message(UpgraderMessage messageKey) {
    if (languageCode == 'ml') {
      switch (messageKey) {
        case UpgraderMessage.body:
          return 'ml പിപ്പിടിയുടെ പുതിയ വേർഷൻ വന്നിട്ടുണ്ട്!';
        case UpgraderMessage.buttonTitleIgnore:
          return 'ml വേണ്ട';
        case UpgraderMessage.buttonTitleLater:
          return 'ml പിന്നെ';
        case UpgraderMessage.buttonTitleUpdate:
          return 'ml ഇപ്പൊ തന്നെ';
        case UpgraderMessage.prompt:
          return 'ml പുതിയത് സെറ്റ് ആക്കിയാലോ?';
        case UpgraderMessage.releaseNotes:
          return 'ml വിവരണം';
        case UpgraderMessage.title:
          return 'ml പുതിയത് സെറ്റ് ആക്കട്ടെ?';
      }
    }

    // Messages that are not provided above can still use the default values.
    return super.message(messageKey);
  }
}
