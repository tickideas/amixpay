import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';

// ---------------------------------------------------------------------------
// Models & enums
// ---------------------------------------------------------------------------

enum KycDocStatus { notSubmitted, pending, approved, rejected }

class KycDocument {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final KycDocStatus status;

  const KycDocument({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
  });
}

// ---------------------------------------------------------------------------
// Provider (stub)
// ---------------------------------------------------------------------------

final kycProvider = StateNotifierProvider<KycNotifier, KycState>(
    (ref) => KycNotifier());

class KycState {
  final int currentLevel;
  final List<KycDocument> documents;
  final bool isUploading;

  const KycState({
    this.currentLevel = 1,
    this.documents = const [],
    this.isUploading = false,
  });

  KycState copyWith({
    int? currentLevel,
    List<KycDocument>? documents,
    bool? isUploading,
  }) =>
      KycState(
        currentLevel: currentLevel ?? this.currentLevel,
        documents: documents ?? this.documents,
        isUploading: isUploading ?? this.isUploading,
      );
}

class KycNotifier extends StateNotifier<KycState> {
  KycNotifier()
      : super(const KycState(
          currentLevel: 1,
          documents: [
            KycDocument(
              id: 'national_id',
              name: 'National ID – Front',
              description: 'Clear photo of the front of your government ID',
              icon: Icons.credit_card_outlined,
              status: KycDocStatus.notSubmitted,
            ),
            KycDocument(
              id: 'passport',
              name: 'Passport',
              description: 'Photo page of your valid passport',
              icon: Icons.book_outlined,
              status: KycDocStatus.notSubmitted,
            ),
            KycDocument(
              id: 'selfie',
              name: 'Selfie with ID',
              description: 'Hold your ID next to your face',
              icon: Icons.face_outlined,
              status: KycDocStatus.notSubmitted,
            ),
          ],
        ));

  /// Pick an image from the camera or gallery and upload to the backend.
  Future<String?> uploadDocument(String docId, {bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return null; // user cancelled

    state = state.copyWith(isUploading: true);
    try {
      final file = File(picked.path);
      final filename = '${docId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final formData = FormData.fromMap({
        'document_type': docId,
        'file': await MultipartFile.fromFile(file.path, filename: filename),
      });

      final token = await SecureStorage.getAccessToken();
      final dio = Dio(BaseOptions(
        baseUrl: ApiClient.instance.options.baseUrl,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      await dio.post('/users/kyc/documents', data: formData);

      // Mark this document as pending in local state
      final updated = state.documents.map((d) {
        if (d.id == docId) {
          return KycDocument(
            id: d.id,
            name: d.name,
            description: d.description,
            icon: d.icon,
            status: KycDocStatus.pending,
          );
        }
        return d;
      }).toList();
      state = state.copyWith(documents: updated, isUploading: false);
      return null; // success
    } catch (e) {
      state = state.copyWith(isUploading: false);
      return e is DioException
          ? (e.response?.data?['error']?['message'] ?? 'Upload failed. Please try again.')
          : 'Upload failed. Please try again.';
    }
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('KYC Verification'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Level progress card ─────────────────────────────────────
              _LevelProgressCard(currentLevel: state.currentLevel),
              const SizedBox(height: 20),

              // ── Info banner ─────────────────────────────────────────────
              _InfoBanner(),
              const SizedBox(height: 20),

              // ── Document cards ──────────────────────────────────────────
              const Text(
                'Required Documents',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...state.documents.map(
                (doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DocumentCard(
                    doc: doc,
                    isUploading: state.isUploading,
                    onUpload: () async {
                      // Show camera vs gallery picker
                      final source = await showModalBottomSheet<bool>(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
                              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.camera_alt_outlined, color: _teal),
                                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () => Navigator.pop(context, true),
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library_outlined, color: _teal),
                                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                                onTap: () => Navigator.pop(context, false),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                      if (source == null) return;
                      final error = await ref.read(kycProvider.notifier)
                          .uploadDocument(doc.id, fromCamera: source);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error), backgroundColor: Colors.red),
                        );
                      } else if (error == null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Document submitted for review'), backgroundColor: _teal),
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Level benefits ──────────────────────────────────────────
              _LevelBenefitsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level progress card
// ---------------------------------------------------------------------------

class _LevelProgressCard extends StatelessWidget {
  final int currentLevel;

  const _LevelProgressCard({required this.currentLevel});

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D6B5E), Color(0xFF14A98C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KYC Level',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Level $currentLevel of 3',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          // Progress row
          Row(
            children: List.generate(4, (i) {
              final isComplete = i <= currentLevel;
              return Expanded(
                child: Row(
                  children: [
                    _LevelDot(level: i, isComplete: isComplete),
                    if (i < 3)
                      Expanded(
                        child: Container(
                          height: 3,
                          color: i < currentLevel
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('L0', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('L1', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('L2', style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('L3', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelDot extends StatelessWidget {
  final int level;
  final bool isComplete;

  const _LevelDot({required this.level, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isComplete ? Colors.white : Colors.white24,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isComplete
            ? Icon(Icons.check,
                size: 15, color: const Color(0xFF0D6B5E))
            : Text(
                '$level',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info banner
// ---------------------------------------------------------------------------

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Level 2 KYC unlocks \$10,000 daily limit',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.green),
                ),
                SizedBox(height: 2),
                Text(
                  'Level 3 unlocks unlimited transactions & merchant features.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document card
// ---------------------------------------------------------------------------

class _DocumentCard extends StatelessWidget {
  final KycDocument doc;
  final bool isUploading;
  final Future<void> Function() onUpload;

  const _DocumentCard({
    required this.doc,
    required this.isUploading,
    required this.onUpload,
  });

  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(doc.icon, color: _teal, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(doc.description,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 8),
                  _StatusBadge(status: doc.status),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (doc.status != KycDocStatus.approved)
              SizedBox(
                width: 80,
                height: 36,
                child: ElevatedButton(
                  onPressed: isUploading ? null : onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isUploading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Upload',
                          style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final KycDocStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case KycDocStatus.approved:
        bg = const Color(0xFFE8F5E9);
        fg = Colors.green.shade700;
        label = 'Approved';
        icon = Icons.check_circle_outline;
        break;
      case KycDocStatus.pending:
        bg = const Color(0xFFFFF3E0);
        fg = Colors.orange.shade700;
        label = 'Pending Review';
        icon = Icons.hourglass_empty;
        break;
      case KycDocStatus.rejected:
        bg = const Color(0xFFFFEBEE);
        fg = Colors.red.shade700;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case KycDocStatus.notSubmitted:
        bg = const Color(0xFFF5F5F5);
        fg = Colors.grey.shade600;
        label = 'Not Submitted';
        icon = Icons.upload_file_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level benefits card
// ---------------------------------------------------------------------------

class _LevelBenefitsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final levels = [
      _LevelBenefit(
          level: 0,
          limit: '\$500/day',
          features: ['Basic wallet', 'P2P transfers']),
      _LevelBenefit(
          level: 1,
          limit: '\$2,000/day',
          features: ['Bill splits', 'QR payments']),
      _LevelBenefit(
          level: 2,
          limit: '\$10,000/day',
          features: ['Merchant tools', 'Withdrawals']),
      _LevelBenefit(
          level: 3,
          limit: 'Unlimited',
          features: ['All features', 'API access']),
    ];

    return Card(
      elevation: 0,
      color: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Level Benefits',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ...levels.map((l) => _BenefitRow(benefit: l)),
          ],
        ),
      ),
    );
  }
}

class _LevelBenefit {
  final int level;
  final String limit;
  final List<String> features;

  const _LevelBenefit(
      {required this.level, required this.limit, required this.features});
}

class _BenefitRow extends StatelessWidget {
  final _LevelBenefit benefit;

  const _BenefitRow({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF0D6B5E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('L${benefit.level}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(benefit.limit,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(benefit.features.join(' · '),
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
