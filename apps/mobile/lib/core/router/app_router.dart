
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/two_factor_screen.dart';
import '../../features/auth/presentation/email_verification_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/wallet/presentation/add_currency_screen.dart';
import '../../features/wallet/presentation/transaction_detail_screen.dart';
import '../../features/payments/presentation/send_money_screen.dart';
import '../../features/payments/presentation/confirm_send_screen.dart';
import '../../features/payments/presentation/send_success_screen.dart';
import '../../features/payments/presentation/request_money_screen.dart';
import '../../features/payments/presentation/payment_requests_screen.dart';
import '../../features/qr/presentation/qr_scanner_screen.dart';
import '../../features/qr/presentation/my_qr_screen.dart';
import '../../features/qr/presentation/qr_payment_confirm_screen.dart';
import '../../features/transfers/presentation/international_transfer_screen.dart';
import '../../features/transfers/presentation/transfer_quote_screen.dart';
import '../../features/transfers/presentation/transfer_confirm_screen.dart';
import '../../features/transfers/presentation/transfer_status_screen.dart';
import '../../features/cards/presentation/my_cards_screen.dart';
import '../../features/cards/presentation/card_detail_screen.dart';
import '../../features/cards/presentation/add_card_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/notifications/presentation/notification_settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/kyc_screen.dart';
import '../../features/profile/presentation/avatar_upload_screen.dart';
import '../../features/security/presentation/security_settings_screen.dart';
import '../../features/security/presentation/change_password_screen.dart';
import '../../features/security/presentation/two_factor_setup_screen.dart';

import '../../features/converter/presentation/currency_converter_screen.dart';
import '../../features/savings/presentation/savings_goals_screen.dart';
import '../../features/analytics/presentation/spending_analytics_screen.dart';

import '../../features/referral/presentation/referral_screen.dart';
import '../../features/scheduled/presentation/scheduled_transfers_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/wallet/presentation/transactions_hub_screen.dart';
import '../../features/funding/presentation/add_funds_screen.dart';
import '../../features/funding/presentation/withdraw_screen.dart';
import '../../features/payments/presentation/zelle_transfer_screen.dart';

import '../../features/legal/presentation/privacy_policy_screen.dart';
import '../../features/legal/presentation/terms_of_service_screen.dart';

import '../../shared/widgets/main_scaffold.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const twoFactor = '/2fa';
  static const emailVerification = '/verify-email';
  static const home = '/home';
  static const wallet = '/wallet';
  static const addCurrency = '/wallet/add-currency';
  static const transactionHistory = '/wallet/transactions';
  static const transactionDetail = '/wallet/transactions/:id';
  static const sendMoney = '/payments/send';
  static const confirmSend = '/payments/confirm';
  static const sendSuccess = '/payments/success';
  static const requestMoney = '/payments/request';
  static const paymentRequests = '/payments/requests';
  static const qrScanner = '/qr/scan';
  static const myQr = '/qr/my-code';
  static const qrPayConfirm = '/qr/confirm';
  static const internationalTransfer = '/transfers/international';
  static const transferQuote = '/transfers/quote';
  static const transferConfirm = '/transfers/confirm';
  static const transferStatus = '/transfers/status/:id';
  static const myCards = '/cards';
  static const cardDetail = '/cards/:id';
  static const addCard = '/cards/add';
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const kyc = '/profile/kyc';
  static const avatarUpload = '/profile/avatar';
  static const security = '/security';
  static const changePassword = '/security/password';
  static const twoFactorSetup = '/security/2fa';


  // ── New world-class features ──────────────────────────────────────────────
  static const currencyConverter = '/converter';
  static const savingsGoals = '/savings';
  static const analytics = '/analytics';

  static const referral = '/referral';
  static const scheduledTransfers = '/scheduled';
  static const transactions = '/transactions';
  static const settings = '/settings';
  static const addFunds = '/funding/add';
  static const withdraw = '/funding/withdraw';
  static const zelleTransfer = '/payments/zelle';

  static const privacyPolicy = '/legal/privacy';
  static const termsOfService = '/legal/terms';

}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.twoFactor, builder: (c, s) => TwoFactorScreen(challengeToken: s.uri.queryParameters['token'] ?? '')),
      GoRoute(path: AppRoutes.emailVerification, builder: (c, s) => EmailVerificationScreen(email: s.uri.queryParameters['email'] ?? '')),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
          GoRoute(path: AppRoutes.wallet, builder: (_, __) => const WalletScreen()),
          GoRoute(path: AppRoutes.myCards, builder: (_, __) => const MyCardsScreen()),
          GoRoute(path: AppRoutes.qrScanner, builder: (_, __) => const QrScannerScreen()),
          GoRoute(path: AppRoutes.transactions, builder: (_, __) => const TransactionsHubScreen()),
          GoRoute(path: AppRoutes.settings, builder: (_, __) => const SettingsScreen()),
          GoRoute(path: AppRoutes.notifications, builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Wallet
      GoRoute(path: AppRoutes.addCurrency, builder: (_, __) => const AddCurrencyScreen()),
      GoRoute(
        path: AppRoutes.transactionHistory,
        builder: (c, s) => TransactionsHubScreen(
          currencyFilter: s.uri.queryParameters['currency'],
        ),
      ),
      GoRoute(path: AppRoutes.transactionDetail, builder: (c, s) => TransactionDetailScreen(transactionId: s.pathParameters['id']!)),

      // Payments
      GoRoute(path: AppRoutes.sendMoney, builder: (_, state) => SendMoneyScreen(initialCurrency: state.extra as String?)),
      GoRoute(path: AppRoutes.confirmSend, builder: (c, s) => ConfirmSendScreen(args: s.extra as Map<String, dynamic>)),
      GoRoute(path: AppRoutes.sendSuccess, builder: (c, s) => SendSuccessScreen(args: s.extra as Map<String, dynamic>)),
      GoRoute(path: AppRoutes.requestMoney, builder: (_, __) => const RequestMoneyScreen()),
      GoRoute(path: AppRoutes.paymentRequests, builder: (_, __) => const PaymentRequestsScreen()),

      // QR
      GoRoute(path: AppRoutes.myQr, builder: (_, __) => const MyQrScreen()),
      GoRoute(path: AppRoutes.qrPayConfirm, builder: (c, s) => QrPaymentConfirmScreen(payload: s.extra as String)),

      // Transfers
      GoRoute(path: AppRoutes.internationalTransfer, builder: (_, __) => const InternationalTransferScreen()),
      GoRoute(path: AppRoutes.transferQuote, builder: (c, s) => TransferQuoteScreen(args: s.extra as Map<String, dynamic>)),
      GoRoute(path: AppRoutes.transferConfirm, builder: (c, s) => TransferConfirmScreen(args: s.extra as Map<String, dynamic>)),
      GoRoute(path: AppRoutes.transferStatus, builder: (c, s) => TransferStatusScreen(transferId: s.pathParameters['id']!)),

      // Cards
      GoRoute(path: AppRoutes.addCard, builder: (_, __) => const AddCardScreen()),
      GoRoute(path: AppRoutes.cardDetail, builder: (c, s) => CardDetailScreen(cardId: s.pathParameters['id']!)),

      // Notifications
      GoRoute(path: AppRoutes.notificationSettings, builder: (_, __) => const NotificationSettingsScreen()),

      // Profile
      GoRoute(path: AppRoutes.editProfile, builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: AppRoutes.kyc, builder: (_, __) => const KycScreen()),
      GoRoute(path: AppRoutes.avatarUpload, builder: (_, __) => const AvatarUploadScreen()),

      // Security
      GoRoute(path: AppRoutes.security, builder: (_, __) => const SecuritySettingsScreen()),
      GoRoute(path: AppRoutes.changePassword, builder: (_, __) => const ChangePasswordScreen()),
      GoRoute(path: AppRoutes.twoFactorSetup, builder: (_, __) => const TwoFactorSetupScreen()),



      // ── World-class new features ────────────────────────────────────────
      GoRoute(path: AppRoutes.currencyConverter, builder: (_, __) => const CurrencyConverterScreen()),
      GoRoute(path: AppRoutes.savingsGoals, builder: (_, __) => const SavingsGoalsScreen()),
      GoRoute(path: AppRoutes.analytics, builder: (_, __) => const SpendingAnalyticsScreen()),

      GoRoute(path: AppRoutes.referral, builder: (_, __) => const ReferralScreen()),
      GoRoute(path: AppRoutes.scheduledTransfers, builder: (_, __) => const ScheduledTransfersScreen()),
      GoRoute(path: AppRoutes.addFunds, builder: (_, state) => AddFundsScreen(initialCurrency: state.extra as String?)),
      GoRoute(path: AppRoutes.withdraw, builder: (_, __) => const WithdrawScreen()),
      GoRoute(path: AppRoutes.zelleTransfer, builder: (_, state) => ZelleTransferScreen(initialCurrency: state.extra as String?)),


      // Legal
      GoRoute(path: AppRoutes.privacyPolicy, builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: AppRoutes.termsOfService, builder: (_, __) => const TermsOfServiceScreen()),


    ],
  );
});
