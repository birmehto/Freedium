import 'package:flutter/services.dart';

import '../utils/app_log.dart';

/// Thin wrapper around the clipboard, kept out of the features so they never
/// depend on the platform channel directly.
class ClipboardService {
  Future<String?> getFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (error) {
      appLog('Failed to read from clipboard: $error', name: 'Clipboard');
      return null;
    }
  }
}
