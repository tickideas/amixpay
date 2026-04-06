import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class SessionInfo {
  final String id;
  final String device;
  final String location;
  final String ip;
  final DateTime lastSeen;
  final bool isCurrentDevice;

  const SessionInfo({
    required this.id,
    required this.device,
    required this.location,
    required this.ip,
    required this.lastSeen,
    required this.isCurrentDevice,
  });
}

class LoginEntry {
  final String device;
  final String location;
  final DateTime timestamp;
  final bool success;

  const LoginEntry({
    required this.device,
    required this.location,
    required this.timestamp,
    required this.success,
  });
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SecuritySettingsState {
  final bool twoFaEnabled;
  final bool biometricEnabled;
  final List<SessionInfo> sessions;
  final List<LoginEntry> loginHistory;

  const SecuritySettingsState({
    this.twoFaEnabled = true,
    this.biometricEnabled = false,
    this.sessions = const [],
    this.loginHistory = const [],
  });

  SecuritySettingsState copyWith({
    bool? twoFaEnabled,
    bool? biometricEnabled,
    List<SessionInfo>? sessions,
    List<LoginEntry>? loginHistory,
  }) =>
      SecuritySettingsState(
        twoFaEnabled: twoFaEnabled ?? this.twoFaEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        sessions: sessions ?? this.sessions,
        loginHistory: loginHistory ?? this.loginHistory,
      );
}

class SecuritySettingsNotifier
    extends StateNotifier<SecuritySettingsState> {
  SecuritySettingsNotifier()
      : super(SecuritySettingsState(
          sessions: [
            SessionInfo(
              id: 's1',
              device: 'iPhone 15 Pro',
              location: 'New York, US',
              ip: '98.211.34.12',
              lastSeen: DateTime.now(),
              isCurrentDevice: true,
            ),
            SessionInfo(
              id: 's2',
              device: 'MacBook Pro',
              location: 'New York, US',
              ip: '98.211.34.12',
              lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
              isCurrentDevice: false,
            ),
            SessionInfo(
              id: 's3',
              device: 'Chrome – Windows',
              location: 'Austin, US',
              ip: '172.56.8.91',
              lastSeen: DateTime.now().subtract(const Duration(days: 2)),
              isCurrentDevice: false,
            ),
          ],
          loginHistory: [
            LoginEntry(
              device: 'iPhone 15 Pro',
              location: 'New York, US',
              timestamp: DateTime.now(),
              success: true,
            ),
            LoginEntry(
              device: 'MacBook Pro',
              location: 'New York, US',
              timestamp: DateTime.now().subtract(const Duration(hours: 5)),
              success: true,
            ),
            LoginEntry(
              device: 'Unknown Browser',
              location: 'Lagos, NG',
              timestamp: DateTime.now().subtract(const Duration(days: 1)),
              success: false,
            ),
          ],
        ));

  void toggle2FA(bool val) => state = state.copyWith(twoFaEnabled: val);
  void toggleBiometric(bool val) =>
      state = state.copyWith(biometricEnabled: val);
  void revokeSession(String id) {
    state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != id).toList());
  }
}

final securitySettingsProvider = StateNotifierProvider<
    SecuritySettingsNotifier, SecuritySettingsState>(
  (ref) => SecuritySettingsNotifier(),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(securitySettingsProvider);
    final notifier = ref.read(securitySettingsProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── 2FA ─────────────────────────────────────────────────────────
            _SectionHeader(title: '2-Factor Authentication'),
            _SettingsCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.security, color: _teal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Authenticator App',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(width: 8),
                                if (state.twoFaEnabled)
                                  _StatusChip(
                                      label: 'Active',
                                      color: Colors.green),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Use an authenticator app for secure login',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.twoFaEnabled,
                        onChanged: notifier.toggle2FA,
                        activeColor: _teal,
                      ),
                    ],
                  ),
                  if (!state.twoFaEnabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            context.push('/security/2fa-setup'),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Setup 2FA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(color: _teal),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Change Password ──────────────────────────────────────────────
            _SettingsCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline, color: _teal, size: 22),
                ),
                title: const Text('Change Password',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Update your account password',
                    style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => context.push('/security/change-password'),
              ),
            ),
            const SizedBox(height: 20),

            // ── Biometric ────────────────────────────────────────────────────
            _SectionHeader(title: 'Biometric Login'),
            _SettingsCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fingerprint, color: _teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Face ID / Fingerprint',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        SizedBox(height: 3),
                        Text(
                          'Use biometrics to unlock AmixPay',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.biometricEnabled,
                    onChanged: notifier.toggleBiometric,
                    activeColor: _teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Active Sessions ──────────────────────────────────────────────
            _SectionHeader(title: 'Active Sessions'),
            ...state.sessions.map((session) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SessionCard(
                    session: session,
                    onRevoke: () => notifier.revokeSession(session.id),
                  ),
                )),
            const SizedBox(height: 20),

            // ── Login History ────────────────────────────────────────────────
            _SectionHeader(title: 'Login History'),
            ...state.loginHistory.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LoginHistoryCard(entry: entry),
                )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
      );
}

// ---------------------------------------------------------------------------
// Settings card wrapper
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      );
}

// ---------------------------------------------------------------------------
// Session card
// ---------------------------------------------------------------------------

class _SessionCard extends StatelessWidget {
  final SessionInfo session;
  final VoidCallback onRevoke;

  const _SessionCard({required this.session, required this.onRevoke});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _deviceIcon(session.device),
                color: _teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(session.device,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      if (session.isCurrentDevice) ...[
                        const SizedBox(width: 6),
                        _StatusChip(
                            label: 'This device',
                            color: _teal),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.location} · ${session.ip}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    'Last active: ${fmt.format(session.lastSeen)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black38),
                  ),
                ],
              ),
            ),
            if (!session.isCurrentDevice)
              TextButton(
                onPressed: onRevoke,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red),
                child: const Text('Revoke',
                    style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  IconData _deviceIcon(String device) {
    final lower = device.toLowerCase();
    if (lower.contains('iphone') || lower.contains('android')) {
      return Icons.smartphone;
    } else if (lower.contains('mac') || lower.contains('windows')) {
      return Icons.laptop_mac;
    }
    return Icons.devices;
  }
}

// ---------------------------------------------------------------------------
// Login history card
// ---------------------------------------------------------------------------

class _LoginHistoryCard extends StatelessWidget {
  final LoginEntry entry;

  const _LoginHistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, h:mm a');
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              entry.success
                  ? Icons.check_circle_outline
                  : Icons.cancel_outlined,
              color: entry.success ? Colors.green : Colors.red,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.device,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(
                    entry.location,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(entry.timestamp),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.success ? 'Success' : 'Failed',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          entry.success ? Colors.green : Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
