import 'package:flutter/material.dart';
import 'package:signlang/services/app_loading.dart';

import 'package:signlang/services/theme_service.dart';
class DailyLifeLessons extends StatefulWidget{
  const DailyLifeLessons({super.key});

  @override
  State<DailyLifeLessons> createState() => _DailyLifeLessonsState();
}

class _DailyLifeLessonsState extends State<DailyLifeLessons> {
  bool _isLoading = true;
  @override
  void initState(){
    super.initState();
    _initData();
  }

// =======================================================================
  Future<void> _initData() async {
    await AppLoading.ready();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeData();
  }

  Future<void> _initializeData() async {
    final results = await Future.wait([
      AppLoading.ready(),
    ]);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppPalette.bg(Color(0xFFBBDEFB)), AppPalette.bg(Colors.white)])),
        child: SafeArea(
            child: CustomScrollView(
              slivers: [
                if (_isLoading)
                  SliverToBoxAdapter()
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                              onTap: () {if (Navigator.canPop(context)) {Navigator.pop(context);}},
                              child: Container(
                                padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppPalette.bg(Colors.white), borderRadius: BorderRadius.circular(15)),
                                child: Icon(Icons.arrow_back_outlined),
                              )
                          ),
                        ],
                      ),
                    ),
                  )
              ],
            )
        ),
      ),
    );
  }
}