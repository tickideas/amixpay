import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/deep_link_service.dart';
import '../services/notification_service.dart';

/// Wraps the navigator and listens to:
///   - DeepLinkService (amixpay:// or https://amixpay.com/ links)
///   - NotificationService (FCM push notification tap routes)
///
/// Place this widget at the root of your MaterialApp.router so it has
/// access to GoRouter via context.
class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  final _subs = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();

    // Deep links (Flutterwave callback + QR links)
    _subs.add(DeepLinkService.stream.listen(_handleUri));

    // Push notification taps
    _subs.add(NotificationService.routeStream.listen(_handleRoute));
  }

  void _handleUri(Uri uri) {
    // Flutterwave payment callback
    final flw = DeepLinkService.parseFlutterwaveCallback(uri);
    if (flw != null) {
      if (flw.isSuccessful) {
        // Navigate to send-success screen reusing the route
        context.go('/payments/success', extra: {
          'recipient': 'Flutterwave',
          'recipientHandle': flw.txRef,
          'amount': 0.0,
          'currency': '',
          'fee': 0.0,
          'note': 'tx: ${flw.transactionId}',
        });
      }
      return;
    }

    // Generic path-based routing for https://amixpay.com/<path>
    if (uri.host == 'amixpay.com' || uri.host == 'amixpay') {
      final path = uri.path;
      if (path.isNotEmpty && path != '/') {
        context.go(path);
      }
    }
  }

  void _handleRoute(String route) {
    if (route.isNotEmpty) {
      context.go(route);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
