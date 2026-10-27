// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'widgets/isohedron_logo.dart';

/// Authentic iOS "Welcome to Isohedron" onboarding sheet.
class OnboardingScreen extends StatefulWidget {
  final IsohedronAppController controller;

  const OnboardingScreen({super.key, required this.controller});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isSigningIn = false;
  String? _signInFeedback;

  IsohedronAppController get controller => widget.controller;

  Future<void> _proceedToHome() async {
    unawaited(HapticFeedback.lightImpact());
    await controller.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, anim1, anim2) =>
            HomeScreen(controller: controller),
        transitionsBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showTokenSheet() {
    final tokenController = TextEditingController();
    final emailController = TextEditingController();

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBg = isDark
            ? AppTheme.darkSecondaryGroupedBackground
            : AppTheme.lightSecondaryGroupedBackground;
        final inputBg = isDark
            ? AppTheme.darkTertiaryGroupedBackground
            : AppTheme.systemGray6Light;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 32,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Text(
                        'Direct OAuth Token',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 32,
                        onPressed: () async {
                          final token = tokenController.text.trim();
                          if (token.isEmpty) return;
                          Navigator.of(ctx).pop();
                          setState(() => _isSigningIn = true);
                          final ok = await controller.connectGoogleWithToken(
                            token,
                            email: emailController.text.trim(),
                          );
                          if (ok) {
                            await _proceedToHome();
                          } else {
                            setState(() {
                              _isSigningIn = false;
                              _signInFeedback =
                                  'Token connection failed: ${controller.googleLastError}';
                            });
                          }
                        },
                        child: const Text(
                          'Connect',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: emailController,
                    placeholder: 'Account Email (optional)',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: tokenController,
                    placeholder: 'OAuth Bearer Token (ya29...)',
                    maxLines: 2,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffoldBg = isDark
        ? AppTheme.darkSystemGroupedBackground
        : AppTheme.lightSystemGroupedBackground;

    final textPrimary =
        isDark ? AppTheme.darkLabelPrimary : AppTheme.lightLabelPrimary;

    final textSecondary =
        isDark ? AppTheme.darkLabelSecondary : AppTheme.lightLabelSecondary;

    final systemBlue = isDark ? AppTheme.darkSystemBlue : AppTheme.systemBlue;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Apple App Header
              const IsohedronLogo(size: 64),
              const SizedBox(height: 18),
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: textPrimary,
                ),
              ),
              Text(
                'Isohedron',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: systemBlue,
                ),
              ),

              const Spacer(flex: 2),

              // Feature Rows in Apple HIG Style
              _FeatureRow(
                icon: CupertinoIcons.checkmark_alt_circle_fill,
                iconColor: systemBlue,
                title: 'Minimalist & Direct',
                subtitle:
                    'Zero-friction task capture with scheduled reminders and swift organization.',
                textColor: textPrimary,
                secondaryColor: textSecondary,
              ),
              const SizedBox(height: 24),

              _FeatureRow(
                icon: CupertinoIcons.arrow_2_circlepath_circle_fill,
                iconColor:
                    isDark ? AppTheme.darkSystemOrange : AppTheme.systemOrange,
                title: 'Accountability Loop',
                subtitle:
                    'A gentle reflection pause on postponed tasks helps build realistic momentum.',
                textColor: textPrimary,
                secondaryColor: textSecondary,
              ),
              const SizedBox(height: 24),

              _FeatureRow(
                icon: CupertinoIcons.shield_fill,
                iconColor:
                    isDark ? AppTheme.darkSystemGreen : AppTheme.systemGreen,
                title: 'Local-First & Private',
                subtitle:
                    'Your data stays offline on your device, with optional Google Tasks cloud sync.',
                textColor: textPrimary,
                secondaryColor: textSecondary,
              ),

              const Spacer(flex: 3),

              if (_signInFeedback != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _signInFeedback!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? AppTheme.darkSystemRed : AppTheme.systemRed,
                    ),
                  ),
                ),

              // Google Tasks quick connect link
              CupertinoButton(
                padding: const EdgeInsets.only(bottom: 14),
                minSize: 32,
                onPressed: _isSigningIn
                    ? null
                    : () async {
                        unawaited(HapticFeedback.selectionClick());
                        setState(() {
                          _isSigningIn = true;
                          _signInFeedback = null;
                        });
                        try {
                          final ok = await controller.signInGoogle();
                          if (ok) {
                            await _proceedToHome();
                          } else {
                            // If Google Play is absent, offer direct token
                            _showTokenSheet();
                          }
                        } catch (_) {
                          _showTokenSheet();
                        } finally {
                          if (mounted) setState(() => _isSigningIn = false);
                        }
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.cloud, size: 16, color: systemBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Optional Google Tasks Sync',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: systemBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // Pinned Apple Primary Action Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: _proceedToHome,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color secondaryColor;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 36, color: iconColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  letterSpacing: -0.1,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
