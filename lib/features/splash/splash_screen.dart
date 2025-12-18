import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  int _currentPage = 0;
  bool _isNavigating = false;

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  // Floating particles
  final List<_FloatingParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeAnimations();
    _generateParticles();
    _startAnimations();
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

    // Fade animation for content
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Slide animation for text
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

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
  }

  void _generateParticles() {
    for (int i = 0; i < 20; i++) {
      _particles.add(_FloatingParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 8 + 4,
        speed: _random.nextDouble() * 0.5 + 0.2,
        opacity: _random.nextDouble() * 0.4 + 0.1,
      ));
    }
  }

  void _startAnimations() async {
    // Start logo animation
    _logoController.forward();

    // Delay then start content animations
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();
    _slideController.forward();

    // Auto-advance after animations complete
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    if (_currentPage == 0 && !_isNavigating) {
      _nextPage();
    }
  }

  void _resetAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _resetAnimations();
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    if (_isNavigating) return;
    _isNavigating = true;
    // Always go to home - login prompt will show for protected features
    context.go(AppRoutes.home);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/images/supportive_companion.jpg'),
      context,
    );
    precacheImage(const AssetImage('assets/images/mental_peace.jpg'), context);
    precacheImage(
      const AssetImage('assets/images/community_support.jpg'),
      context,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = ref.watch(stringsProvider);
    final size = MediaQuery.of(context).size;

    final onboardingData = [
      {
        'title': s.onboardingTitle1,
        'subtitle': s.onboardingDesc1,
        'image': 'assets/images/supportive_companion.jpg',
        'color': AppColors.primary,
        'icon': Icons.favorite_rounded,
      },
      {
        'title': s.onboardingTitle2,
        'subtitle': s.onboardingDesc2,
        'image': 'assets/images/mental_peace.jpg',
        'color': const Color(0xFF0D9488),
        'icon': Icons.spa_rounded,
      },
      {
        'title': s.onboardingTitle3,
        'subtitle': s.onboardingDesc3,
        'image': 'assets/images/community_support.jpg',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.people_rounded,
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Stack(
        children: [
          // Animated floating particles background
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _floatAnimation.value,
                  color: (onboardingData[_currentPage]['color'] as Color)
                      .withValues(alpha: 0.3),
                ),
              );
            },
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (isDark ? AppColors.backgroundDark : Colors.white)
                      .withValues(alpha: 0.8),
                  isDark ? AppColors.backgroundDark : Colors.white,
                ],
              ),
            ),
          ),

          // Main content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              _resetAnimations();
            },
            itemCount: onboardingData.length,
            itemBuilder: (context, index) {
              final item = onboardingData[index];
              return _buildOnboardingPage(item, isDark, index);
            },
          ),

          // Bottom navigation
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: _buildBottomNavigation(onboardingData, isDark, s),
          ),

          // Skip button with fade
          if (_currentPage < onboardingData.length - 1)
            Positioned(
              top: 60,
              right: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05),
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

          // Animated image with glow effect
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
                          color: (item['color'] as Color).withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        item['image'] as String,
                        height: 280,
                        width: 280,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 50),

          // Animated icon
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildBreathingIcon(
                item['icon'] as IconData,
                item['color'] as Color,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Animated title with shimmer
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ShaderMask(
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
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Animated subtitle
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                item['subtitle'] as String,
                style: AppTypography.bodyLarge.copyWith(
                  color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                  height: 1.6,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
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
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Animated page indicators
          Row(
            children: List.generate(
              onboardingData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8,
                width: _currentPage == index ? 32 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? onboardingData[_currentPage]['color'] as Color
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: (onboardingData[_currentPage]['color']
                                    as Color)
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),

          // Animated next button with pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: _nextPage,
                child: Transform.scale(
                  scale: _currentPage == onboardingData.length - 1
                      ? _pulseAnimation.value
                      : 1.0,
                  child: Container(
                    height: 60,
                    width: _currentPage == onboardingData.length - 1 ? 140 : 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          onboardingData[_currentPage]['color'] as Color,
                          (onboardingData[_currentPage]['color'] as Color)
                              .withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: (onboardingData[_currentPage]['color'] as Color)
                              .withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentPage == onboardingData.length - 1)
                          Text(
                            s.getStarted,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        if (_currentPage == onboardingData.length - 1)
                          const SizedBox(width: 8),
                        Icon(
                          _currentPage == onboardingData.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.arrow_forward_rounded,
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
      ),
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
    return Matrix4.translationValues(
      bounds.width * (progress * 2 - 1),
      0,
      0,
    );
  }
}
