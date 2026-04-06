import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../auth/domain/auth_models.dart';
import '../../../shared/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State notifier
// ---------------------------------------------------------------------------

class EditProfileState {
  final bool isLoading;
  final String? error;
  final bool saved;

  const EditProfileState({
    this.isLoading = false,
    this.error,
    this.saved = false,
  });

  EditProfileState copyWith({
    bool? isLoading,
    String? error,
    bool? saved,
  }) =>
      EditProfileState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        saved: saved ?? this.saved,
      );
}

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  EditProfileNotifier() : super(const EditProfileState());

  Future<void> save({
    required String firstName,
    required String lastName,
    required String phone,
    required String dob,
    required String country,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 2)); // simulate API
    state = state.copyWith(isLoading: false, saved: true);
  }
}

final editProfileProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>(
        (ref) => EditProfileNotifier());

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _dob;
  late final TextEditingController _address;
  late final TextEditingController _country;
  late final bool _dobLocked;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).value?.user;
    _firstName = TextEditingController(text: user?.firstName ?? '');
    _lastName = TextEditingController(text: user?.lastName ?? '');
    _phone = TextEditingController(text: user?.phone ?? '');
    _dob = TextEditingController(text: user?.dateOfBirth ?? '');
    _address = TextEditingController(text: user?.address ?? '');
    _country = TextEditingController(text: '');
    // Lock DOB once it has been set — it cannot be changed after registration
    _dobLocked = (user?.dateOfBirth ?? '').isNotEmpty;
  }

  final List<String> _countries = [
    'United States', 'United Kingdom', 'Canada', 'Australia',
    'Germany', 'France', 'Netherlands', 'Spain', 'Italy',
    'Nigeria', 'Ghana', 'Kenya', 'South Africa', 'Uganda',
    'Tanzania', 'Ethiopia', 'Rwanda', 'Egypt', 'Morocco',
    'India', 'Pakistan', 'Bangladesh', 'Sri Lanka',
    'United Arab Emirates', 'Saudi Arabia', 'Qatar',
    'China', 'Japan', 'South Korea', 'Singapore', 'Malaysia',
    'Brazil', 'Mexico', 'Argentina', 'Colombia',
  ];
  String _selectedCountry = 'United States';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _dob.dispose();
    _address.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 8, 14),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dob.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(editProfileProvider.notifier).save(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim(),
          dob: _dob.text.trim(),
          country: _selectedCountry,
        );
    if (mounted) {
      // Sync updated fields back into authProvider
      final currentUser = ref.read(authProvider).value?.user;
      if (currentUser != null) {
        final updatedUser = UserModel(
          id: currentUser.id,
          email: currentUser.email,
          username: currentUser.username,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          phone: _phone.text.trim().isEmpty ? currentUser.phone : _phone.text.trim(),
          countryCode: currentUser.countryCode,
          role: currentUser.role,
          status: currentUser.status,
          twoFactorOn: currentUser.twoFactorOn,
          kycStatus: currentUser.kycStatus,
          kycLevel: currentUser.kycLevel,
          avatarUrl: currentUser.avatarUrl,
          dateOfBirth: _dob.text.trim().isNotEmpty ? _dob.text.trim() : currentUser.dateOfBirth,
          address: _address.text.trim().isNotEmpty ? _address.text.trim() : currentUser.address,
        );
        ref.read(authProvider.notifier).setUser(updatedUser);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: _teal,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                // ── Avatar ───────────────────────────────────────────────
                _buildAvatarHeader(),
                const SizedBox(height: 24),

                // ── First Name ───────────────────────────────────────────
                _buildLabel('First Name'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _firstName,
                  hint: 'Enter first name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Last Name ────────────────────────────────────────────
                _buildLabel('Last Name'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _lastName,
                  hint: 'Enter last name',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Phone ────────────────────────────────────────────────
                _buildLabel('Phone Number'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _phone,
                  hint: '+1 555 000 0000',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // ── Date of Birth ────────────────────────────────────────
                _buildLabel('Date of Birth'),
                const SizedBox(height: 6),
                if (_dobLocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: _teal, size: 20),
                        const SizedBox(width: 12),
                        Text(_dob.text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        const Spacer(),
                        const Icon(Icons.lock_outline, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        const Text('Locked', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: _buildField(
                        controller: _dob,
                        hint: 'YYYY-MM-DD',
                        icon: Icons.cake_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Address ──────────────────────────────────────────────
                _buildLabel('Home Address'),
                const SizedBox(height: 6),
                _buildField(
                  controller: _address,
                  hint: 'Enter your home address',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 16),

                // ── Country ──────────────────────────────────────────────
                _buildLabel('Country'),
                const SizedBox(height: 6),
                _buildCountryDropdown(),
                const SizedBox(height: 32),

                // ── Save button ──────────────────────────────────────────
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
                            'Save Changes',
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

  Widget _buildAvatarHeader() {
    final fn = _firstName.text;
    final ln = _lastName.text;
    final initials = '${fn.isNotEmpty ? fn[0] : '?'}${ln.isNotEmpty ? ln[0] : ''}'.toUpperCase();
    final user = ref.watch(authProvider).value?.user;
    final email = user?.email ?? '';
    final username = user?.username != null ? '@${user!.username}' : '';
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF0D6B5E), Color(0xFF14A88F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (email.isNotEmpty)
            Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          if (username.isNotEmpty)
            Text(username, style: const TextStyle(fontSize: 12, color: Color(0xFF0D6B5E), fontWeight: FontWeight.w600)),
        ],
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0D6B5E), size: 20),
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
          borderSide: const BorderSide(color: Color(0xFF0D6B5E), width: 1.8),
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

  Widget _buildCountryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF0D6B5E)),
          items: _countries
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedCountry = val);
            }
          },
        ),
      ),
    );
  }
}
