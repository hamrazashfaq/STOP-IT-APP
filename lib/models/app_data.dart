import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/native_bridge.dart';

class BlockedAttempt {
  const BlockedAttempt(this.domain, this.at);
  final String domain;
  final DateTime at;
  factory BlockedAttempt.fromJson(Map<String, dynamic> json) => BlockedAttempt(
    json['domain'] as String? ?? '', DateTime.fromMillisecondsSinceEpoch((json['at'] as num?)?.toInt() ?? 0));
  Map<String, Object> toJson() => {'domain': domain, 'at': at.millisecondsSinceEpoch};
}

class AppData extends ChangeNotifier {
  String language = 'en';
  DateTime? recoveryStarted;
  int completedDaysBefore = 0;
  String personalGoal = '';
  String reflection = '';
  String reflectionDate = '';
  List<String> customDomains = [];
  List<BlockedAttempt> attempts = [];
  bool protectionOn = false;
  bool onboardingComplete = false;
  bool dailyReminderEnabled = false;
  bool loaded = false;

  int get currentStreak {
    if (recoveryStarted == null) return 0;
    final elapsed = DateTime.now().toUtc().difference(recoveryStarted!.toUtc()).inDays;
    return elapsed < 0 ? 0 : elapsed;
  }
  int get totalDays => completedDaysBefore + currentStreak;
  static const milestones = [1, 3, 7, 14, 30, 60, 90];
  int get nextMilestone => milestones.firstWhere((day) => day > currentStreak, orElse: () => 90);

  Future<void> load() async {
    try {
      final data = jsonDecode(await NativeBridge.readState()) as Map<String, dynamic>;
      language = data['language'] as String? ?? 'en';
      recoveryStarted = DateTime.tryParse(data['recoveryStarted'] as String? ?? '');
      completedDaysBefore = (data['completedDaysBefore'] as num?)?.toInt() ?? 0;
      personalGoal = data['personalGoal'] as String? ?? '';
      reflection = data['reflection'] as String? ?? '';
      reflectionDate = data['reflectionDate'] as String? ?? '';
      customDomains = (data['customDomains'] as List<dynamic>? ?? []).whereType<String>().toSet().toList();
      attempts = (data['blockedAttempts'] as List<dynamic>? ?? []).whereType<Map>().map((e) => BlockedAttempt.fromJson(Map<String,dynamic>.from(e))).toList();
      onboardingComplete = data['onboardingComplete'] as bool? ?? false;
      dailyReminderEnabled = data['dailyReminderEnabled'] as bool? ?? false;
      protectionOn = await NativeBridge.protectionStatus();
    } catch (_) { /* A fresh install starts with safe defaults. */ }
    loaded = true;
    notifyListeners();
  }

  Map<String, Object?> toJson() => {
    'language': language, 'onboardingComplete': onboardingComplete, 'dailyReminderEnabled': dailyReminderEnabled, 'recoveryStarted': recoveryStarted?.toIso8601String(),
    'completedDaysBefore': completedDaysBefore, 'personalGoal': personalGoal,
    'reflection': reflection, 'reflectionDate': reflectionDate,
    'customDomains': customDomains, 'blockedAttempts': attempts.map((e) => e.toJson()).toList(),
  };

  Future<void> _persist() async {
    await NativeBridge.saveState(jsonEncode(toJson()));
    notifyListeners();
  }

  Future<void> setLanguage(String value) async { language = value; await _persist(); }
  Future<void> finishOnboarding() async { onboardingComplete = true; await _persist(); }
  Future<void> setDailyReminder(bool value) async { dailyReminderEnabled = value; await _persist(); }
  Future<void> setGoal(String value) async { personalGoal = value.trim(); await _persist(); }
  Future<void> setReflection(String value) async {
    reflection = value.trim(); final now = DateTime.now();
    reflectionDate = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    await _persist();
  }
  Future<bool> addDomain(String raw) async {
    var value = raw.trim().toLowerCase().replaceFirst(RegExp(r'^https?://'), '').split('/').first.replaceFirst(RegExp(r':\d+$'), '').replaceAll(RegExp(r'\.$'), '');
    if (value.startsWith('*.')) value = value.substring(2);
    if (value.isEmpty || value.length > 253 || value.contains(' ') || RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(value) || value.startsWith('.') || !value.contains('.') || value.split('.').any((label) => label.isEmpty || label.length > 63 || !RegExp(r'^[a-z0-9-]+$').hasMatch(label) || label.startsWith('-') || label.endsWith('-'))) return false;
    if (!customDomains.contains(value)) { customDomains.add(value); await _persist(); }
    return true;
  }
  Future<void> removeDomain(String value) async { customDomains.remove(value); await _persist(); }
  Future<void> refreshProtectionStatus() async {
    try {
      final current = await NativeBridge.protectionStatus();
      if (protectionOn != current) { protectionOn = current; notifyListeners(); }
    } catch (_) { }
  }

  Future<void> refreshNativeHistory() async {
    try {
      final data = jsonDecode(await NativeBridge.readState()) as Map<String, dynamic>;
      attempts = (data['blockedAttempts'] as List<dynamic>? ?? []).whereType<Map>().map((e) => BlockedAttempt.fromJson(Map<String,dynamic>.from(e))).toList();
      protectionOn = await NativeBridge.protectionStatus();
      notifyListeners();
    } catch (_) { }
  }
  Future<bool> enableProtection() async {
    final requested = await NativeBridge.startProtection();
    if (!requested) { protectionOn = false; notifyListeners(); return false; }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await refreshNativeHistory();
    return protectionOn;
  }
  Future<void> disableProtection() async { await NativeBridge.stopProtection(); protectionOn = false; notifyListeners(); }
  Future<void> restartRecovery() async {
    if (currentStreak > 0) completedDaysBefore += currentStreak;
    recoveryStarted = DateTime.now();
    reflection = ''; reflectionDate = '';
    await _persist();
  }
  Future<void> clear() async {
    await NativeBridge.stopProtection();
    protectionOn = false;
    await NativeBridge.setDailyReminder(false);
    await NativeBridge.clearState();
    language = 'en'; recoveryStarted = null; completedDaysBefore = 0; onboardingComplete = true; dailyReminderEnabled = false;
    personalGoal = ''; reflection = ''; reflectionDate = ''; customDomains = []; attempts = [];
    await _persist();
  }
}
