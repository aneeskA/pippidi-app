import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pippidi/data/questions.dart';

class InstallQuestions {
  Future<bool> Do() async {
    bool status = false;
    try {
      String url = 'https://www.pippidi.com/vintage.txt?time=' +
          DateTime.now().microsecondsSinceEpoch.toString();
      var response = await Dio().get(url);
      LineSplitter ls = new LineSplitter();
      List<String> lines = ls.convert(response.data.toString());
      for (int start = Questions().vintage + 1; start < lines.length; start++) {
        try {
          final pieces = lines[start].split(',');
          // IMP: ENSURE THE FILES ARE IN CRLF Encoding.
          var response = await Dio().get(pieces[1]);

          await Questions().addQuestions(pieces[0], response.data.toString());
          Questions().vintage++;

          status = true;
        } catch (e) {
          return false;
        }
      }

      return status;
    } catch (e) {
      return false;
    }
  }
}
