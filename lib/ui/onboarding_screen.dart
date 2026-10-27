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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? AppTheme.darkSecondaryGroupedBackground
        : AppTheme.lightSecondaryGroupedBackground;
    final textPrimary =
        isDark ? AppTheme.darkLabelPrimary : AppTheme.lightLabelPrimary;
    final textSecondary =
        isDark ? AppTheme.darkLabelSecondary : AppTheme.lightLabelSecondary;
    final systemBlue = isDark ? AppTheme.darkSystemBlue : AppTheme.systemBlue;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),

                    // App Logo with Apple squircle framing
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: systemBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: IsohedronLogo(size: 48),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Large Apple Title
                    Text(
                      'Welcome to\nIsohedron',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.0,
                        height: 1.15,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mindful intentions for sovereign living.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Feature Bullets (SF-style squircle icons)
                    _buildFeatureItem(
                      icon: CupertinoIcons.clock_fill,
                      iconBg: systemBlue,
                      title: 'Mindful Planning',
                      description:
                          'Schedule daily tasks with calm intention rather than stressful deadlines.',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 24),

                    _buildFeatureItem(
                      icon: CupertinoIcons.heart_fill,
                      iconBg:
                          isDark ? AppTheme.darkSystemRed : AppTheme.systemRed,
                      title: 'Guilt-Free Overdue Flow',
                      description:
                          'Unmet tasks prompt gentle reflection and rescheduling with peace, not guilt.',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 24),

                    _buildFeatureItem(
                      icon: CupertinoIcons.shield_fill,
                      iconBg: isDark
                          ? AppTheme.darkSystemGreen
                          : AppTheme.systemGreen,
                      title: '100% Private & Sovereign',
                      description:
                          'Everything lives strictly on this device. No cloud sync, accounts, or telemetry.',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Pinned Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  borderRadius: BorderRadius.circular(14),
                  onPressed: _proceedToHome,
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String description,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: CupertinoColors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  letterSpacing: -0.2,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
