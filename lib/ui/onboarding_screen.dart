import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'widgets/isohedron_logo.dart';

class OnboardingScreen extends StatefulWidget {
  final IsohedronAppController controller;

  const OnboardingScreen({super.key, required this.controller});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  IsohedronAppController get controller => widget.controller;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _proceedToHome() async {
    await controller.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, anim1, anim2) =>
            HomeScreen(controller: controller),
        transitionsBuilder: (context, anim1, anim2, child) =>
            FadeTransition(opacity: anim1, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with brand logo and Skip button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const IsohedronLogo(size: 28, showText: true),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          2,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // Main Carousel
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildSlide1(theme, isDark),
                  _buildSlide2(theme, isDark),
                  _buildSlide3(theme, isDark),
                ],
              ),
            ),

            // Bottom Navigation & Indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primary
                              : (isDark
                                  ? AppTheme.darkOutline
                                  : AppTheme.lightOutline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next Button on Slides 0 & 1
                  if (_currentPage < 2)
                    FilledButton.icon(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      iconAlignment: IconAlignment.end,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'Next',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Slide 1: Welcome & Philosophy ---
  Widget _buildSlide1(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: IsohedronLogo(size: 110),
          ),
          const SizedBox(height: 32),
          Text(
            'Sanctuary of Focus',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'A minimalist geometric space created to give your tasks clarity, rhythm, and peace of mind.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _buildFeatureRow(
            icon: Icons.filter_center_focus_rounded,
            title: 'Geometric Calm',
            description: 'No clutter, notifications overload, or infinite menus.',
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.calendar_today_rounded,
            title: 'Calendar-Day Rhythm',
            description: 'Tasks organize cleanly around actual days without external time drift.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // --- Slide 2: Reflection Loop ---
  Widget _buildSlide2(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withValues(alpha: 0.12),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.autorenew_rounded,
                size: 54,
                color: AppTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Kindness When Plans Change',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'Days don\'t always unfold as planned. Isohedron treats unmet tasks with mindful compassion rather than guilt.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _buildFeatureRow(
            icon: Icons.favorite_border_rounded,
            title: 'Guilt-Free Overdue Flow',
            description: 'Past-due items invite a gentle prompt to reschedule or reflect.',
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.edit_note_rounded,
            title: 'Thoughtful Intentions',
            description: 'Record why a priority shifted so you can let it go with peace.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // --- Slide 3: Sovereign Sanctuary ---
  Widget _buildSlide3(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.shield_outlined,
                  size: 54,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Private by Design',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            'Your thoughts, intentions, and reflections remain 100% on this device. No cloud surveillance, accounts, or telemetry.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          _buildFeatureRow(
            icon: Icons.offline_bolt_outlined,
            title: '100% Offline & Sovereign',
            description: 'Never requires internet connectivity or external credentials.',
            isDark: isDark,
          ),
          const SizedBox(height: 18),
          _buildFeatureRow(
            icon: Icons.lock_outline_rounded,
            title: 'Atomic Durability',
            description: 'Crash-resilient local persistence keeps your data safe.',
            isDark: isDark,
          ),
          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _proceedToHome,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Enter Isohedron',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
