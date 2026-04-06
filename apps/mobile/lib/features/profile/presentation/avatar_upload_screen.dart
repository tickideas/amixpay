import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class AvatarUploadState {
  final bool isUploading;
  final bool uploadSuccess;
  final String? imagePath;
  const AvatarUploadState({
    this.isUploading = false,
    this.uploadSuccess = false,
    this.imagePath,
  });
  AvatarUploadState copyWith({bool? isUploading, bool? uploadSuccess, String? imagePath}) =>
      AvatarUploadState(
        isUploading: isUploading ?? this.isUploading,
        uploadSuccess: uploadSuccess ?? this.uploadSuccess,
        imagePath: imagePath ?? this.imagePath,
      );
}

class AvatarUploadNotifier extends StateNotifier<AvatarUploadState> {
  AvatarUploadNotifier() : super(const AvatarUploadState());

  final _picker = ImagePicker();

  Future<void> pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        state = state.copyWith(imagePath: picked.path);
      }
    } catch (_) {}
  }

  Future<void> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        state = state.copyWith(imagePath: picked.path);
      }
    } catch (_) {}
  }

  Future<void> upload() async {
    if (state.imagePath == null) return;
    state = state.copyWith(isUploading: true);
    // Simulate upload to server
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isUploading: false, uploadSuccess: true);
  }
}

final avatarUploadProvider = StateNotifierProvider.autoDispose<AvatarUploadNotifier, AvatarUploadState>(
  (ref) => AvatarUploadNotifier(),
);

class AvatarUploadScreen extends ConsumerWidget {
  const AvatarUploadScreen({super.key});

  static const _teal = Color(0xFF0D6B5E);
  static const _bg = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(avatarUploadProvider);
    final notifier = ref.read(avatarUploadProvider.notifier);

    ref.listen(avatarUploadProvider, (_, next) {
      if (next.uploadSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: _teal),
        );
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Update Photo'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () => notifier.pickFromGallery(),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _teal, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: const Color(0xFFE5E7EB),
                          backgroundImage: state.imagePath != null
                              ? FileImage(File(state.imagePath!))
                              : null,
                          child: state.imagePath == null
                              ? const Icon(Icons.person, size: 60, color: Color(0xFF9CA3AF))
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.imagePath != null) ...[
                const SizedBox(height: 12),
                const Center(
                  child: Text('Photo selected — tap Save to upload',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ),
              ],
              const SizedBox(height: 40),
              _PickButton(
                icon: Icons.camera_alt_outlined,
                label: 'Take Photo',
                onTap: notifier.pickFromCamera,
              ),
              const SizedBox(height: 14),
              _PickButton(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: notifier.pickFromGallery,
              ),
              const Spacer(),
              if (state.imagePath != null)
                ElevatedButton.icon(
                  onPressed: state.isUploading ? null : notifier.upload,
                  icon: state.isUploading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(state.isUploading ? 'Uploading...' : 'Save Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PickButton({required this.icon, required this.label, required this.onTap});
  static const _teal = Color(0xFF0D6B5E);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: _teal),
      label: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _teal)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: _teal, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.white,
      ),
    );
  }
}
