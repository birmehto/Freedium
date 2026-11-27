import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freedium/core/theme/app_fonts.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runtime font fetching is disabled', () {
    AppFonts.configure();

    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test('every weight used by the theme is bundled', () async {
    for (final name in [
      'Inter-Regular',
      'Inter-SemiBold',
      'Inter-Bold',
      'SourceSerif4-Regular',
      'SourceSerif4-SemiBold',
      'SourceSerif4-Bold',
    ]) {
      final font = await rootBundle.load('assets/fonts/$name.ttf');
      expect(font.lengthInBytes, greaterThan(0), reason: name);
    }
  });
}
