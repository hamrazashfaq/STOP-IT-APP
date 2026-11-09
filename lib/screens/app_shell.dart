import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_data.dart';
import '../localization/strings.dart';
import 'home_screen.dart';
import 'protection_screen.dart';
import 'progress_screen.dart';
import 'activities_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.data});
  final AppData data;
  @override State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? statusTimer;
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); statusTimer = Timer.periodic(const Duration(seconds: 4), (_) => widget.data.refreshProtectionStatus()); }
  @override void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) widget.data.refreshNativeHistory(); }
  @override void dispose() { statusTimer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  int selected = 0;
  bool prompted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.data.loaded && !widget.data.onboardingComplete && !prompted) {
      prompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _showWelcome(); });
    }
  }

  Future<void> _showWelcome() async {
    var choice = widget.data.language;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      backgroundColor: panel, title: Text(AppStrings(choice == 'ur' ? const Locale('ur') : choice == 'ar' ? const Locale('ar') : const Locale('en')).t('onboarding_title')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppStrings(choice == 'ur' ? const Locale('ur') : choice == 'ar' ? const Locale('ar') : const Locale('en')).t('onboarding_body')),
        const SizedBox(height: 18), Text(AppStrings(choice == 'ur' ? const Locale('ur') : choice == 'ar' ? const Locale('ar') : const Locale('en')).t('choose_language'), style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: ['en','ur','ar'].map((code) => ChoiceChip(label: Text(AppStrings.languageName(code)), selected: choice == code, selectedColor: emerald, onSelected: (_) => setDialogState(() => choice = code))).toList()),
      ]),
      actions: [TextButton(onPressed: () async { await widget.data.setLanguage(choice); await widget.data.finishOnboarding(); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: Text(AppStrings(choice == 'ur' ? const Locale('ur') : choice == 'ar' ? const Locale('ar') : const Locale('en')).t('begin')))],
    )));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final pages = [
      HomeScreen(data: widget.data, goTo: (index) => setState(() => selected = index)),
      ProtectionScreen(data: widget.data),
      ProgressScreen(data: widget.data),
      ActivitiesScreen(data: widget.data),
      SettingsScreen(data: widget.data),
    ];
    final labels = [s.t('home'), s.t('protection'), s.t('progress'), s.t('activities'), s.t('settings')];
    const icons = [Icons.home_rounded, Icons.shield_rounded, Icons.insights_rounded, Icons.bolt_rounded, Icons.tune_rounded];
    return Scaffold(
      appBar: AppBar(title: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/images/stop_it_logo.png', width: 31, height: 31, fit: BoxFit.cover)), const SizedBox(width: 10), const Text('STOP IT!', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.3))]), actions: [IconButton(tooltip: s.t('history_refresh'), onPressed: widget.data.refreshNativeHistory, icon: const Icon(Icons.refresh_rounded, color: muted))]),
      body: widget.data.loaded ? IndexedStack(index: selected, children: pages) : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: gold), const SizedBox(height: 14), Text(s.t('loading'))])),
      bottomNavigationBar: NavigationBar(selectedIndex: selected, onDestinationSelected: (index) { setState(() => selected = index); if (index == 1) widget.data.refreshNativeHistory(); }, destinations: List.generate(5, (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i]))),
    );
  }
}
