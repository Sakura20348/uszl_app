import 'package:flutter/material.dart';
import 'package:signlang/components/log/nameLog/nameLogItem.dart';
import 'package:signlang/components/log/setUp.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class WellDone extends StatefulWidget{
  const WellDone({super.key});

  @override
  State<WellDone> createState() => _WellDoneState();
}

class _WellDoneState extends State<WellDone> {
  void _handLeValidation() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SetUp()));
  }

  @override
  Widget build(BuildContext context){
    const String ImagePath = 'web/images/well_done.png';

    final greatData = GreatData(context: context);
    final greatItem = greatData.storeGreatItem['0'] ?? [];

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // ===== 1) image =====
                  Image.asset(ImagePath, height: 254), const SizedBox(height: 12),
                  // ===== 2) text =====
                  Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.translate('great'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text(AppLocalizations.of(context)!.translate('great_sub'), style: TextStyle(fontWeight: FontWeight.w400, fontSize: 15, color: AppPalette.fg(Colors.black).withValues(alpha: 0.5)))
                      ]
                    )
                  ),
                  const SizedBox(height: 20),
                  // ===== 3) how many ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), width: double.infinity,
                    decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.grey).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))]),
                    child: Row(children: List.generate(greatItem.length, (index) { return Expanded(child: Row(children: [Expanded(child: _buildGreatItem(context, greatItem[index])), if (index < greatItem.length - 1) _buildDividerVertical()])); }))
                  ),

                  const Spacer(),

                  // ===== 4) button =====
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _handLeValidation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.translate('check_answer'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppPalette.fg(Colors.blue[900]!))),
                          const SizedBox(width: 10),
                          Icon(Icons.arrow_forward_outlined, color: AppPalette.fg(Colors.blue[900]!), size: 16),
                        ],
                      ),
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

  // ======================== build ========================
  Widget _buildGreatItem(BuildContext context, Map<String, dynamic> item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(item['image'], width: 30, height: 30, fit: BoxFit.contain),
        const SizedBox(height: 10),
        Text(item['title'], style: TextStyle(fontWeight: FontWeight.w400, fontSize: 14, color: AppPalette.fg(Colors.grey[600]!)), textAlign: TextAlign.center),
        Text(item['titleSub'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A))), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDividerVertical() { return Container(width: 1, height: 60, color: AppPalette.bg(Colors.black).withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 4)); }
}