import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TwoFaSetupState {
  final int step; // 1-4
  final String secret;
  final String otpAuthUrl;
  final String verificationCode;
  final bool isVerifying;
  final String? verifyError;
  final List<String> backupCodes;

  const TwoFaSetupState({
    this.step = 1,
    this.secret = 'JBSWY3DPEHPK3PXP',
    this.otpAuthUrl =
        'otpauth://totp/AmixPay:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=AmixPay',
    this.verificationCode = '',
    this.isVerifying = false,
    this.verifyError,
    this.backupCodes = const [],
  });

  TwoFaSetupState copyWith({
    int? step,
    String? verificationCode,
    bool? isVerifying,
    String? verifyError,
    List<String>? backupCodes,
  }) =>
      TwoFaSetupState(
        step: step ?? this.step,
        secret: secret,
        otpAuthUrl: otpAuthUrl,
        verificationCode: verificationCode ?? this.verificationCode,
        isVerifying: isVerifying ?? this.isVerifying,
        verifyError: verifyError,
        backupCodes: backupCodes ?? this.backupCodes,
      );
}

class TwoFaSetupNotifier extends StateNotifier<TwoFaSetupState> {
  TwoFaSetupNotifier() : super(const TwoFaSetupState());

  void nextStep() => state = state.copyWith(step: state.step + 1);

  void setCode(String code) =>
      state = state.copyWith(verificationCode: code, verifyError: null);

  Future<void> verify() async {
    if (state.verificationCode.length != 6) {
      state = state.copyWith(verifyError: 'Please enter a 6-digit code');
      return;
    }
    state = state.copyWith(isVerifying: true, verifyError: null);
    await Future.delayed(const Duration(seconds: 2));
    // Stub: accept any 6-digit code
    final codes = List.generate(
        10,
        (i) =>
            '${(100000 + i * 91737).toString().substring(0, 4)}-'
            '${(100000 + i * 13579).toString().substring(0, 4)}');
    state = state.copyWith(
        isVerifying: false, step: 4, backupCodes: codes);
  }
}

final twoFaSetupProvider =
    StateNotifierProvider.autoDispose<TwoFaSetupNotifier, TwoFaSetupState>(
        (ref) => TwoFaSetupNotifier());

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TwoFactorSetupScreen extends ConsumerWidget {
  const TwoFactorSetupScreen({super.key});

  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(twoFaSetupProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Setup 2FA'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Step indicator ───────────────────────────────────────────
            _StepIndicator(currentStep: state.step),

            // ── Step content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildStep(context, ref, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
      BuildContext context, WidgetRef ref, TwoFaSetupState state) {
    final notifier = ref.read(twoFaSetupProvider.notifier);
    switch (state.step) {
      case 1:
        return _Step1(onNext: notifier.nextStep);
      case 2:
        return _Step2(state: state, onNext: notifier.nextStep);
      case 3:
        return _Step3(state: state, notifier: notifier);
      case 4:
        return _Step4(state: state);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Step indicator
// ---------------------------------------------------------------------------

class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(4, (i) {
          final step = i + 1;
          final isActive = step == currentStep;
          final isDone = step < currentStep;
          return Expanded(
            child: Row(
              children: [
                _StepDot(step: step, isActive: isActive, isDone: isDone),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? _teal : const Color(0xFFE0E0E0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final bool isActive;
  final bool isDone;

  const _StepDot(
      {required this.step, required this.isActive, required this.isDone});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive || isDone ? _teal : const Color(0xFFE0E0E0),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '$step',
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 – Instructions
// ---------------------------------------------------------------------------

class _Step1 extends StatelessWidget {
  final VoidCallback onNext;

  const _Step1({required this.onNext});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.security, size: 64, color: _teal),
        const SizedBox(height: 20),
        const Text(
          'Set Up Two-Factor Authentication',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'Protect your account with an extra layer of security. '
          'You\'ll need an authenticator app to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 32),
        const Text(
          'Step 1 – Download an Authenticator App',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 12),
        ...[
          _AppOption(
            icon: Icons.grid_view_rounded,
            name: 'Google Authenticator',
            desc: 'Available on iOS & Android',
            color: Colors.blue,
          ),
          _AppOption(
            icon: Icons.shield,
            name: 'Authy',
            desc: 'Multi-device support',
            color: Colors.red,
          ),
          _AppOption(
            icon: Icons.lock,
            name: '1Password',
            desc: 'Built-in TOTP support',
            color: Colors.orange,
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('I have an app – Continue',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

class _AppOption extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;
  final Color color;

  const _AppOption(
      {required this.icon,
      required this.name,
      required this.desc,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(desc,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 – QR Code
// ---------------------------------------------------------------------------

class _Step2 extends StatelessWidget {
  final TwoFaSetupState state;
  final VoidCallback onNext;

  const _Step2({required this.state, required this.onNext});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Scan QR Code',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Open your authenticator app and scan this QR code, '
          'or enter the secret key manually.',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 28),

        // QR code
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: QrImageView(
              data: state.otpAuthUrl,
              version: QrVersions.auto,
              size: 200,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0D6B5E),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0D6B5E),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Manual secret
        const Text(
          'Or enter manually:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  state.secret,
                  style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Color(0xFF0D6B5E)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Color(0xFF0D6B5E)),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: state.secret));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Secret copied!')),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('I\'ve scanned the code',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 – Verify code
// ---------------------------------------------------------------------------

class _Step3 extends StatelessWidget {
  final TwoFaSetupState state;
  final TwoFaSetupNotifier notifier;

  const _Step3({required this.state, required this.notifier});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.dialpad, size: 56, color: _teal),
        const SizedBox(height: 20),
        const Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter the 6-digit code from your authenticator app '
          'to confirm setup.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 32),

        // 6-digit code input
        TextField(
          onChanged: notifier.setCode,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 10),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: const TextStyle(color: Colors.black26, letterSpacing: 10),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _teal, width: 2),
            ),
            errorText: state.verifyError,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: state.isVerifying ? null : notifier.verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: state.isVerifying
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Verify & Enable',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 – Backup codes
// ---------------------------------------------------------------------------

class _Step4 extends StatelessWidget {
  final TwoFaSetupState state;

  const _Step4({required this.state});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    final allCodes = state.backupCodes.join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, size: 56, color: Colors.green),
        const SizedBox(height: 12),
        const Text(
          '2FA Enabled!',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.green),
        ),
        const SizedBox(height: 8),
        const Text(
          'Save these backup codes. You can use them to access your '
          'account if you lose your authenticator app.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Backup codes grid
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Backup Codes',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: allCodes));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Backup codes copied!'),
                            backgroundColor: _teal),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: _teal),
                    label: const Text('Copy All',
                        style: TextStyle(color: _teal, fontSize: 12)),
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ),
              const Divider(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 6,
                ),
                itemCount: state.backupCodes.length,
                itemBuilder: (_, i) => Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.backupCodes[i],
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D6B5E)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Store these codes in a safe place. Each code can only be used once.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Done',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
