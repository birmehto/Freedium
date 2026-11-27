import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Loads the bundled fonts before any test builds a widget.
///
/// `google_fonts` starts a `FontLoader` whenever a text style is created. With
/// real font assets present, that loader tells the engine about new system
/// fonts, which schedules a relayout. Waiting for it here keeps the callback
/// from arriving after a test has already disposed its widget tree.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.inter(fontWeight: FontWeight.w400);
    GoogleFonts.inter(fontWeight: FontWeight.w600);
    GoogleFonts.inter(fontWeight: FontWeight.w700);
    GoogleFonts.sourceSerif4(fontWeight: FontWeight.w400);
    GoogleFonts.sourceSerif4(fontWeight: FontWeight.w600);
    GoogleFonts.sourceSerif4(fontWeight: FontWeight.w700);
    await GoogleFonts.pendingFonts();
  });

  await testMain();
}
