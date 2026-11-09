import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_data.dart';
import '../localization/strings.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.data, required this.goTo});
  final AppData data; final ValueChanged<int> goTo;
  @override Widget build(BuildContext context) {
    final s = context.s;
    return PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(s.t('hello'), style: const TextStyle(color: muted, fontSize: 14)),
      const SizedBox(height: 3), Text(s.t('tagline'), style: const TextStyle(fontSize: 14, color: Colors.white70)),
      const SizedBox(height: 20),
      LuxuryCard(gradient: true, padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.t(data.protectionOn ? 'protection_on' : 'protection_off'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(s.t(data.protectionOn ? 'status_detail' : 'dns_note'), style: const TextStyle(color: Colors.white70, fontSize: 12))]),),
          Container(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, color: data.protectionOn ? emerald.withValues(alpha:.3) : Colors.white.withValues(alpha:.06), border: Border.all(color: data.protectionOn ? const Color(0xFF52C987) : muted.withValues(alpha:.4))), child: Icon(data.protectionOn ? Icons.shield_rounded : Icons.shield_outlined, color: data.protectionOn ? const Color(0xFF75D89C) : muted, size: 28)),
        ]), const SizedBox(height: 18), Row(children: [Icon(Icons.local_fire_department_rounded, color: gold, size: 21), const SizedBox(width: 7), Text('${s.t('streak')}: ${data.currentStreak} ${s.t('days')}', style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), if (data.recoveryStarted == null) TextButton(onPressed: () => data.restartRecovery(), child: Text(s.t('start_recovery'), style: const TextStyle(color: gold))) ]),
      ])),
      const SizedBox(height: 16),
      LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.auto_awesome_rounded, title: s.t('quran_title'), color: gold), const SizedBox(height: 18), Text(s.t('quran_arabic'), textDirection: TextDirection.rtl, textAlign: TextAlign.right, style: const TextStyle(fontSize: 24, height: 1.8, color: gold, fontFamily: 'serif')), const SizedBox(height: 8), Text('“${s.t('quran_translation')}”', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), const SizedBox(height: 5), Text(s.t('quran_source'), style: const TextStyle(fontSize: 11, color: muted))])),
      const SizedBox(height: 16),
      LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.favorite_outline_rounded, title: s.t('hadith_title'), color: const Color(0xFF79CBA0)), const SizedBox(height: 14), Text(s.t('hadith_arabic'), textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(color: gold, fontSize: 19, height: 1.8)), const SizedBox(height: 7), Text('“${s.t('hadith_text')}”'), const SizedBox(height: 8), Text(s.t('hadith_source'), style: const TextStyle(fontSize: 11, color: muted))])),
      const SizedBox(height: 16),
      LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [IconHeading(icon: Icons.bolt_rounded, title: s.t('quick_choice')), const SizedBox(height: 14), Text(s.t('activities_intro'), style: const TextStyle(color: muted)), const SizedBox(height: 14), PrimaryAction(label: s.t('start_activity'), icon: Icons.self_improvement_rounded, onPressed: () => goTo(3))])),
      const SizedBox(height: 16),
      InkWell(onTap: () => goTo(1), borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [const Icon(Icons.info_outline_rounded, color: muted, size: 18), const SizedBox(width: 8), Expanded(child: Text(s.t('dns_note'), style: const TextStyle(color: muted, fontSize: 11))), const Icon(Icons.chevron_right, color: muted)]))),
    ]));
  }
}
