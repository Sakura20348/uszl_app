import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:signlang/components/log/login/phoneLogin.dart';
import 'package:signlang/components/log/nameLog/nameLogItem.dart';
import 'package:signlang/components/web/gradientCircularProgress.dart';
import 'package:signlang/l10n/app_localizations.dart';

import 'package:signlang/services/theme_service.dart';
class SetUp extends StatefulWidget {
  const SetUp({super.key});

  @override
  State<SetUp> createState() => _SetUpState();
}

class _SetUpState extends State<SetUp> {
  double _progress = 0.0;
  Timer? _timer;

  @override
  void initState(){ super.initState(); _startProgressSimulation(); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  void _startProgressSimulation() {
    const duration = Duration(milliseconds: 50);
    _timer = Timer.periodic(duration, (timer) { setState(() { if (_progress < 1.0) { _progress += 0.01; } else { _timer?.cancel(); } }); });
  }

  void _handleValidation() { Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneLogin())); }

  @override
  Widget build(BuildContext context){
    final setUpData = SetUpData(context: context);
    final setUpitem = setUpData.storeSetUpItem['0'] ?? [];
    int percentage = (_progress * 100).toInt();

    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // ===== 1) text =====
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('set_up'), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF0F172A)), height: 1.2)),
                      const SizedBox(height: 10),
                      Text(
                        percentage < 100 ? AppLocalizations.of(context)!.translate("set_up_sub") : AppLocalizations.of(context)!.translate("ready"),
                        style: TextStyle(fontSize: 18, color: AppPalette.fg(Colors.black).withValues(alpha: 0.4), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ===== 2) Gradient Circular Progress =====
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 176, height: 176,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF3B82F6)).withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 4))],
                          ),
                        ),

                        GradientCircularProgress(progress: _progress, size: 180, strokeWidth: 12),
                        Text("$percentage%", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppPalette.fg(Color(0xFF2563EB)))),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ===== 3) cards good or bad =====
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppPalette.bg(Color(0xFFF8FAFC)).withValues(alpha: 0.9), borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppPalette.shadow(Colors.black).withValues(alpha: 0.2), blurRadius: 15, offset: Offset(0, 6))]
                    ),
                    child: ListView.separated(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: setUpitem.length,
                      separatorBuilder: (context, index) => Divider(height: 2, thickness: 2, indent: 16, endIndent: 16, color: AppPalette.border(Color(0xFFE2E8F0))),
                      itemBuilder: (context, index) {
                        double stepThreshold = (index + 1) / setUpitem.length;bool isCompleted = _progress >= stepThreshold;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(setUpitem[index]['title'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppPalette.fg(Color(0xFF0F172A)))),
                              ),
                              isCompleted
                                ? Container(
                                  padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: AppPalette.bg(Color(0xFF3B82F6)), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(Icons.check, size: 16, color: AppPalette.fg(Colors.white)))
                                : SizedBox(width: 20, height: 20, child: CupertinoActivityIndicator(color: AppPalette.fg(Colors.blue), radius: 9)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== 4) button =====
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: percentage == 100 ? () {_handleValidation();} : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.1), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, disabledBackgroundColor: AppPalette.bg(Color(0xFF3B82F6)).withValues(alpha: 0.1),
                        shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate("continue"),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: percentage == 100 ? AppPalette.fg(Colors.blue[900]!) : AppPalette.fg(Colors.blue).withValues(alpha: 0.3)),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18, color: percentage == 100 ? AppPalette.fg(Colors.blue[900]!) : AppPalette.fg(Colors.blue).withValues(alpha: 0.3)),
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
}