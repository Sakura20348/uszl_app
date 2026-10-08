import 'dart:io';
import 'package:signlang/services/app_loading.dart';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:signlang/components/profile/group/personal/changeLink.dart';
import 'package:signlang/components/profile/group/personal/changeName.dart';
import 'package:signlang/components/profile/group/personal/changePhone.dart';
import 'package:signlang/components/profile/group/personal/changePicture.dart';
import 'package:signlang/components/profile/group/deleteProfile/deleteAccount.dart';
import 'package:signlang/components/profile/nameProfile/nameProfileSheet.dart';
import 'package:signlang/components/profile/skeleton/skeleton.dart';

import '../../../../api/api_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../nameProfile/nameStore.dart';

import 'package:signlang/services/theme_service.dart';
class PersonalInformation extends StatefulWidget{
  const PersonalInformation({super.key});

  @override
  State<PersonalInformation> createState() => _PersonalInformationState();
}

class _PersonalInformationState extends State<PersonalInformation>{
  bool _isLoading = true;
  File? _profileImage;
  String _initialName = '';
  String _initialLastName = '';
  String _initialProfileImage = '';
  String _phoneNumber = '';
  String _initialPhone = '';
  bool _isAppleConnected = false;
  bool _isGoogleConnected = false;

  final TextEditingController nameController = TextEditingController(text: '');
  final TextEditingController lastNameController = TextEditingController(text: '');

  bool get isChanged {
    final currentImagePath = _profileImage?.path ?? '';
    return nameController.text.trim() != _initialName.trim() || lastNameController.text.trim() != _initialLastName.trim() ||
      currentImagePath.trim() != _initialProfileImage.trim() || _phoneNumber.trim() != _initialPhone.trim();
  }

// =======================================================================
  @override
  void initState(){ super.initState(); _initializeData(); }

  @override
  void dispose() {
    nameController.removeListener(_onChanged); lastNameController.removeListener(_onChanged);
    nameController.dispose(); lastNameController.dispose();
    super.dispose();
  }

// =======================================================================
  Future<void> _loadImage() async {
    final path = await ImageStorage.load();
    if (mounted) { setState(() { _profileImage = (path != null && path.isNotEmpty) ? File(path) : null; _initialProfileImage = path ?? ''; }); }
  }

  Future<void> _initializeData() async {
    await _loadImage();
    await _loadUserData();

    nameController.addListener(_onChanged);
    lastNameController.addListener(_onChanged);

    await Future.wait([ AppLoading.ready(), ]);
    if (!mounted) return;
    setState(() { _isLoading = false; });
  }

  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }

  Future<void> _loadUserData() async {
    final savedName = await NameStorage.load();
    final savedLastName = await LastNameStorage.load();
    final savedPhone = await NumberStorage.load();
    final linkStatus = await LinkStorage.load();

    if (!mounted) return;
    setState(() {
      nameController.text = savedName ?? ''; lastNameController.text = savedLastName ?? '';
      _phoneNumber = savedPhone ?? ''; _initialPhone = _phoneNumber;
      _initialName = nameController.text; _initialLastName = lastNameController.text;
      _initialProfileImage = _profileImage?.path ?? '';
      _isAppleConnected = linkStatus['apple'];
      _isGoogleConnected = linkStatus['google'];
    });
  }

  Future<bool> _saveData() async {
    final imagePath = _profileImage?.path ?? '';

    // 1. Save locally to Shared Preferences
    await ImageStorage.save(imagePath);
    await NameStorage.save(nameController.text);
    await LastNameStorage.save(lastNameController.text);
    await NumberStorage.save(_phoneNumber);

    // 2. Send to the server in the background (sent on the next app start if it can't be reached now)
    ApiService.updateProfile(name: nameController.text, lastName: lastNameController.text, phone: _phoneNumber, image: imagePath);

    // Saved on the phone: the profile and home screens show the new name right away
    const success = true;
    if (mounted) {
      setState(() {
        _initialName = nameController.text;
        _initialLastName = lastNameController.text;
        _initialProfileImage = imagePath;
        _initialPhone = _phoneNumber;
      });
    }
    return success;
  }

// =======================================================================
  Future<void> _showChangePictureSheet() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangePicture(currentImage: _profileImage),
    );

    if (result == 'remove') { setState(() => _profileImage = null); } else if (result is File) { setState(() => _profileImage = result); }
  }

  Future<void> _showChangeNameSheet() async {
    final String fullName = "${nameController.text} ${lastNameController.text}".trim();
    final result = await showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ChangeName(initialName: fullName),
    );

    if (result != null && result.isNotEmpty) {
      final parts = result.split(' ');
      setState(() {
        nameController.text = parts[0];
        lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      });
    }
  }

  Future<void> _showChangePhoneSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ChangePhone(initialPhone: _phoneNumber),
    );

    if (result != null && result.isNotEmpty) { setState(() { _phoneNumber = result; }); }
  }

  Future<void> _showChangeLinkSheet() async {
    await showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => const ChangeLink(),
    );
    final linkStatus = await LinkStorage.load();
    if (mounted) { setState(() { _isAppleConnected = linkStatus['apple']; _isGoogleConnected = linkStatus['google']; }); }
  }

// =======================================================================
  void _onChanged() {if (mounted) {setState(() {});}}

  void _showDeleteAccount() async {
    final deleted = await showModalBottomSheet<int>(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: DeleteAccount())
    );
    if (deleted != null && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String name = nameController.text; final String lastName = lastNameController.text;
    const String ImageInitial = 'web/icons/initial.png'; const String ImageCode = 'web/icons/code.png'; const String ImageEdit = 'web/icons/edit.png';
    const int level = 2;
    const ImageDelete = 'web/icons/trash.png';

    final allProfileItem = AllProfileData(
      context: context,
      name: '$name $lastName',
      phone: _phoneNumber,
      isAppleConnected: _isAppleConnected,
      isGoogleConnected: _isGoogleConnected,
    ).allProfileItems;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter(child: Shimmer.fromColors(baseColor: AppPalette.bg(Colors.grey[200]!), highlightColor: AppPalette.bg(Color(0xFF42A5F5)).withValues(alpha: 0.2), child: PersonalInformationSkeleton.buildSkeleton()))
                else ... [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                  child: const Icon(Icons.arrow_back_outlined),
                                )
                              ),
                              if (isChanged)
                                SizedBox(
                                  width: 100, height: 46,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final success = await _saveData();
                                      if (success && context.mounted) {
                                        Navigator.pop(context, true);
                                      } else if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile'))); }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppPalette.bg(Color(0xFFC8E6C9)).withOpacity(0.4), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                      shadowColor: AppPalette.shadow(Color(0xFF1B5E20)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1B5E20)).withOpacity(0.2)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    ),
                                    child: Text(AppLocalizations.of(context)!.translate('save'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity, padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppPalette.bg(Colors.white).withOpacity(0.4), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withOpacity(0.9), blurRadius: 15)]
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 96, height: 96,
                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: AppPalette.bg(Colors.grey).withOpacity(0.3), border: Border.all(width: 1, color: AppPalette.border(Colors.white))),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: _profileImage != null && _profileImage!.path.isNotEmpty ? Image.file(_profileImage!, width: 96, height: 96, fit: BoxFit.cover) : Center(child: Icon(Icons.person_outline, color: AppPalette.fg(Colors.white54), size: 40)),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0, right: 0,
                                        child: GestureDetector(
                                          onTap: _showChangePictureSheet,
                                          child: Container(
                                            width: 30, height: 30, padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), shape: BoxShape.circle, border: Border.all(color: AppPalette.border(Color(0xFF42A5F5)), width: 2)),
                                            child: Image.asset(ImageEdit),
                                          ),
                                        )
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('$name $lastName', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 2), decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFC5E1A5)).withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFF1F8E9)))),
                                        child: Row(
                                          children: [
                                            Image.asset(ImageInitial, width: 16, height: 16, color: AppPalette.fg(Color(0xFF1B5E20)).withOpacity(0.8)),
                                            const SizedBox(width: 4),
                                            Text(AppLocalizations.of(context)!.translate('initial'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppPalette.fg(Color(0xFF1B5E20)).withOpacity(0.8)))
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                                        decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFFFF59D)).withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFFFFDE7)))),
                                        child: Row(
                                          children: [
                                            Image.asset(ImageCode, width: 16, height: 16, color: AppPalette.fg(Color(0xFFF57F17)).withOpacity(0.9)),
                                            const SizedBox(),
                                            Text('$level ${AppLocalizations.of(context)!.translate('level')}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppPalette.fg(Color(0xFFF57F17)).withOpacity(0.9)))
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(AppLocalizations.of(context)!.translate('profile'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24))
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(children: List.generate(allProfileItem.length, (index) => _buildAllProfile(allProfileItem[index]))),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: _showDeleteAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.bg(Color(0xFFFFCDD2)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                                  shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withOpacity(0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(ImageDelete, width: 24, height: 24,),
                                    const SizedBox(width: 4),
                                    Text(AppLocalizations.of(context)!.translate('delete_account'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  )
                ]
              ],
            )
          )
        ),
      ),
    );
  }

  Widget _buildAllProfile(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        switch (item['id']) {
          case '0': _showChangeNameSheet(); break;
          case '1': _showChangePhoneSheet(); break;
          case '2': _showChangeLinkSheet(); break;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppPalette.bg(Colors.white).withOpacity(0.4), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
          borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF29B6F6)).withOpacity(0.9), blurRadius: 15)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), borderRadius: BorderRadius.circular(18)),
              child: Image.asset(item['image'], width: 22, height: 22, color: AppPalette.fg(Colors.blue[600]!), errorBuilder: (_, __, ___) => Icon(Icons.account_circle_outlined, size: 40, color: AppPalette.fg(Colors.blue))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['titleKey'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(item['subKey'] ?? '', style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.grey[700]!)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // trailing chevron (optional, like your other rows)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE3F2FD)).withOpacity(0.6), border: Border.all(width: 1, color: AppPalette.border(Colors.white)), shape: BoxShape.circle),
              child: Icon(Icons.keyboard_arrow_right_outlined, size: 22, color: AppPalette.fg(Color(0xFF0D47A1)).withOpacity(0.9)),
            ),
          ],
        ),
      ),
    );
  }
}