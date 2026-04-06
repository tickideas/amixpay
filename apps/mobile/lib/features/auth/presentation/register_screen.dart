import 'dart:io';
import 'package:country_picker/country_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/notification_service.dart';
import '../data/auth_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCountry = 'Detecting...';
  String _selectedCountryCode = '';
  String _selectedCountryDial = '';
  bool _setupPin = false;
  final _pinController = TextEditingController();
  final _pinConfirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Detect from IP (falls back to device locale then US if all fail)
    _detectLocaleByIp();
  }

  Future<void> _detectLocaleByIp() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ));

    String? detectedCode;

    // Try multiple IP geolocation APIs in order
    final apis = [
      () async {
        final r = await dio.get('https://ip-api.com/json');
        final d = r.data as Map<String, dynamic>?;
        if (d != null && d['status'] == 'success') return d['countryCode'] as String?;
        return null;
      },
      () async {
        final r = await dio.get('https://ipapi.co/json/');
        final d = r.data as Map<String, dynamic>?;
        if (d != null && d['error'] != true) return d['country_code'] as String?;
        return null;
      },
      () async {
        final r = await dio.get('https://ipinfo.io/json');
        final d = r.data as Map<String, dynamic>?;
        return d?['country'] as String?;
      },
    ];

    for (final api in apis) {
      try {
        detectedCode = await api();
        if (detectedCode != null && detectedCode.isNotEmpty) break;
      } catch (_) {
        continue;
      }
    }

    // Fall back to device locale if all APIs failed
    if ((detectedCode == null || detectedCode.isEmpty) && !kIsWeb) {
      try {
        final parts = Platform.localeName.split('_');
        if (parts.length >= 2) detectedCode = parts.last.toUpperCase();
      } catch (_) {}
    }

    final cc = detectedCode ?? 'US';
    final country = CountryParser.tryParseCountryCode(cc);
    if (mounted) {
      setState(() {
        if (country != null) {
          _selectedCountry = country.name;
          _selectedCountryCode = country.countryCode;
          _selectedCountryDial = '+${country.phoneCode}';
        } else {
          // Ultimate fallback
          _selectedCountry = 'United States';
          _selectedCountryCode = 'US';
          _selectedCountryDial = '+1';
        }
      });
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _pinController.dispose();
    _pinConfirmController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      searchAutofocus: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: AppColors.surface,
        textStyle: const TextStyle(color: AppColors.textPrimary),
        searchTextStyle: const TextStyle(color: AppColors.textPrimary),
        inputDecoration: InputDecoration(
          hintText: 'Search country',
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.textHint.withOpacity(0.3)),
          ),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
          _selectedCountryCode = country.countryCode;
          _selectedCountryDial = '+${country.phoneCode}';
        });
      },
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validate PIN if setup enabled
    if (_setupPin) {
      if (_pinController.text.length != 6) {
        setState(() { _isLoading = false; _errorMessage = 'PIN must be exactly 6 digits.'; });
        return;
      }
      if (_pinController.text != _pinConfirmController.text) {
        setState(() { _isLoading = false; _errorMessage = 'PINs do not match.'; });
        return;
      }
    }

    try {
      final phoneNum = _phoneController.text.trim();
      final phone = (_selectedCountryDial.isNotEmpty && phoneNum.isNotEmpty)
          ? '$_selectedCountryDial $phoneNum'
          : phoneNum;
      final result = await ref.read(authRepositoryProvider).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        phone: phone,
        countryCode: _selectedCountryCode.isNotEmpty ? _selectedCountryCode : 'US',
      );

      // Save PIN if user set one up
      if (_setupPin && _pinController.text.length == 6) {
        await BiometricService.setPin(_pinController.text);
      }

      if (!mounted) return;
      // Register FCM device token (fire-and-forget)
      final fcmToken = await NotificationService.getToken();
      if (fcmToken != null) {
        final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
        ref.read(authRepositoryProvider).registerDeviceToken(fcmToken, platform);
      }
      // Sync user into authProvider so home screen shows real name/initials immediately
      ref.read(authProvider.notifier).setUser(result.user);
      // Route to email verification unless already verified (demo mode sets emailVerified=false but
      // the user id starts with 'demo-' — skip verification for offline/demo sessions)
      final isDemoUser = result.user.id.startsWith('demo-');
      if (!result.user.emailVerified && !isDemoUser) {
        context.go('${AppRoutes.emailVerification}?email=${Uri.encodeComponent(result.user.email)}');
      } else {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e is ApiException ? e.message : 'Registration failed. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join AmixPay',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Create your free account in seconds',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First + Last name row
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _firstNameController,
                            hint: 'First name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            controller: _lastNameController,
                            hint: 'Last name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _usernameController,
                      hint: 'Username (e.g. john_doe)',
                      icon: Icons.alternate_email_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.length < 3) return 'Min 3 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildField(
                      controller: _emailController,
                      hint: 'Email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$')
                            .hasMatch(v.trim())) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Phone field with country prefix
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Mobile number',
                        prefixIcon: GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: _selectedCountryDial.isEmpty
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : Text(_selectedCountryDial, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 6) return 'Invalid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Country picker
                    GestureDetector(
                      onTap: _showCountryPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.flag_outlined,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$_selectedCountry ($_selectedCountryDial)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date of Birth
                    GestureDetector(
                      onTap: _pickDob,
                      child: AbsorbPointer(
                        child: _buildField(
                          controller: _dobController,
                          hint: 'Date of Birth (YYYY-MM-DD)',
                          icon: Icons.cake_outlined,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _buildField(
                      controller: _addressController,
                      hint: 'Home address',
                      icon: Icons.location_on_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Password
                    _buildField(
                      controller: _passwordController,
                      hint: 'Password (min. 8 characters)',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      action: TextInputAction.done,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 8) return 'Min 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Quick PIN setup (optional) ──────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _setupPin ? AppColors.primary : AppColors.border),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _setupPin,
                            onChanged: (v) => setState(() => _setupPin = v),
                            activeColor: AppColors.primary,
                            title: const Text('Set up Quick PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                            subtitle: const Text('Use a 6-digit PIN instead of password to log in', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 20),
                            ),
                          ),
                          if (_setupPin) ...[
                            const Divider(height: 0),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _pinController,
                                    obscureText: true,
                                    maxLength: 6,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8, color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: '• • • • • •',
                                      hintStyle: TextStyle(letterSpacing: 4, color: AppColors.textHint),
                                      labelText: 'Enter 6-digit PIN',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _pinConfirmController,
                                    obscureText: true,
                                    maxLength: 6,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8, color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: '• • • • • •',
                                      hintStyle: TextStyle(letterSpacing: 4, color: AppColors.textHint),
                                      labelText: 'Confirm PIN',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Terms & Privacy notice
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          children: [
                            const TextSpan(text: 'By creating an account you agree to our '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push(AppRoutes.termsOfService),
                                child: const Text('Terms of Service', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => context.push(AppRoutes.privacyPolicy),
                                child: const Text('Privacy Policy', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Create Account'),
                    ),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
