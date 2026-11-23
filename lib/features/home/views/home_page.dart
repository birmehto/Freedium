import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/animation/app_animator.dart';
import '../../../core/theme/app_theme.dart';
import '../../support/widgets/support_dialog.dart';
import '../widgets/home_hero.dart';
import '../widgets/home_unlock_form.dart';

/// The front door: a masthead, the URL field and a three-step explainer.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HomeHero(),
              const SizedBox(height: 40),
              const HomeUnlockForm(),
              const SizedBox(height: 48),
              AppAnimator.entrance(
                delay: const Duration(milliseconds: 80),
                child: const _Explainer(),
              ),
              const SizedBox(height: 40),
              const _SupportFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Explainer extends StatelessWidget {
  const _Explainer();

  static const _steps = [
    ('1', 'Copy a link', 'Find a Medium story worth reading.'),
    ('2', 'Paste it here', 'Drop the URL into the field above.'),
    ('3', 'Read in peace', 'Just the words, with nothing in the way.'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = AppTheme.ink(context);
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _steps[i].$1,
                style: GoogleFonts.sourceSerif4(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _steps[i].$2,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _steps[i].$3,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (i < _steps.length - 1) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: rule),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }
}

class _SupportFooter extends StatelessWidget {
  const _SupportFooter();

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.muted(context);
    final rule = AppTheme.rule(context);

    return Column(
      children: [
        Divider(height: 1, color: rule),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => showSupportDialog(context),
          child: Text(
            'Support this project',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
