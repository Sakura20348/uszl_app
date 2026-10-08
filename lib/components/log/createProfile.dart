import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signlang/api/api_service.dart';
import 'package:signlang/components/profile/nameProfile/nameStore.dart';
import 'package:signlang/l10n/app_localizations.dart';
import 'package:signlang/main.dart';

import 'package:signlang/services/theme_service.dart';
class CreateProfile extends StatefulWidget{
  const CreateProfile({super.key});

  @override
  State<CreateProfile> createState() => _CreateProfile();
}

class _CreateProfile extends State<CreateProfile> {
  int _selectedIndex = -1;

  Future<void> _handleValidation() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) { setState(() => _showError = true); return; }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('first_name', name);
    await NameStorage.save(name);
    final phone = await NumberStorage.load() ?? '';
    await ApiService.updateProfile(name: name, lastName: '', phone: phone, image: '');
    await prefs.setBool('isLoggedIn', true);

    if (!mounted) return;
    FocusScope.of(context).unfocus(); // close the keyboard before leaving
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainWrapper(initialTab: 0)),
      (route) => false,
    );
  }

  final TextEditingController _nameController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ===== 1) back =====
                  if (Navigator.canPop(context))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.arrow_back_outlined),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 48),
                  // ===== 2) text =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.translate('create_profile'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 30)),
                      const SizedBox(height: 6),
                      Text(loc.translate('create_profile_sub'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400))
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ===== 3) name =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.translate('name'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF1A237E)))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        onChanged: (_) { if (_showError) setState(() => _showError = false); },
                        decoration: InputDecoration(
                          hintText: loc.translate('name_sub'), hintStyle: TextStyle(color: AppPalette.fg(Colors.grey[400]!), fontSize: 15),
                          filled: true, fillColor: AppPalette.bg(Color(0xFFF0F4FF)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _showError ? AppPalette.border(Colors.red) : Colors.transparent, width: 1.5)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppPalette.border(Color(0xFF4A7FD0)), width: 1.5)),
                        ),
                      ),
                      if (_showError) Padding(padding: const EdgeInsets.only(top: 6, left: 4), child: Text(loc.translate('please_name'), style: TextStyle(color: AppPalette.fg(Colors.red), fontSize: 13))),
                    ],
                  ),

                  const Spacer(),

                  // ===== 4) button =====
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _handleValidation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _nameController.text.trim().isEmpty ? AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1) : AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), foregroundColor: AppPalette.fg(Colors.white),
                        elevation: _selectedIndex == -1 ? 0 : 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                        side: BorderSide(width: 1, color: _selectedIndex == -1 ? AppPalette.border(Colors.black12) : AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2))
                      ),
                      child: Text(loc.translate('continue'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _selectedIndex == -1 ? AppPalette.fg(Colors.blue[700]!) : AppPalette.fg(Colors.blue[900]!))),
                    ),
                  ),
                ],
              ),
            )
          ),
        ),
      ),
    );
  }
}