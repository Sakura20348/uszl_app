import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';
import 'package:signlang/components/uiTextBooks/group/familyLessons/two/exam/examTwo.dart';

import '../../../../../../l10n/app_localizations.dart';
import '../../../../../web/loading/bookLoading.dart';

import 'package:signlang/services/theme_service.dart';
class ExamWords2One extends StatefulWidget{
  const ExamWords2One({super.key});

  @override
  State<ExamWords2One> createState() => _ExamWords2OneState();
}

class _ExamWords2OneState extends State<ExamWords2One> {
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _initData(); }

// =======================================================================
  Future<void> _handleRefresh() async { setState(() { _isLoading = true; }); await _initializeData(); }
  Future<void> _initData() async { await AppLoading.ready(); if (mounted) { setState(() { _isLoading = false; }); } }
  Future<void> _initializeData() async { final results = await Future.wait([AppLoading.ready()]); if (!mounted) return; setState(() { _isLoading = false; }); }

  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
          child: SafeArea(
            child: RefreshIndicator(
              onRefresh: _handleRefresh, notificationPredicate: (ScrollNotification notification) {return notification.depth == 0;},
              child: CustomScrollView(
                slivers: [
                  if(_isLoading)
                  // ======= 1 =======
                    const SliverFillRemaining(hasScrollBody: false, child: Center(child: BookLoader(label: 'Loading')))
                  else
                  // ======= 2 =======
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            // ===== 1) exam test =====
                            Center(
                              child: Container(
                                width: 200, height: 200,
                                decoration: BoxDecoration(
                                  color: AppPalette.bg(Colors.white).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(150), border: Border.all(width: 1, color: AppPalette.border(Colors.white)),
                                  boxShadow: [BoxShadow(color: AppPalette.shadow(Color(0xFF42A5F5)).withValues(alpha: 0.9), blurRadius: 15)],
                                ),
                                child: Center(child: Image.asset('web/images/exam.png', width: 130, height: 140))
                              ),
                            ),
                            const SizedBox(height: 30,),
                            // ===== 2) text =====
                            Text(AppLocalizations.of(context)!.translate('good_job'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 34)),
                            const SizedBox(height: 4),
                            Text(AppLocalizations.of(context)!.translate('good_job_sub'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400)),
                            const Spacer(),
                            // ===== 6) button =====
                            SizedBox(
                              width: double.infinity, height: 56,
                              child: ElevatedButton(
                                onPressed: () {Navigator.push(context, MaterialPageRoute(builder: (_) => const ExamWords2Two()));},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPalette.bg(Color(0xFF4A7FD0)).withValues(alpha: 0.2), foregroundColor: AppPalette.fg(Colors.white), elevation: 6, shadowColor: AppPalette.shadow(Color(0xFFBBDEFB)).withValues(alpha: 0.9),
                                  side: BorderSide(width: 1, color: AppPalette.border(Color(0xFF1A237E)).withValues(alpha: 0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                child: Text(AppLocalizations.of(context)!.translate('start_lesson'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppPalette.fg(Colors.white))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              )
            )
          ),
        ),
      )
    );
  }
}