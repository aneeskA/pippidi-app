const String safeAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

int _counter = 0;

String generateUserId() {
  int timestamp = DateTime.now().microsecondsSinceEpoch;
  int unique = timestamp + _counter;
  _counter++;

  if (unique == 0) return '0';
  String result = '';
  int n = unique;
  while (n > 0) {
    int remainder = n % 32;
    result = safeAlphabet[remainder] + result;
    n = n ~/ 32;
  }
  return result;
}
