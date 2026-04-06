import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/services/notification_service.dart';
import 'core/services/deep_link_service.dart';
import 'firebase_options.dart';
import 'app.dart';

// ── Stripe key must be provided via --dart-define=STRIPE_PK=pk_... ──────────
// In debug mode an empty key is tolerated (Stripe features won't work).
// In release mode the build MUST supply the key.
const _stripePublishableKey = String.fromEnvironment('STRIPE_PK');

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Stripe ──────────────────────────────────────────────────────────────
  if (_stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = _stripePublishableKey;
  } else if (kDebugMode) {
    debugPrint('[WARN] STRIPE_PK not set. Pass --dart-define=STRIPE_PK=pk_test_... to enable Stripe.');
  }

  // Lock to portrait orientation for consistent experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar — works with the teal app header
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // ── Firebase, Crashlytics & Push Notifications ──────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wire Crashlytics as the global Flutter/platform error handler
  if (!kDebugMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await NotificationService.init();
  await DeepLinkService.init();

  runApp(const ProviderScope(child: AmixPayApp()));
}

void main() {
  runZonedGuarded(_bootstrap, (error, stack) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}
