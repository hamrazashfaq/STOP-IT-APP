import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_data.dart';
import '../services/native_bridge.dart';
import '../localization/strings.dart';
import '../widgets/ui.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.data});
  final AppData data;

  Future<void> _clear(BuildContext context) async {
    final s = context.s;
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(s.t('clear_data')), content: Text(s.t('clear_confirm')), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))), TextButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('delete')))]));
    if (yes != true || !context.mounted) return;
    await data.disableProtection();
    await data.clear();
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('data_cleared'))));
  }

  @override Widget build(BuildContext context) {
    final s = context.s;
    return PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(s.t('settings'), subtitle: s.t('setting_desc')),
      LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.translate_rounded, title: s.t('language')), const SizedBox(height: 14), Wrap(spacing: 8, runSpacing: 8, children: ['en','ur','ar'].map((code) => ChoiceChip(label: Text(AppStrings.languageName(code)), selected: code == data.language, selectedColor: emerald.withValues(alpha:.45), onSelected: (_) => data.setLanguage(code))).toList())])),
      const SizedBox(height: 14), LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, value: data.dailyReminderEnabled, activeThumbColor: gold, secondary: const Icon(Icons.notifications_active_outlined, color: gold), title: Text(s.t('daily_reminder')), subtitle: Text(s.t('daily_reminder_desc')), onChanged: (value) async { if (value) await NativeBridge.requestNotifications(); await data.setDailyReminder(value); await NativeBridge.setDailyReminder(value); }),
      ])),
      const SizedBox(height: 14), LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.lock_outline_rounded, title: s.t('privacy')), const SizedBox(height: 11), Text(s.t('privacy_text'), style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 12), Text(s.t('dns_note'), style: const TextStyle(color: Colors.white70, fontSize: 12))])),
      const SizedBox(height: 14),
      LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.help_outline_rounded, title: s.t('faq')), const SizedBox(height: 6),
        _FaqRow(question: s.t('faq_what'), answer: s.t('protection_disclosure')),
        _FaqRow(question: s.t('faq_limit'), answer: s.t('dns_note')),
        _FaqRow(question: s.t('faq_data'), answer: s.t('privacy_text')),
        _FaqRow(question: s.t('faq_relapse'), answer: s.t('relapse_body')),
      ])),
      const SizedBox(height: 14),
      LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.info_outline_rounded, title: s.t('about')), const SizedBox(height: 12), Text(s.t('tagline'), style: const TextStyle(color: gold)), const SizedBox(height: 8), Text(s.t('about_body'), style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 10), const Text('Version 1.0.0 · Private by default', style: TextStyle(fontSize: 11, color: muted))])),
      const SizedBox(height: 16), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _clear(context), icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE58B82)), label: Text(s.t('clear_data'), style: const TextStyle(color: Color(0xFFE58B82))))),
      const SizedBox(height: 16), Text(s.t('support_note'), textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
    ]));
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.question, required this.answer});
  final String question, answer;
  @override Widget build(BuildContext context) => ExpansionTile(title: Text(question, style: const TextStyle(fontSize: 14)), iconColor: gold, collapsedIconColor: muted, tilePadding: EdgeInsets.zero, childrenPadding: const EdgeInsets.only(bottom: 14), children: [Align(alignment: AlignmentDirectional.centerStart, child: Text(answer, style: const TextStyle(color: muted, fontSize: 12)))]);
}
