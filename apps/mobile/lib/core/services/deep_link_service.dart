import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Handles incoming deep links:
///   amixpay://payment/callback?status=successful&tx_ref=...&transaction_id=...
///   https://amixpay.com/payment/callback?...  (App Link / Universal Link)
///
/// Usage — call [init] once at startup (before runApp), then listen to [stream].
class DeepLinkService {
  DeepLinkService._();

  static final _controller = StreamController<Uri>.broadcast();
  static Stream<Uri> get stream => _controller.stream;

  static AppLinks? _appLinks;

  static Future<void> init() async {
    if (kIsWeb) return;
    _appLinks = AppLinks();

    // Handle the link that launched a cold-start
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) _controller.add(initial);
    } catch (_) {}

    // Handle links while app is running (foreground / background)
    _appLinks!.uriLinkStream.listen(
      (uri) => _controller.add(uri),
      onError: (_) {},
    );
  }

  /// Parse a Flutterwave callback URI and return the payment result.
  /// Returns `null` if the URI is not a Flutterwave callback.
  static FlutterwaveCallbackResult? parseFlutterwaveCallback(Uri uri) {
    final isCallback =
        (uri.scheme == 'amixpay' && uri.host == 'payment' && uri.path == '/callback') ||
        (uri.host == 'amixpay.com' && uri.path == '/payment/callback');

    if (!isCallback) return null;

    return FlutterwaveCallbackResult(
      status: uri.queryParameters['status'] ?? '',
      txRef: uri.queryParameters['tx_ref'] ?? '',
      transactionId: uri.queryParameters['transaction_id'] ?? '',
    );
  }

  static void dispose() {
    _controller.close();
  }
}

class FlutterwaveCallbackResult {
  final String status;
  final String txRef;
  final String transactionId;

  const FlutterwaveCallbackResult({
    required this.status,
    required this.txRef,
    required this.transactionId,
  });

  bool get isSuccessful => status == 'successful';
}
