import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signlang/components/profile/group/deleteProfile/changePictureDelete.dart';
import '../../../../l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class ChangePicture extends StatelessWidget {
  final File? currentImage;

  const ChangePicture({super.key, this.currentImage});

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(source: source);
    if (picked != null && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, File(picked.path));
    }
  }

  void _showConfirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePictureDelete(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppPalette.bg(Color(0xFF80DEEA)).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFB2EBF2)).withOpacity(0.2)),
        boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF80DEEA)).withOpacity(0.9), blurRadius: 15, offset: Offset(0, -6))]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 50, height: 4, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF4DD0E1)).withOpacity(0.9), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: AppPalette.bg(Colors.blueGrey).withOpacity(0.4), border: Border.all(color: AppPalette.border(Colors.white))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: currentImage != null && currentImage!.path.isNotEmpty ? Image.file(currentImage!, width: 64, height: 64, fit: BoxFit.cover) : Center(child: Icon(Icons.person_outline, size: 25, color: AppPalette.fg(Colors.white))),
            ),
          ),
          const SizedBox(height: 16),
          Text(loc.translate('update_profile_picture'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))), const SizedBox(height: 8),
          Text(loc.translate('change_language_sub'), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.7))),
          const SizedBox(height: 32),
          // Options
          _buildOption(context, icon: Icons.camera_alt_outlined, title: loc.translate('take_via_camera'), subtitle: loc.translate('take_new_photo'), onTap: () => _pickImage(context, ImageSource.camera)),
          const SizedBox(height: 12),
          _buildOption(context, icon: Icons.image_outlined, title: loc.translate('choose_from_gallery'), subtitle: loc.translate('choose_existing_photo'), onTap: () => _pickImage(context, ImageSource.gallery)),
          const SizedBox(height: 12),
          _buildOption(
            context, icon: Icons.delete_outline, title: loc.translate('remove_current_picture'), subtitle: loc.translate('use_default_avatar'),
            iconColor: AppPalette.fg(Colors.red), isColor: AppPalette.bg(Color(0xFFEF5350)).withOpacity(0.9), onTap: () => _showConfirmDelete(context),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFF212121)).withOpacity(0.9),
                side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF212121)).withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor, Color? isColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withOpacity(0.4), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: isColor ?? AppPalette.shadow(Color(0xFF29B6F6)).withOpacity(0.9), blurRadius: 15)]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor ?? AppPalette.fg(Color(0xFF4A7FD0)), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF1E293B)))),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: AppPalette.fg(Color(0xFF1E293B)).withOpacity(0.9))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
              child: Center(child: Icon(Icons.keyboard_arrow_right_outlined, size: 24, color: AppPalette.fg(Color(0xFF0D47A1)).withOpacity(0.9))),
            ),
          ],
        ),
      ),
    );
  }
}
