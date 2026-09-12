import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../utils/app_log.dart';

class ClipboardService extends GetxService {
  /// Copy text to clipboard
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      appLog(e.toString());
    }
  }

  /// Get text from clipboard
  Future<String?> getFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      appLog(e.toString());
      return null;
    }
  }
}
