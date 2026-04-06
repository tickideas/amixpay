import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Password strength helper
// ---------------------------------------------------------------------------

enum PasswordStrength { empty, weak, medium, strong }

PasswordStrength _evaluate(String password) {
  if (password.isEmpty) return PasswordStrength.empty;
  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score <= 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ChangePasswordState {
  final bool isLoading;
  final String? error;
  final bool success;

  const ChangePasswordState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) =>
      ChangePasswordState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class ChangePasswordNotifier
    extends StateNotifier<ChangePasswordState> {
  ChangePasswordNotifier() : super(const ChangePasswordState());

  Future<void> submit({
    required String current,
    required String newPass,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 2));
    // Simulate wrong current password case
    if (current == 'wrongpassword') {
      state = state.copyWith(
          isLoading: false, error: 'Current password is incorrect.');
      return;
    }
    state = state.copyWith(isLoading: false, success: true);
  }
}

final changePasswordProvider = StateNotifierProvider.autoDispose<
    ChangePasswordNotifier, ChangePasswordState>(
  (ref) => ChangePasswordNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  PasswordStrength _strength = PasswordStrength.empty;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() {
      setState(() => _strength = _evaluate(_newCtrl.text));
    });
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(changePasswordProvider.notifier).submit(
          current: _currentCtrl.text,
          newPass: _newCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordProvider);

    ref.listen(changePasswordProvider, (_, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: _teal),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),

                // ── Current Password ──────────────────────────────────────
                _buildLabel('Current Password'),
                const SizedBox(height: 6),
                _buildPasswordField(
                  controller: _currentCtrl,
                  hint: 'Enter current password',
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 6),
                  Text(state.error!,
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12)),
                ],
                const SizedBox(height: 20),

                // ── New Password ──────────────────────────────────────────
                _buildLabel('New Password'),
                const SizedBox(height: 6),
                _buildPasswordField(
                  controller: _newCtrl,
                  hint: 'Enter new password',
                  obscure: _obscureNew,
                  onToggle: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _StrengthMeter(strength: _strength),
                const SizedBox(height: 20),

                // ── Confirm Password ──────────────────────────────────────
                _buildLabel('Confirm New Password'),
                const SizedBox(height: 6),
                _buildPasswordField(
                  controller: _confirmCtrl,
                  hint: 'Re-enter new password',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != _newCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Requirements hint ─────────────────────────────────────
                _RequirementHints(password: _newCtrl.text),
                const SizedBox(height: 32),

                // ── Submit ────────────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
      );

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            const Icon(Icons.lock_outline, color: Color(0xFF0D6B5E), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF0D6B5E), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Strength meter widget
// ---------------------------------------------------------------------------

class _StrengthMeter extends StatelessWidget {
  final PasswordStrength strength;

  const _StrengthMeter({required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();

    Color color;
    String label;
    int filledBars;

    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.red;
        label = 'Weak';
        filledBars = 1;
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        label = 'Medium';
        filledBars = 2;
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        label = 'Strong';
        filledBars = 3;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Row(
      children: [
        ...List.generate(3, (i) {
          return Expanded(
            child: Container(
              height: 5,
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < filledBars ? color : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Requirement hints
// ---------------------------------------------------------------------------

class _RequirementHints extends StatelessWidget {
  final String password;

  const _RequirementHints({required this.password});

  @override
  Widget build(BuildContext context) {
    final reqs = [
      _Req('At least 8 characters', password.length >= 8),
      _Req('One uppercase letter',
          RegExp(r'[A-Z]').hasMatch(password)),
      _Req('One number', RegExp(r'[0-9]').hasMatch(password)),
      _Req('One special character',
          RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)),
    ];

    return Column(
      children: reqs
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      r.met
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 14,
                      color: r.met ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(r.text,
                        style: TextStyle(
                            fontSize: 12,
                            color: r.met ? Colors.green : Colors.grey)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _Req {
  final String text;
  final bool met;

  const _Req(this.text, this.met);
}
