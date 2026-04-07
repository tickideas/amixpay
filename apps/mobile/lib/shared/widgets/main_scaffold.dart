import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_router.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/wallet/presentation/transactions_hub_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

// ---------------------------------------------------------------------------
// Main Shell — swipeable PageView across 5 tabs
// ---------------------------------------------------------------------------

class MainScaffold extends StatefulWidget {
  final Widget child; // kept for ShellRoute compatibility
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final PageController _pageController;
  int _currentIndex = 0;
  DateTime? _backPressedAt;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.wallet,
    AppRoutes.qrHub,
    AppRoutes.transactions,
    AppRoutes.settings,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIdx = _indexFromRoute(context);
    if (newIdx != _currentIndex) {
      _currentIndex = newIdx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
  }

  int _indexFromRoute(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    if (loc == AppRoutes.home) return 0;
    if (loc.startsWith('/wallet') || loc.startsWith('/cards')) return 1;
    if (loc.startsWith('/qr')) return 2;
    if (loc.startsWith('/transactions')) return 3;
    if (loc.startsWith('/settings') || loc.startsWith('/profile') ||
        loc.startsWith('/security')) return 4;
    return 0;
  }

  void _onNavTap(int idx) {
    if (_currentIndex == idx) return;
    setState(() => _currentIndex = idx);
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
    context.go(_routes[idx]);
  }

  void _onPageChanged(int idx) {
    if (_currentIndex == idx) return;
    setState(() => _currentIndex = idx);
    context.go(_routes[idx]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // If not on home tab, go home first
        if (_currentIndex != 0) {
          _onNavTap(0);
          return;
        }
        final now = DateTime.now();
        if (_backPressedAt != null &&
            now.difference(_backPressedAt!) < const Duration(seconds: 2)) {
          SystemNavigator.pop();
        } else {
          _backPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: const [
            _KeepAlive(child: HomeScreen()),
            _KeepAlive(child: WalletScreen()),
            _KeepAlive(child: _QrTabPage()),
            _KeepAlive(child: TransactionsHubScreen()),
            _KeepAlive(child: SettingsScreen()),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          selected: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Keep-alive wrapper — preserves page state when swiped off screen
// ---------------------------------------------------------------------------

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ---------------------------------------------------------------------------
// QR Hub Tab — tap to scan or show My QR (camera NOT auto-started)
// ---------------------------------------------------------------------------

class _QrTabPage extends StatelessWidget {
  const _QrTabPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QR Payments',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan to pay or share your code to receive',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // ── Scan QR ──────────────────────────────────────────
                    _QrActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan QR Code',
                      subtitle: 'Point your camera at any AmixPay QR code to pay instantly',
                      color: AppColors.primary,
                      onTap: () => context.push(AppRoutes.qrScanner),
                    ),
                    const SizedBox(height: 16),

                    // ── My QR Code ────────────────────────────────────────
                    _QrActionCard(
                      icon: Icons.qr_code_rounded,
                      title: 'My QR Code',
                      subtitle: 'Show your personal code to receive money from anyone',
                      color: const Color(0xFF7C3AED),
                      onTap: () => context.push(AppRoutes.myQr),
                    ),
                    const SizedBox(height: 32),

                    // ── How it works ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How it works',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 14),
                          _QrStep(
                              number: '1',
                              text: 'Scan the QR code of the person you want to pay'),
                          _QrStep(
                              number: '2',
                              text: 'Confirm the amount and recipient details'),
                          _QrStep(
                              number: '3',
                              text: 'Payment is sent instantly — zero fees'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrActionCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _QrActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ],
          ),
        ),
      );
}

class _QrStep extends StatelessWidget {
  final String number, text;
  const _QrStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Bottom Navigation
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  selected: selected == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Wallet',
                  selected: selected == 1,
                  onTap: () => onTap(1)),
              // QR centre button
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: selected == 2
                              ? AppColors.cardGradient
                              : const LinearGradient(
                                  colors: [Color(0xFF0D6B5E), Color(0xFF0A8A78)]),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0x330D6B5E),
                                blurRadius: selected == 2 ? 16 : 8,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: const Icon(Icons.qr_code_scanner,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Transactions',
                  selected: selected == 3,
                  onTap: () => onTap(3)),
              _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  label: 'Settings',
                  selected: selected == 4,
                  onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? activeIcon : icon,
                  key: ValueKey(selected),
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}
