import 'package:flutter/material.dart' as fm;
import 'package:get/get.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_error.dart';
import '../controllers/login_controller.dart';
import '../models/login_purpose.dart';
import '../widgets/login_webview.dart';

/// Medium sign-in, hosted in-app.
///
/// The reader signs in on Medium's own page. When a profile can be read the
/// screen closes with it, and the caller decides what to do with the result.
class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isRefresh = controller.purpose == LoginPurpose.refresh;

    return Scaffold(
      appBar: AppAppBar(
        centerTitle: false,
        title: Text(
          isRefresh ? 'Refreshing profile' : 'Sign in to Medium',
          style: context.text.titleMedium,
        ),
      ),
      body: Stack(
        children: [
          // Deliberately not reactive: the WebView is created once for the
          // initial URL, and later navigations are driven by the controller.
          // Backing out before a profile is read simply yields no result, which
          // the caller already treats as "not signed in".
          LoginWebView(url: controller.initialUrl),
          const _ProgressIndicator(),
          const _ErrorView(),
        ],
      ),
    );
  }
}

class _ProgressIndicator extends GetView<LoginController> {
  const _ProgressIndicator();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final progress = controller.progress.value;

      return Visibility(
        visible: loading,
        maintainAnimation: true,
        maintainState: true,
        child: Align(
          alignment: Alignment.topCenter,
          child: M3EProgressIndicator.linear(
            // A determinate bar that is already full, rather than flipping to
            // an indeterminate spinner at exactly 100%.
            value: progress >= 1 ? 1 : (progress > 0 ? progress : null),
            color: context.colors.primary,
          ),
        ),
      );
    });
  }
}

/// Shown only when a refresh could not read a profile; while signing in the
/// reader's next attempt belongs on Medium's own page, not on an error.
class _ErrorView extends GetView<LoginController> {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final message = controller.errorMessage.value;
      if (message.isEmpty) return const SizedBox.shrink();

      return Positioned.fill(
        child: fm.ColoredBox(
          color: context.colors.surface,
          child: AppError(
            title: 'Could not load your profile',
            message: message,
            hint: 'Your session may have expired. Sign in again to continue.',
            onRetry: controller.retry,
          ),
        ),
      );
    });
  }
}
