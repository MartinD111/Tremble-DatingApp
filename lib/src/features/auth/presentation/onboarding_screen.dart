import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../../../core/translations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String get _lang => ref.read(authStateProvider)?.appLanguage ?? 'en';
  String tr(String key) => t(key, _lang);

  List<_OnboardingData> _getSlides(BuildContext context) => [
    _OnboardingData(
      titleKey: 'onb1_title',
      bodyKey: 'onb1_body',
      emoji: '👋',
      accentColor: Theme.of(context).colorScheme.primary,
    ),
    const _OnboardingData(
      titleKey: 'onb2_title',
      bodyKey: 'onb2_body',
      emoji: '🚫',
      accentColor: Color(0xFF64B5F6),
    ),
    const _OnboardingData(
      titleKey: 'onb3_title',
      bodyKey: 'onb3_body',
      emoji: '🗺️',
      accentColor: Color(0xFFFFD54F),
    ),
  ];

  void _next() {
    final slidesCount = _getSlides(context).length;
    if (_currentPage < slidesCount - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = _getSlides(context);
    final slide = slides[_currentPage];
    final isLast = _currentPage == slides.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                  child: isLast
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Skip',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14)),
                        ),
                ),
              ),
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (ctx, i) => _buildSlide(slides[i]),
                ),
              ),
              // Dots + button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(slides.length, (i) {
                        final active = i == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? slide.accentColor : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 28),
                    // Continue button (always active)
                    GestureDetector(
                      onTap: _next,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            isLast
                                ? tr('confirm_btn').toUpperCase()
                                : tr('continue_btn').toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  letterSpacing: 1.2,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in glowing circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.accentColor.withValues(alpha: 0.1),
              border: Border.all(
                  color: data.accentColor.withValues(alpha: 0.2), width: 1),
            ),
            child: Center(
                child: Text(data.emoji, style: const TextStyle(fontSize: 52))),
          ),
          const SizedBox(height: 48),
          Text(
            tr(data.titleKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            tr(data.bodyKey),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String titleKey;
  final String bodyKey;
  final String emoji;
  final Color accentColor;

  const _OnboardingData({
    required this.titleKey,
    required this.bodyKey,
    required this.emoji,
    required this.accentColor,
  });
}
