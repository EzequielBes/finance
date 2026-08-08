import 'dart:isolate';

import 'package:mobile/services/import/bank_detector.dart';
import 'package:mobile/services/import/import_result.dart';

class BankImportService {
  const BankImportService();

  Future<ImportResult?> parse(String content) {
    return Isolate.run(() => _detectAndParse(content));
  }
}

ImportResult? _detectAndParse(String content) {
  final parser = const BankDetector().detect(content);
  return parser?.parse(content);
}
