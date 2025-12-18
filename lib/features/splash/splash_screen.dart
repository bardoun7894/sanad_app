import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/l10n/language_provider.dart';
import '../../routes/app_router.dart';
import '../auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  bool _isNavigating = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    _fadeController.forward();
    _scaleController.forward();

    // Check auth status after initial animation/delay
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Give user some time to see the splash if needed,
    // but we'll wait for them to finish onboarding if it's their first time
    // For now, let's just wait 3 seconds total for the first slide
    await Future.delayed(const Duration(seconds: 4));

    if (_currentPage == 0 && !_isNavigating) {
      _nextPage();
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    if (_isNavigating) return;
    _isNavigating = true;

    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final onboardingData = [
      {
        'title': 'Sanad',
        'subtitle': 'Your companion for mental wellness and support.',
        'image': 'assets/images/splash_illustration.png',
        'color': AppColors.primary,
      },
      {
        'title': 'Track Your Mood',
        'subtitle': 'Understand your emotions with our daily mood tracker.',
        'image': 'assets/images/mood_feature.png',
        'color': const Color(0xFF0D9488),
      },
      {
        'title': 'Professional Support',
        'subtitle': 'Connect with therapists and a supportive community.',
        'image': 'assets/images/chat_feature.png',
        'color': const Color(0xFF2563EB),
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              final item = onboardingData[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Image.asset(
                              item['image'] as String,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                item['title'] as String,
                                style: AppTypography.headingLarge.copyWith(
                                  color: item['color'] as Color,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                item['subtitle'] as String,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: isDark
                                      ? AppColors.textMuted
                                      : AppColors.textMutedLight,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // Navigation controls
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    onboardingData.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? onboardingData[_currentPage]['color'] as Color
                            : (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                // Next/Get Started button
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: onboardingData[_currentPage]['color'] as Color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (onboardingData[_currentPage]['color'] as Color)
                                  .withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _currentPage == onboardingData.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Skip button
          if (_currentPage < onboardingData.length - 1)
            Positioned(
              top: 60,
              right: 20,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
