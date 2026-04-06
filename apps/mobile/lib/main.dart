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

const _stripePublishableKey = String.fromEnvironment(
  'STRIPE_PK',
  defaultValue: 'pk_test_51TAZ64L7INWPLV8q5D9Zw0fcXZx5Jv857470VsJWCIiXsH1XKGe50OnUUrL842Vq6PhnjXK5FnFnPqzN5utt6wOT00yf60dkjf',
);

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Stripe ──────────────────────────────────────────────────────────────
  Stripe.publishableKey = _stripePublishableKey;

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
