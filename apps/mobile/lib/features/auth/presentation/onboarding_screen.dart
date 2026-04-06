import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color iconBg;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.iconBg,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.send_rounded,
    title: 'Send Money',
    subtitle: 'Globally',
    description:
        'Transfer funds to anyone, anywhere in the world instantly. '
        'Low fees, fast settlement, and support for 50+ currencies.',
    iconBg: Color(0xFFE8F5F3),
  ),
  _OnboardingPage(
    icon: Icons.currency_exchange_rounded,
    title: 'Real Exchange',
    subtitle: 'Rates',
    description:
        'Get live mid-market exchange rates with zero hidden markup. '
        'Convert currencies at the fairest rate available, every time.',
    iconBg: Color(0xFFFFF3E0),
  ),
  _OnboardingPage(
    icon: Icons.shield_rounded,
    title: 'Bank-Level',
    subtitle: 'Security',
    description:
        'Your money is protected by 256-bit encryption, two-factor '
        'authentication, and real-time fraud monitoring 24/7.',
    iconBg: Color(0xFFEDE7F6),
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 20),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageView(page: page);
                },
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.textHint,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 36),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _onNext,
                    child: Text(isLast ? 'Get Started' : 'Next'),
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _goToLogin,
                      child: const Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon card
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 68, color: AppColors.primary),
          ),
          const SizedBox(height: 48),

          // Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              children: [
                TextSpan(text: '${page.title}\n'),
                TextSpan(
                  text: page.subtitle,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
