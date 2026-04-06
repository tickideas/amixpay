import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with WidgetsBindingObserver {
  static const Color _teal = Color(0xFF0D6B5E);

  late MobileScannerController _scannerController;
  final _codeController = TextEditingController();

  bool _torchOn = false;
  bool _scanned = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
      _permissionChecked = true;
    });
    if (status.isGranted) {
      await _scannerController.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_permissionGranted) return;
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;
    _scanned = true;
    _scannerController.stop();
    context.push('/qr/confirm', extra: raw).then((_) {
      if (mounted) {
        setState(() => _scanned = false);
        _scannerController.start();
      }
    });
  }

  void _submitManual() {
    final raw = _codeController.text.trim();
    if (raw.isEmpty) return;
    context.push('/qr/confirm', extra: raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          if (_permissionGranted)
            IconButton(
              onPressed: () async {
                await _scannerController.toggleTorch();
                setState(() => _torchOn = !_torchOn);
              },
              icon: Icon(
                _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _torchOn ? Colors.yellow : Colors.white,
              ),
              tooltip: 'Toggle Flash',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_permissionChecked
          ? const Center(
              child: CircularProgressIndicator(color: _teal),
            )
          : !_permissionGranted
              ? _PermissionDeniedView(onRetry: _requestCameraPermission)
              : Stack(
                  children: [
                    // Live camera feed
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    ),

                    // Scanner frame overlay
                    CustomPaint(
                      painter: _OverlayPainter(
                        overlayColor: Colors.black.withValues(alpha: 0.55),
                        frameColor: _teal,
                        frameSize: 260,
                      ),
                      child: const SizedBox.expand(),
                    ),

                    // Instruction label
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 200),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Point camera at an AmixPAY QR code',
                              style:
                                  TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom manual entry panel
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.9),
                              Colors.transparent
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _codeController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Or paste amixpay:// link manually',
                                hintStyle: const TextStyle(
                                    color: Colors.white38, fontSize: 13),
                                filled: true,
                                fillColor:
                                    Colors.white.withValues(alpha: 0.08),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onSubmitted: (_) => _submitManual(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitManual,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _teal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Confirm',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Permission denied state ───────────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;
  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 20),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Please allow camera access to scan QR codes.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                // If permanently denied, open app settings
                final status = await Permission.camera.status;
                if (status.isPermanentlyDenied) {
                  await openAppSettings();
                } else {
                  onRetry();
                }
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6B5E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overlay painter ───────────────────────────────────────────────────────────

class _OverlayPainter extends CustomPainter {
  final Color overlayColor;
  final Color frameColor;
  final double frameSize;

  _OverlayPainter(
      {required this.overlayColor,
      required this.frameColor,
      required this.frameSize});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final half = frameSize / 2;
    final scanRect =
        Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half);

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    const cornerLen = 28.0;
    const cornerThickness = 4.0;
    final cp = Paint()
      ..color = frameColor
      ..strokeWidth = cornerThickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(scanRect.left + 4, scanRect.top),
        Offset(scanRect.left + cornerLen, scanRect.top), cp);
    canvas.drawLine(Offset(scanRect.left, scanRect.top + 4),
        Offset(scanRect.left, scanRect.top + cornerLen), cp);
    canvas.drawLine(Offset(scanRect.right - cornerLen, scanRect.top),
        Offset(scanRect.right - 4, scanRect.top), cp);
    canvas.drawLine(Offset(scanRect.right, scanRect.top + 4),
        Offset(scanRect.right, scanRect.top + cornerLen), cp);
    canvas.drawLine(Offset(scanRect.left + 4, scanRect.bottom),
        Offset(scanRect.left + cornerLen, scanRect.bottom), cp);
    canvas.drawLine(Offset(scanRect.left, scanRect.bottom - cornerLen),
        Offset(scanRect.left, scanRect.bottom - 4), cp);
    canvas.drawLine(Offset(scanRect.right - cornerLen, scanRect.bottom),
        Offset(scanRect.right - 4, scanRect.bottom), cp);
    canvas.drawLine(Offset(scanRect.right, scanRect.bottom - cornerLen),
        Offset(scanRect.right, scanRect.bottom - 4), cp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
