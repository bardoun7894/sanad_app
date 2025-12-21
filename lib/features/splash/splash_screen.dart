import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../routes/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  double _scrollProgress = 0.0;
  bool _isNavigating = false;
  bool _showOnboarding = false; // Controls logo -> onboarding transition

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late AnimationController _loadingController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  // Floating particles
  final List<_FloatingParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
  }

  void _onScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _scrollProgress = _pageController.page ?? 0.0;
      });
    }
  }

  void _initializeAnimations() {
    // Logo animation - scale and subtle rotation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Pulse animation for button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Float animation for particles
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(_floatController);

    // Shimmer animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Loading animation
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _FloatingParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 8 + 4,
          speed: _random.nextDouble() * 0.5 + 0.2,
          opacity: _random.nextDouble() * 0.4 + 0.1,
        ),
      );
    }
  }

  void _startAnimations() async {
    _logoController.forward();

    // Show logo loading for 3 seconds, then transition to onboarding
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    setState(() {
      _showOnboarding = true;
    });
  }

  void _nextPage() {
    final currentPage = _scrollProgress.round();
    if (currentPage < 2) {
      _pageController.animateToPage(
        currentPage + 1,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    if (_isNavigating) return;
    _isNavigating = true;
    context.go(AppRoutes.home);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer precaching to avoid blocking the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (mounted) {
          precacheImage(
            const AssetImage('assets/images/availability.png'),
            context,
          );
          precacheImage(const AssetImage('assets/images/privacy.png'), context);
          precacheImage(const AssetImage('assets/images/booking.png'), context);
          precacheImage(
            const AssetImage('assets/images/community.png'),
            context,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    _logoController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Color _interpolateColor(List<Color> colors, double progress) {
    int index = progress.floor();
    double subProgress = progress - index;

    if (index >= colors.length - 1) return colors.last;
    if (index < 0) return colors.first;

    return Color.lerp(colors[index], colors[index + 1], subProgress)!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final size = MediaQuery.of(context).size;

    // Show logo loading screen first, then onboarding
    if (!_showOnboarding) {
      return _buildLogoLoadingScreen(isDark, s, size);
    }

    return _buildOnboardingScreen(isDark, s, size);
  }

  Widget _buildLogoLoadingScreen(bool isDark, dynamic s, Size size) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Animated floating particles background
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlesPainter(
                    particles: _particles,
                    progress: _floatAnimation.value,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.backgroundDark : Colors.white).withValues(
                    alpha: 0.8,
                  ),
                  isDark ? AppColors.backgroundDark : Colors.white,
                ],
              ),
            ),
          ),

          // Language Switcher (top-left)
          Positioned(top: 50, left: 20, child: _buildLanguageSwitcher(isDark)),

          // Logo and Loading centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animation
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 180,
                              width: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if logo not found
                                return Container(
                                  height: 180,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'سند',
                                      style: AppTypography.headingLarge
                                          .copyWith(
                                            color: Colors.white,
                                            fontSize: 48,
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App name
                Text(
                  s.appName,
                  style: AppTypography.headingLarge.copyWith(
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                Text(
                  s.welcomeSubtitle,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 50),

                // Loading indicator
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeWidth: 3,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Text(
                  s.loading,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitcher(bool isDark) {
    final currentLang = ref.watch(languageProvider);

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getFlagWidget(currentLang.language),
            const SizedBox(width: 8),
            Text(
              _getLanguageCode(currentLang.language).toUpperCase(),
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ],
        ),
      ),
      onSelected: (String langCode) {
        final language = _getAppLanguageFromCode(langCode);
        ref.read(languageProvider.notifier).setLanguage(language);
      },
      itemBuilder: (BuildContext context) => [
        _buildLanguageMenuItem('ar', 'العربية', isDark),
        _buildLanguageMenuItem('en', 'English', isDark),
        _buildLanguageMenuItem('fr', 'Français', isDark),
      ],
    );
  }

  PopupMenuItem<String> _buildLanguageMenuItem(
    String code,
    String name,
    bool isDark,
  ) {
    final languageState = ref.watch(languageProvider);
    final isSelected = _getAppLanguageFromCode(code) == languageState.language;
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          _getFlagWidget(_getAppLanguageFromCode(code)),
          const SizedBox(width: 12),
          Text(
            name,
            style: TextStyle(
              color: isDark ? AppColors.textDark : AppColors.textLight,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, color: AppColors.primary, size: 18),
          ],
        ],
      ),
    );
  }

  Widget _getFlagWidget(AppLanguage language) {
    String flagAsset;
    switch (language) {
      case AppLanguage.arabic:
        flagAsset = 'assets/icons/flag_ar.svg';
        break;
      case AppLanguage.english:
        flagAsset = 'assets/icons/flag_en.svg';
        break;
      case AppLanguage.french:
        flagAsset = 'assets/icons/flag_fr.svg';
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SvgPicture.asset(
        flagAsset,
        width: 24,
        height: 18,
        placeholderBuilder: (context) => Container(
          width: 24,
          height: 18,
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  String _getLanguageCode(AppLanguage language) {
    switch (language) {
      case AppLanguage.arabic:
        return 'AR';
      case AppLanguage.english:
        return 'EN';
      case AppLanguage.french:
        return 'FR';
    }
  }

  AppLanguage _getAppLanguageFromCode(String code) {
    switch (code) {
      case 'en':
        return AppLanguage.english;
      case 'fr':
        return AppLanguage.french;
      case 'ar':
      default:
        return AppLanguage.arabic;
    }
  }

  Widget _buildOnboardingScreen(bool isDark, dynamic s, Size size) {
    final onboardingData = [
      {
        'title': s.onboardingTitle1,
        'subtitle': s.onboardingDesc1,
        'image': 'assets/images/availability.png',
        'color': AppColors.primary,
        'icon': Icons.access_time_rounded,
      },
      {
        'title': s.onboardingTitle2,
        'subtitle': s.onboardingDesc2,
        'image': 'assets/images/privacy.png',
        'color': const Color(0xFF0D9488),
        'icon': Icons.shield_rounded,
      },
      {
        'title': s.onboardingTitle3,
        'subtitle': s.onboardingDesc3,
        'image': 'assets/images/booking.png',
        'color': const Color(0xFF0369A1),
        'icon': Icons.calendar_month_rounded,
      },
      {
        'title': s.onboardingTitle4,
        'subtitle': s.onboardingDesc4,
        'image': 'assets/images/community.png',
        'color': const Color(0xFF7C3AED),
        'icon': Icons.people_rounded,
      },
    ];

    final colors = onboardingData.map((e) => e['color'] as Color).toList();
    final currentColor = _interpolateColor(colors, _scrollProgress);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Animated floating particles background
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _ParticlesPainter(
                    particles: _particles,
                    progress: _floatAnimation.value,
                    color: currentColor.withValues(alpha: 0.3),
                  ),
                );
              },
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.backgroundDark : Colors.white).withValues(
                    alpha: 0.8,
                  ),
                  isDark ? AppColors.backgroundDark : Colors.white,
                ],
              ),
            ),
          ),

          // Main content
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              final item = onboardingData[index];
              final double pageOffset = (_scrollProgress - index).abs();
              final double opacity = (1.0 - pageOffset).clamp(0.0, 1.0);
              final double scale = (1.0 - pageOffset * 0.2).clamp(0.8, 1.0);
              final double slide = pageOffset * 100.0;

              return Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Transform.translate(
                    offset: Offset(0, slide),
                    child: _buildOnboardingPage(item, isDark, index),
                  ),
                ),
              );
            },
          ),

          // Language Switcher (top-left)
          Positioned(top: 50, left: 20, child: _buildLanguageSwitcher(isDark)),

          // Bottom navigation
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: _buildBottomNavigation(
              onboardingData,
              isDark,
              s,
              currentColor,
            ),
          ),

          // Skip button
          if (_scrollProgress < onboardingData.length - 1.5)
            Positioned(
              top: 50,
              right: 20,
              child: Opacity(
                opacity: (onboardingData.length - 1.5 - _scrollProgress).clamp(
                  0.0,
                  1.0,
                ),
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.skip,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(
    Map<String, dynamic> item,
    bool isDark,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),

          // Vector Image with floating animation
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              // Create a gentle up/down float
              final floatOffset = sin(_floatAnimation.value * 2 * pi) * 10.0;
              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: child,
              );
            },
            child: RepaintBoundary(
              child: Container(
                // Removed boxy decoration/clip for vector look
                constraints: const BoxConstraints(maxHeight: 300),
                child: Image.asset(
                  item['image'] as String,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.contain, // Changed to contain for full vector
                  cacheWidth: 600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Breathing icon
          _buildBreathingIcon(item['icon'] as IconData, item['color'] as Color),

          const SizedBox(height: 24),

          // Title with shimmer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      item['color'] as Color,
                      (item['color'] as Color).withValues(alpha: 0.7),
                      item['color'] as Color,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    transform: _ShimmerTransform(_shimmerController.value),
                  ).createShader(bounds);
                },
                child: Text(
                  item['title'] as String,
                  style: AppTypography.headingLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            item['subtitle'] as String,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
              height: 1.6,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingIcon(IconData icon, Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (_pulseAnimation.value - 1) * 0.3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2 * _pulseAnimation.value),
                  blurRadius: 20 * _pulseAnimation.value,
                  spreadRadius: 5 * (_pulseAnimation.value - 1),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigation(
    List<Map<String, dynamic>> onboardingData,
    bool isDark,
    dynamic s,
    Color currentColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Page indicators
        Row(
          children: List.generate(onboardingData.length, (index) {
            final double distance = (_scrollProgress - index).abs();
            final double width = (32.0 - distance * 24.0).clamp(8.0, 32.0);

            return Container(
              margin: const EdgeInsets.only(right: 8),
              height: 8,
              width: width,
              decoration: BoxDecoration(
                color: index == _scrollProgress.round()
                    ? currentColor
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        // Next/Get Started button
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final isLastPage = _scrollProgress >= 1.5;
            final double progress = (_scrollProgress - 1.0).clamp(0.0, 1.0);

            return GestureDetector(
              onTap: _nextPage,
              child: Transform.scale(
                scale: isLastPage ? _pulseAnimation.value : 1.0,
                child: Container(
                  height: 60,
                  width: isLastPage ? 140 : 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentColor,
                        currentColor.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: currentColor.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLastPage)
                        Opacity(
                          opacity: progress,
                          child: Text(
                            s.getStarted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (isLastPage) SizedBox(width: 8 * progress),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Floating particle model
class _FloatingParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Custom painter for floating particles
class _ParticlesPainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final Color color;

  _ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final y = (particle.y + progress * particle.speed) % 1.0;
      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Shimmer gradient transform
class _ShimmerTransform extends GradientTransform {
  final double progress;

  const _ShimmerTransform(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (progress * 2 - 1), 0, 0);
  }
}
