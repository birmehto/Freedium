import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../utils/app_log.dart';

class ClipboardService extends GetxService {
  /// Copy text to clipboard.
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      appLog(
        'Failed to copy to clipboard',
        name: 'Clipboard',
        level: LogLevel.warning,
      );
      appLog(e.toString(), name: 'Clipboard');
    }
  }

  /// Get text from clipboard.
  Future<String?> getFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      appLog(
        'Failed to read from clipboard',
        name: 'Clipboard',
        level: LogLevel.warning,
      );
      appLog(e.toString(), name: 'Clipboard');
      return null;
    }
  }
}
