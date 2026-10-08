import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class ChangePictureDelete extends StatefulWidget{
  const ChangePictureDelete({super.key});

  @override
  State<ChangePictureDelete> createState() => _ChangePictureDeleteState();
}

class _ChangePictureDeleteState extends State<ChangePictureDelete> with SingleTickerProviderStateMixin{
  late Animation<Offset> _slideUp;
  late Animation<double> _fadeIn;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context){
     final loc = AppLocalizations.of(context)!;

     return Container(
       padding: const EdgeInsets.fromLTRB(10, 12, 10, 40),
       decoration: BoxDecoration(
         color: AppPalette.bg(Color(0xFFEF9A9A)).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(width: 1, color: AppPalette.border(Color(0xFFFFCDD2)).withOpacity(0.2)),
         boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFFEF9A9A)).withOpacity(0.9), blurRadius: 15, offset: Offset(0, -6))]
       ),
       child: FadeTransition(
         opacity: _fadeIn,
         child: SlideTransition(
           position: _slideUp,
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Container(width: 40, height: 4, decoration: BoxDecoration(color: AppPalette.bg(Color(0xFFE57373)).withOpacity(0.9), borderRadius: BorderRadius.circular(2))),
               const SizedBox(height: 24),
               Text(
                 "${loc.translate('remove_current_picture')}?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A))), textAlign: TextAlign.center,
               ),
               const SizedBox(height: 5),
               Text(
                 loc.translate('use_default_avatar'), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppPalette.fg(Color(0xFF0F172A)).withOpacity(0.8)),
               ),
               const SizedBox(height: 28),
               SizedBox(
                 width: double.infinity, height: 56,
                 child: ElevatedButton(
                   onPressed: () {
                     Navigator.pop(context); // Close confirm
                     Navigator.pop(context, 'remove'); // Return to caller
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppPalette.bg(Color(0xFFEF9A9A)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                     shadowColor: AppPalette.shadow(Color(0xFFB71C1C)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFFB71C1C)).withOpacity(0.2)),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                   ),
                   child: Text(loc.translate('remove_current_picture'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                 ),
               ),
               const SizedBox(height: 12),
               SizedBox(
                 width: double.infinity, height: 56,
                 child: ElevatedButton(
                   onPressed: () => Navigator.pop(context),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppPalette.bg(Color(0xFFEEEEEE)).withOpacity(0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6,
                     shadowColor: AppPalette.shadow(Color(0xFF212121)).withOpacity(0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF212121)).withOpacity(0.2)),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                   ),
                   child: Text(loc.translate('cancel'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                 ),
               ),
               const SizedBox(height: 22)
             ],
           ),
         ),
       ),
     );
   }
}