import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_data.dart';
import '../localization/strings.dart';
import '../widgets/ui.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.data});
  final AppData data;
  @override State<ProgressScreen> createState() => _ProgressScreenState();
}
class _ProgressScreenState extends State<ProgressScreen> {
  late final TextEditingController reflectionController = TextEditingController(text: widget.data.reflection);
  late final TextEditingController goalController = TextEditingController(text: widget.data.personalGoal);
  @override void dispose() { reflectionController.dispose(); goalController.dispose(); super.dispose(); }

  Future<void> _relapse() async {
    final s = context.s;
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(s.t('relapse_title')), content: Text(s.t('relapse_body')), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('restart')))]));
    if (yes == true) { await widget.data.restartRecovery(); reflectionController.clear(); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('relapse_history')))); }
  }

  @override Widget build(BuildContext context) {
    final s = context.s; final streak = widget.data.currentStreak;
    final today = DateTime.now();
    return PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(s.t('progress'), subtitle: s.t('tagline')),
      LuxuryCard(gradient: true, padding: const EdgeInsets.all(22), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.t('streak_days'), style: const TextStyle(color: Colors.white70)), const SizedBox(height: 6), Text('$streak', style: const TextStyle(color: gold, fontSize: 46, height: 1, fontWeight: FontWeight.w800)), Text(s.t('days'), style: const TextStyle(color: muted)), const SizedBox(height: 14), Text('${s.t('total_days')}: ${widget.data.totalDays}', style: const TextStyle(fontWeight: FontWeight.w600))]),), SizedBox(width: 88, height: 88, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: streak == 0 ? 0.035 : (streak % 7) / 7, strokeWidth: 7, backgroundColor: Colors.white12, color: gold), Column(mainAxisSize: MainAxisSize.min, children: [Text('${(widget.data.nextMilestone - streak).clamp(0, 90)}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)), Text(s.t('days'), style: const TextStyle(fontSize: 9, color: muted))])]))])),
      if (widget.data.recoveryStarted == null) ...[const SizedBox(height: 12), PrimaryAction(label: s.t('start_recovery'), onPressed: () => widget.data.restartRecovery(), icon: Icons.flag_rounded)],
      const SizedBox(height: 18),
      SectionTitle(s.t('weekly'), subtitle: s.t('week_days')),
      LuxuryCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(7, (index) {
        final date = today.subtract(Duration(days: 6-index));
        final tracked = widget.data.recoveryStarted != null && !date.isBefore(DateTime(widget.data.recoveryStarted!.year, widget.data.recoveryStarted!.month, widget.data.recoveryStarted!.day)) && !date.isAfter(today);
        final days = [s.t('weekday_mon'),s.t('weekday_tue'),s.t('weekday_wed'),s.t('weekday_thu'),s.t('weekday_fri'),s.t('weekday_sat'),s.t('weekday_sun')];
        return Column(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: tracked ? emerald.withValues(alpha:.45) : Colors.white.withValues(alpha:.04), shape: BoxShape.circle, border: Border.all(color: tracked ? const Color(0xFF67CE91) : Colors.white12)), child: Icon(tracked ? Icons.check_rounded : Icons.remove, size: 17, color: tracked ? const Color(0xFF8AE0AA) : muted)), const SizedBox(height: 8), Text(days[date.weekday-1], style: const TextStyle(color: muted, fontSize: 11))]);
      }))),
      const SizedBox(height: 18), SectionTitle(s.t('monthly'), subtitle: s.t('month_days')),
      Builder(builder: (context) { final monthStart = DateTime(today.year, today.month); final started = widget.data.recoveryStarted; final recoveryDay = started == null ? today : DateTime(started.year, started.month, started.day); final activeFrom = recoveryDay.isAfter(monthStart) ? recoveryDay : monthStart; final utcToday = DateTime.utc(today.year, today.month, today.day); final utcActiveFrom = DateTime.utc(activeFrom.year, activeFrom.month, activeFrom.day); final monthCount = recoveryDay.isAfter(today) ? 0 : utcToday.difference(utcActiveFrom).inDays + 1; final monthLength = DateTime(today.year, today.month + 1, 0).day; return LuxuryCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(s.t('monthly'))), Text('$monthCount / $monthLength', style: const TextStyle(color: gold, fontWeight: FontWeight.w700))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: monthCount / monthLength, minHeight: 8, backgroundColor: Colors.white12, color: emerald))])); }),
      const SizedBox(height: 18), SectionTitle(s.t('milestones')),
      LuxuryCard(child: Column(children: AppData.milestones.map((mile) { final achieved = streak >= mile; final next = !achieved && widget.data.nextMilestone == mile; return Padding(padding: const EdgeInsets.symmetric(vertical: 9), child: Row(children: [Icon(achieved ? Icons.check_circle_rounded : Icons.circle_outlined, color: achieved ? const Color(0xFF7DD99C) : muted, size: 21), const SizedBox(width: 12), Expanded(child: Text('$mile ${s.t('days')}', style: TextStyle(fontWeight: next ? FontWeight.w700 : FontWeight.w500, color: achieved ? Colors.white : muted))), if (achieved) const Pill('✓', color: gold)])); }).toList())),
      const SizedBox(height: 18), SectionTitle(s.t('goal')),
      LuxuryCard(child: Column(children: [TextField(controller: goalController, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: s.t('goal_hint'), prefixIcon: const Icon(Icons.flag_outlined))), if (widget.data.personalGoal.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: Text('${s.t('goal')}: ${widget.data.personalGoal}', style: const TextStyle(color: gold, fontSize: 12)))), const SizedBox(height: 12), PrimaryAction(label: s.t('save_goal'), icon: Icons.check, onPressed: () => widget.data.setGoal(goalController.text))])),
      const SizedBox(height: 18), SectionTitle(s.t('daily_reflection')),
      LuxuryCard(child: Column(children: [TextField(controller: reflectionController, maxLines: 4, maxLength: 400, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(hintText: s.t('reflection_hint'), alignLabelWithHint: true)), const SizedBox(height: 10), PrimaryAction(label: s.t('save_reflection'), icon: Icons.bookmark_add_outlined, onPressed: () async { if (reflectionController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('write_reflection')))); return; } await widget.data.setReflection(reflectionController.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('reflection_saved')))); })])),
      const SizedBox(height: 22), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: widget.data.recoveryStarted == null ? null : _relapse, icon: const Icon(Icons.restart_alt_rounded), label: Text(s.t('relapse')))),
      const SizedBox(height: 10), Text(s.t('relapse_body'), textAlign: TextAlign.center, style: const TextStyle(color: muted, fontSize: 11)),
    ]));
  }
}
