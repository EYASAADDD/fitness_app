import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_image_widget.dart';

class ProfilePhotoPickerWidget extends StatefulWidget {
  final String? photoPath;
  final ValueChanged<String?> onPhotoSelected;

  const ProfilePhotoPickerWidget({
    super.key,
    required this.photoPath,
    required this.onPhotoSelected,
  });

  @override
  State<ProfilePhotoPickerWidget> createState() =>
      _ProfilePhotoPickerWidgetState();
}

class _ProfilePhotoPickerWidgetState extends State<ProfilePhotoPickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return;
      widget.onPhotoSelected('file://${file.path}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de sélectionner une image.')),
      );
    }
  }

  Future<void> _openPickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (widget.photoPath != null && widget.photoPath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Retirer la photo'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPhotoSelected(null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.photoPath != null && widget.photoPath!.isNotEmpty;

    return Center(
      child: GestureDetector(
        onTap: _openPickerSheet,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bgSecondary,
                border: Border.all(
                  color: AppTheme.primaryBlue.withAlpha(77),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withAlpha(31),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: hasPhoto
                  ? ClipOval(
                      child: CustomImageWidget(
                        imageUrl: widget.photoPath,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorWidget: _buildDefaultAvatar(),
                      ),
                    )
                  : _buildDefaultAvatar(),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person_rounded,
      color: AppTheme.primaryBlue,
      size: 48,
    );
  }
}
