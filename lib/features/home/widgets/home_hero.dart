import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';

/// The editorial masthead: one small green signal, a serif name and a single
/// quiet line. No gradient, badge or decorative icon.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.accent(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'READ WITHOUT NOISE',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: muted, letterSpacing: 1.6),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Freedium',
          textAlign: TextAlign.center,
          style: GoogleFonts.sourceSerif4(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: ink,
            letterSpacing: -2.4,
            height: 1,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            'Read the stories you love, without the paywall or the clutter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: muted, height: 1.5),
          ),
        ),
      ],
    );
  }
}
