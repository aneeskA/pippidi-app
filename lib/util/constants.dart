import 'package:flutter/services.dart';

class Malayalam {
  // App name and general strings
  static const String appName = 'പിപ്പിടി';
  static const String getStarted = 'തുടങ്ങാം';

  // onboarding
  static const String appDescription =
      'ലോകത്തിലെ ഏക സമ്പൂർണ മലയാളം ആപ്പ്. മലയാളികൾക്ക് വേണ്ടി മലയാളി നിർമിച്ചത്.';
  static const String onboardingKadankathaTitle = 'കടങ്കഥകൾ';
  static const String onboardingKadankathaDescription =
      'മലയാള ഭാഷയിലെ തന്ത്രപരമായ ചോദ്യങ്ങളാണ് കടങ്കഥകൾ. അവയുടെ വലിയൊരു ശേഖരമാണ് പിപ്പിടിയിൽ ഒരുക്കിയിരിക്കുന്നത്.';
  static const String onboardingBattleTitle = 'പോരാട്ടം';
  static const String onboardingBattleDescription =
      'സുഹൃത്തുക്കളുടെ കൂടെ പോരടിക്കാനുള്ള അവസരം. ആരാണ് നിങ്ങളുടെ കൂട്ടത്തിലെ തങ്കപ്പനും പൊന്നപ്പനും!';

  // navigation
  static const String home = 'താവളം';
  static const String play = 'കളിക്കളം';
  static const String profile = 'ഞാൻ';

  // home
  static const String pointsTable = 'സ്ഥിതി';
  static const String greeting1 = "നൂറ് കണക്കിന് ചോദ്യങ്ങൾ";
  static const String greeting2 = "കേട്ടുമറന്ന ഉത്തരങ്ങൾ";
  static const String greeting3 = 'ഗതകാലത്തിന്റെ പ്രൗഢസമരണകൾ';
  String share(String id) {
    return 'മച്ചാനെ! പിപ്പിടി എന്ന കളിയിൽ എന്റെ കൂടെ കൂടുന്നോ?\n\nകടങ്കഥകളും കുസൃതി ചോദ്യങ്ങളുമായി മല്ലിടാനുള്ള അവസരമാണിത്. പിപ്പിടി ഇൻസ്റ്റാൾ ചെയ്തിട്ട് ${id} എന്ന കോഡ് ചേർത്താൽ മതി.\n\nപിപ്പിടി കിട്ടാൻ ഈ ലിങ്കിൽ ഞെക്കിയാൽ മതി https://pippidi.com/download';
  }

  // profile
  static const String acheivements = 'പതക്കങ്ങൾ';
  static const String suggestions = 'ആശയം';
  static const String suggestionEmail = 'pippidi.com@gmail.com';
  static const String suggestionPrompt =
      'ഈ കളിയെ മെച്ചപ്പെടുത്താൻ നിങ്ങളുടെ കയ്യിൽ ആശയങ്ങൾ ഉണ്ടെങ്കിൽ ഞങ്ങളെ എഴുതി അറിയിക്കൂ - pippidi.com@gmail.com';
  String suggestionPromptCopy(String email) =>
      'ഇമെയിൽ അഡ്രസ് ക്ലിപ്പ്ബോർഡിലേക്ക് കോപ്പി ചെയ്തു: $email';
  static const String medal = ' പതക്കം';
  static const String points = ' പോയിന്റ്';
  static const String correct = 'ശരി';
  static const String wrong = 'തെറ്റ്';
  static const String save = 'സൂക്ഷിക്കുക';
  static const String newName = 'കളിക്കാരന്റെ പേര്';
  static const String switchUser = 'കളിക്കാരനെ മാറ്റുക';
  static const String createNewUser = 'പുതിയ കളിക്കാരൻ';
  static const String switchedTo = 'കളിക്കാരൻ മാറി:';
  String shareLink(String id) {
    return 'https://pippidi.com/user/$id';
  }

  String shareCodeOnly(String link) {
    return 'പിപ്പിടിയിൽ എന്റെ സ്കോർ കാണാൻ $link എന്ന ലിങ്ക് തുറന്നാൽ മതി. പിപ്പിടി ഇല്ലെങ്കിൽ ആപ്പ് സ്റ്റോറിലോട്ട് പോകും. ഇൻസ്റ്റാൾ ചെയ്തതിന് ശേഷം ഒന്നൂടെ ലിങ്ക് ക്ലിക്ക് ചെയ്യാൻ മറക്കരുത്.';
  }

  String shareImageAndText(String link) {
    return 'ക്യൂ ആർ സ്കാൻ ചെയ്യുകയോ $link എന്ന ലിങ്ക് തുറക്കുകയോ ചെയ്‌താൽ എന്റെ സ്കോർ നിങ്ങൾക്ക് കാണാൻ പറ്റും.';
  }

  static const String feedback_sending = 'നിർദേശം അയക്കുന്നു ...';
  static const String feedback_sending_failed =
      'ക്ഷമിക്കണം. നിർദേശം അയക്കാൻ പറ്റുന്നില്ല. അൽപനേരം കഴിഞ്ഞ് ശ്രമിക്കുക.';
  static const String feedback_sending_success = 'നന്ദി! നിർദേശം കിട്ടി.';

  // Notification messages
  static const String newQuestionsReady =
      'പുതുപുത്തൻ ചോദ്യങ്ങൾ റെഡി. നീങ്ക റെഡിയാ?';
  static const String allUpToDate =
      'ഒന്നും പേടിക്കാനില്ല! എല്ലാം അപ്പ് ടു ഡേറ്റ് ആണ്';

  // Category names
  static const String kadamkatha = 'കടങ്കഥ';
  static const String kusruthy = 'കുസൃതി';
  static const String charithram = 'ചരിത്രം';
  static const String aanukalikam = 'ആനുകാലികം';
  static const String cinema = 'സിനിമ';
  static const String letter = 'അക്ഷരക്കളരി';
  static const String futureCategory = 'ഭാവി കാറ്റഗറി';

  // Game related strings
  static const String gameFinished = 'തീർന്നുപോയി!';
  static const String freeQuestionsInfoPrompt =
      'നോ പ്രോബ്ലം. ഈ വിഭാഗത്തിലെ ചോദ്യങ്ങൾ തികച്ചും സൗജന്യം ആണ്. ചോദ്യങ്ങൾ വരുന്നത് അറിയാൻ നോട്ടിഫിക്കേഷൻ ഓൺ ആക്കി വച്ചാൽ മതി.';
  static const String freeQuestionsInfo =
      'നോ പ്രോബ്ലം. ഈ വിഭാഗത്തിലെ ചോദ്യങ്ങൾ തികച്ചും സൗജന്യം ആണ്. നോട്ടിഫിക്കേഷൻ ഓൺ ആയത് കൊണ്ട് അവ വരുമ്പോ അറിഞ്ഞോളും.';
  static String noNegativePointsFor(int n) =>
      'ഇനിയുള്ള $n ചോദ്യത്തിന് നെഗറ്റീവ് പോയിന്റ് ഇല്ല.';
  static const String noNegativeForThisQuestion =
      'പോട്ടെ. സാരമില്ല. അടുത്ത ചോദ്യത്തിന് നെഗറ്റീവ് പോയിന്റ് ഇല്ല.';
  static const String loadingQuestion = 'ദേ വരുന്നു ചോദ്യം ...';
  static const String clue = 'സൂചന';

  // User account strings
  static const String cameraPermissionError =
      'ക്യാമറ തുറക്കാനുള്ള അനുവാദം തന്നിട്ടില്ല. ദയവായി സെറ്റിങ്സിൽ ചെന്ന് ഓൺ ആക്കിയിട്ട് തിരികെ വരൂ.';
  static const String galleryPermissionError =
      'ഗാലറി തുറക്കാനുള്ള അനുവാദം തന്നിട്ടില്ല. ദയവായി സെറ്റിങ്സിൽ ചെന്ന് ഓൺ ആക്കിയിട്ട് തിരികെ വരൂ.';
  static const String feedbackSuggestion = 'അഭിപ്രായം / നിര്‍ദ്ദേശം';
  static const String feedbackHint =
      'ഈ കളിയെ മെച്ചപ്പെടുത്താൻ നിങ്ങൾക്ക് ആശയം ഉണ്ടോ?\nഞങ്ങളെ അറിയിക്കൂ.';
  static const String friendCodeHint = 'സുഹൃത്തിന്റെ കോഡ്';
  static const String add = 'ചേർക്കുക';
  static const String cancel = 'വേണ്ട';
  static const String ok = 'ഓക്കേ';
  static const String great = 'അടിപൊളി!';
  static const String later = '5 ചോദ്യം സൗജന്യം!';
  static const String shareLabel = 'ഷെയർ';
  static const String saveLabel = 'സേവ്';
  static const String shareQR = 'എന്റെ കോഡ് പങ്ക് വെക്കുക';
  static const String enterCode = 'കോഡ് സ്കാൻ ചെയ്യുക';
  static const String scanQRInfo =
      'സുഹൃത്തിന്റെ സ്കോർ കാണാൻ പുള്ളിയുടെ ക്യൂ. ആർ. കോഡ് സ്കാൻ ചെയ്യുകയോ കോഡിന്റെ പടം അപ്‌ലോഡ് ചെയ്യുകയോ ചെയ്യാം.';
  static const String noQRCode = 'കോഡ് കണ്ടെത്താനായില്ല';
  static const String failedToSaveProfilePicture =
      "ഫോട്ടോ സൂക്ഷിച്ചു വെക്കാൻ പറ്റിയില്ല";

  // Share strings
  static const String shareFooter = 'pippidi.com - സാധനം കയ്യിലുണ്ടോ?!';
  static const String shareButtonHaveIt = 'കയ്യിലുണ്ട്';
  static const String downloadUrl = 'https://pippidi.com/download';

  // Purchase related strings
  static const String purchaseCancelled =
      'നോ പ്രോബ്ലം. ഇപ്പൊ വേണ്ടെങ്കിൽ വേണ്ട. പിന്നെ വാങ്ങിയാലും മതി.';
  static const String purchaseNotAllowed =
      'താങ്കൾക്ക് ഇത് വാങ്ങുന്നതിനുള്ള അനുവാദം ഇല്ല!';
  static const String purchaseError =
      'എന്തോ തകരാറ് സംഭവിച്ചു. വീണ്ടും അൽപ സമയത്തിന് ശേഷം ശ്രമിക്കുക.';
  static String buyQuestions(int count) => 'വാങ്ങാം $count ചോദ്യങ്ങൾ';
  static String purchasedQuestions(int count) =>
      '$count ചോദ്യങ്ങൾ നിങ്ങൾ വാങ്ങിക്കഴിഞ്ഞു.';

  // User name onboarding
  static const String nameQuestion = 'എന്താണ് നിങ്ങളുടെ പേര്?';
  static const String typeToStart = 'ടൈപ്പ് ചെയ്തു തുടങ്ങൂ...';

  // Username validation
  static const int maxUsernameLength = 100;

  // User management
  static const int maxUsersAllowed = 3;

  // Skip feature
  static const int SKIP_CORRECT_THRESHOLD = 10;
  static String skipEarnedMessage(int consecutiveCorrect, int skipCount) =>
      skipCount == 1
          ? "അടുപ്പിച്ച് ${consecutiveCorrect} ചോദ്യം ശരിയാക്കിയത് കൊണ്ട് ഒരു ചോദ്യത്തിനെ ചാടിക്കടക്കാനുള്ള അവസരം"
          : "പിന്നെയും അടുപ്പിച്ച് ${consecutiveCorrect} ചോദ്യം ശരിയാക്കിയത് കൊണ്ട് ഒരു ചോദ്യത്തിനെ കൂടി ചാടിക്കടക്കാനുള്ള അവസരം";

  // Validation function for Malayalam names
  static bool isValidMalayalamName(String text) {
    if (text.isEmpty) return false;

    // Malayalam Unicode range: U+0D00 to U+0D7F
    // Allow Malayalam characters, spaces, and basic Malayalam punctuation
    final malayalamRegex = RegExp(r'^[\u0D00-\u0D7F\s\u0D4D\u0D3F\u0D57]*$');

    // Must match Malayalam regex AND not contain English letters
    final englishLettersRegex = RegExp(r'[A-Za-z]');
    return malayalamRegex.hasMatch(text) && !englishLettersRegex.hasMatch(text);
  }

  // Input formatter that only allows Malayalam characters during typing
  static final TextInputFormatter malayalamInputFormatter =
      TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow empty text
      if (newValue.text.isEmpty) {
        return newValue;
      }

      // For input formatting, we need to be more permissive during typing
      // Allow Malayalam characters, English letters (for transliteration), spaces
      // But reject numbers and special characters
      final allowedRegex =
          RegExp(r'^[\u0D00-\u0D7F\u0D4D\u0D3F\u0D57A-Za-z\s]*$');
      final unwantedCharsRegex =
          RegExp("[0-9'\"/!@#\\\$%^&*()_+\\-=\\[\\]{}|;:,.<>?`~\\\\]");

      if (!allowedRegex.hasMatch(newValue.text) ||
          unwantedCharsRegex.hasMatch(newValue.text)) {
        return oldValue; // Reject invalid characters
      }

      return newValue;
    },
  );

  // Legacy formatter - allows letters and spaces, rejects special chars (kept for compatibility)
  static final TextInputFormatter lenientInputFormatter =
      TextInputFormatter.withFunction(
    (oldValue, newValue) {
      // Allow empty text
      if (newValue.text.isEmpty) {
        return newValue;
      }

      // Allow letters and spaces only - reject special characters, numbers, quotes, slashes, and emojis
      final unwantedCharsRegex = RegExp(
          "[0-9'\"/!@#\\\$%^&*()_+\\-=\\[\\]{}|;:,.<>?`~\\\\\u2018\u2019\u201C\u201D]");
      final emojiRegex = RegExp(r'[\uD83C-\uDBFF\uDC00-\uDFFF]');

      // Explicitly check for quotes and forward slash, plus regex checks
      if (unwantedCharsRegex.hasMatch(newValue.text) ||
          emojiRegex.hasMatch(newValue.text)) {
        return oldValue; // Reject if contains unwanted characters or emojis
      }

      return newValue;
    },
  );

  // Friend related messages
  static String friendChecking(String id) => "$id വിശദാംശം നോക്കുന്നു ...";
  static String friendNotFound(String id) => "$id നോക്കിയിട്ട് കാണുന്നില്ല";
  static String friendAdded(String label) => "$label വിശദാംശം ചേർത്തിട്ടുണ്ട്!";

  // Badge texts
  static final Map<String, String> badgeWonMessages = {
    '1': 'ഗംഭീരം! നിങ്ങളുടെ ആദ്യത്തെ ശരി ഉത്തരം',
    '2': 'അതിഗംഭീരം! അടുപ്പിച്ച് മൂന്ന് ശരിയുത്തരം',
    '3': 'അടിപൊളി! അടുപ്പിച്ച് അഞ്ചു ശരിയുത്തരം',
    '4': 'കിക്കിടു! അടുപ്പിച്ച് പത്ത് ശരിയുത്തരം',
    '5': 'പൊന്നപ്പൻ! അടുപ്പിച്ച് അമ്പത് ശരിയുത്തരം',
    '8': 'പൊളി! ആയിരം പോയിന്റ് നേടി',
    '9': 'കിടു! രണ്ടായിരം പോയിന്റ് നേടി',
    '10': 'ബല്ലേ ബല്ലേ! അയ്യായിരം പോയിന്റ് നേടി.',
    '11': 'തങ്കപ്പൻ! പതിനായിരം പോയിന്റ് നേടി',
    '12': 'എന്റമ്മോ! അടുപ്പിച്ച് ഇരുപത് ശരിയുത്തരം.',
    '14': 'തമ്പുരാൻ! പതിനയ്യായിരം പോയിന്റ് നേടി',
    '15': 'പുലി! ഇരുപതിനായിരം പോയിന്റ് നേടി',
    '16': 'പുപ്പുലി! അടുപ്പിച്ച് ഇരുനൂറ് ശരിയുത്തരം',
    '17': 'ബാഹുബലി! അമ്പതിനായിരം പോയിന്റ് നേടി',
    '18': 'ഡിങ്കൻ! ഒരു ലക്ഷം പോയിന്റ് നേടി',
  };

  static String badgeWonText(String key) => badgeWonMessages[key] ?? '';
}
