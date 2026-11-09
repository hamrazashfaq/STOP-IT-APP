import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_data.dart';
import '../localization/strings.dart';
import '../widgets/ui.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key, required this.data});
  final AppData data;
  Future<void> _open(BuildContext context, Widget page) async { await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => page)); }
  @override Widget build(BuildContext context) {
    final s = context.s;
    final actions = <(String, String, IconData, Color, Widget)>[
      (s.t('memory'), s.t('memory_desc'), Icons.grid_view_rounded, gold, const MemoryGame()),
      (s.t('number_puzzle'), s.t('puzzle_desc'), Icons.calculate_rounded, const Color(0xFF8BC8F2), const NumberPuzzle()),
      (s.t('breathing'), s.t('breathing_desc'), Icons.air_rounded, const Color(0xFF8ED1A8), const BreathingExercise()),
      (s.t('five_min'), s.t('focus_desc'), Icons.timer_outlined, const Color(0xFFD7A2E9), const FocusChallenge()),
      (s.t('challenge'), s.t('challenge_desc'), Icons.flag_circle_rounded, gold, const DisciplineChallenge()),
      (s.t('read'), s.t('read_desc'), Icons.menu_book_rounded, const Color(0xFFF2A58B), const ReminderReading()),
    ];
    return PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(s.t('activities_title'), subtitle: s.t('activities_intro')),
      LuxuryCard(gradient: true, child: Row(children: [const Icon(Icons.self_improvement_rounded, color: gold, size: 30), const SizedBox(width: 12), Expanded(child: Text(s.t('blocked_notice'), style: const TextStyle(fontWeight: FontWeight.w600)))])),
      const SizedBox(height: 16),
      ...actions.map((a) => Padding(padding: const EdgeInsets.only(bottom: 11), child: InkWell(onTap: () => _open(context, a.$5), borderRadius: BorderRadius.circular(20), child: LuxuryCard(padding: const EdgeInsets.all(15), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: a.$4.withValues(alpha:.13), borderRadius: BorderRadius.circular(15)), child: Icon(a.$3, color: a.$4)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(a.$1, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(a.$2, style: const TextStyle(color: muted, fontSize: 12))])), const Icon(Icons.arrow_forward_ios_rounded, color: muted, size: 16)]))))),
      const SizedBox(height: 8), Text(s.t('offline_note'), style: const TextStyle(color: muted, fontSize: 11)),
    ]));
  }
}

class _ActivityPage extends StatelessWidget {
  const _ActivityPage({required this.title, required this.icon, required this.child});
  final String title; final IconData icon; final Widget child;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Row(children: [Icon(icon, color: gold), const SizedBox(width: 10), Expanded(child: Text(title, overflow: TextOverflow.ellipsis))])), body: PagePadding(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: child))));
}

class MemoryGame extends StatefulWidget { const MemoryGame({super.key}); @override State<MemoryGame> createState() => _MemoryGameState(); }
class _MemoryGameState extends State<MemoryGame> {
  final random = Random(); List<int> sequence = []; List<int> answers = []; bool showing = false; int showingIndex = -1; bool complete = false; bool? result; int round = 1;
  Future<void> start() async { setState(() { sequence = List.generate(3 + min(round-1, 4), (_) => random.nextInt(4)); answers = []; showing = true; showingIndex = -1; result = null; complete = false; }); for (var i = 0; i < sequence.length; i++) { if (!mounted) return; setState(() => showingIndex = i); await Future<void>.delayed(const Duration(milliseconds: 650)); } if (mounted) setState(() { showing = false; showingIndex = -1; }); }
  void tap(int index) { if (showing || complete || sequence.isEmpty) return; setState(() { answers.add(index); if (answers.last != sequence[answers.length - 1]) { complete = true; result = false; } else if (answers.length == sequence.length) { complete = true; result = true; round = min(round + 1, 5); } }); }
  @override Widget build(BuildContext context) { final s = context.s; return _ActivityPage(title: s.t('memory'), icon: Icons.grid_view_rounded, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s.t(showing ? 'watch_pattern' : complete ? (result! ? 'correct' : 'try_again') : sequence.isEmpty ? 'tap_sequence' : 'your_turn'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text('${s.t('round')} $round', style: const TextStyle(color: muted)), const SizedBox(height: 24), GridView.count(shrinkWrap: true, crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, children: List.generate(4, (i) { final activeFlash = showing && showingIndex >= 0 && sequence[showingIndex] == i; final colors = [emerald, const Color(0xFF315D7A), const Color(0xFF79572B), const Color(0xFF694575)]; return InkWell(onTap: () => tap(i), borderRadius: BorderRadius.circular(20), child: AnimatedContainer(duration: const Duration(milliseconds: 180), decoration: BoxDecoration(color: activeFlash ? gold : colors[i].withValues(alpha: .38), borderRadius: BorderRadius.circular(20), border: Border.all(color: colors[i].withValues(alpha:.8))), child: Icon(Icons.circle, size: 30, color: activeFlash ? ink : Colors.white70))); })), const SizedBox(height: 20), if (sequence.isEmpty || complete) PrimaryAction(label: s.t(complete ? 'restart_game' : 'begin'), onPressed: start, icon: Icons.play_arrow_rounded)])); }
}

class NumberPuzzle extends StatefulWidget { const NumberPuzzle({super.key}); @override State<NumberPuzzle> createState() => _NumberPuzzleState(); }
class _NumberPuzzleState extends State<NumberPuzzle> {
  final random = Random(); final answerController = TextEditingController(); late int a = 8 + random.nextInt(30), b = 2 + random.nextInt(19); late bool add = random.nextBool(); bool? correct; int solved = 0;
  void next() { setState(() { a = 8 + random.nextInt(30); b = 2 + random.nextInt(19); add = random.nextBool(); correct = null; answerController.clear(); }); }
  void check() { if (correct == true) return; final value = int.tryParse(answerController.text.trim()); setState(() { correct = value == (add ? a+b : a-b); if (correct == true) solved++; }); }
  @override void dispose() { answerController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) { final s = context.s; return _ActivityPage(title: s.t('number_puzzle'), icon: Icons.calculate_rounded, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s.t('solve_puzzle'), style: const TextStyle(color: muted)), const SizedBox(height: 8), Text('$a ${add ? '+' : '−'} $b = ?', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: gold)), Text('${s.t('solved')}: $solved', style: const TextStyle(color: muted)), const SizedBox(height: 20), TextField(controller: answerController, keyboardType: const TextInputType.numberWithOptions(signed: true), textAlign: TextAlign.center, decoration: InputDecoration(hintText: s.t('answer'))), const SizedBox(height: 14), PrimaryAction(label: s.t('check'), onPressed: check, icon: Icons.check_rounded), if (correct != null) ...[const SizedBox(height: 12), Text(s.t(correct! ? 'correct_answer' : 'incorrect_answer'), style: TextStyle(color: correct! ? const Color(0xFF83D6A0) : gold)), if (correct!) TextButton(onPressed: next, child: Text(s.t('next_puzzle')))] ])); }
}

class BreathingExercise extends StatefulWidget { const BreathingExercise({super.key}); @override State<BreathingExercise> createState() => _BreathingExerciseState(); }
class _BreathingExerciseState extends State<BreathingExercise> {
  Timer? timer; int seconds = 60; bool running = false;
  void start() { timer?.cancel(); setState(() { seconds = 60; running = true; }); timer = Timer.periodic(const Duration(seconds: 1), (t) { if (!mounted) return; setState(() { seconds--; if (seconds <= 0) { t.cancel(); running = false; } }); }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) { final s = context.s; final elapsed = 60-seconds; final phase = elapsed % 14; final phaseLabel = phase < 4 ? 'breathe_in' : phase < 6 ? 'hold' : 'breathe_out'; return _ActivityPage(title: s.t('breathing'), icon: Icons.air_rounded, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s.t('breathing_instruction'), textAlign: TextAlign.center, style: const TextStyle(color: muted)), const SizedBox(height: 30), AnimatedContainer(duration: const Duration(seconds: 3), width: phase < 4 ? 190 : 145, height: phase < 4 ? 190 : 145, decoration: BoxDecoration(shape: BoxShape.circle, color: emerald.withValues(alpha:.25), border: Border.all(color: gold.withValues(alpha:.6), width: 2)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.spa_outlined, color: gold, size: 32), const SizedBox(height: 8), Text(running ? s.t(phaseLabel) : s.t('ready'), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)), if (running) Text('0:${seconds.toString().padLeft(2,'0')}', style: const TextStyle(color: muted))])), const SizedBox(height: 30), if (seconds == 0) Text(s.t('correct'), textAlign: TextAlign.center, style: const TextStyle(color: gold)), PrimaryAction(label: s.t(running ? 'in_progress' : 'begin'), onPressed: running ? null : start, icon: Icons.play_arrow_rounded)])); }
}

class FocusChallenge extends StatefulWidget { const FocusChallenge({super.key}); @override State<FocusChallenge> createState() => _FocusChallengeState(); }
class _FocusChallengeState extends State<FocusChallenge> {
  Timer? timer; int seconds = 300; bool running = false; bool done = false;
  void toggle() { if (running) { timer?.cancel(); setState(() => running = false); return; } if (done) setState(() { seconds=300; done=false; }); setState(() => running=true); timer = Timer.periodic(const Duration(seconds:1), (t) { if (!mounted) return; setState(() { seconds--; if (seconds <= 0) { t.cancel(); running=false; done=true; } }); }); }
  @override void dispose() { timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) { final s = context.s; return _ActivityPage(title: s.t('five_min'), icon: Icons.timer_outlined, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(s.t('focus_instruction'), textAlign: TextAlign.center, style: const TextStyle(color: muted)), const SizedBox(height: 28), Text('${(seconds~/60).toString().padLeft(2,'0')}:${(seconds%60).toString().padLeft(2,'0')}', style: const TextStyle(fontSize: 58, color: gold, fontWeight: FontWeight.w800)), const SizedBox(height: 16), if (done) Text(s.t('focus_started'), textAlign: TextAlign.center), PrimaryAction(label: s.t(running ? 'pause' : done ? 'restart_game' : 'begin'), onPressed: toggle, icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded)])); }
}

class DisciplineChallenge extends StatefulWidget { const DisciplineChallenge({super.key}); @override State<DisciplineChallenge> createState() => _DisciplineChallengeState(); }
class _DisciplineChallengeState extends State<DisciplineChallenge> {
  bool complete = false;
  @override Widget build(BuildContext context) { final s = context.s; return _ActivityPage(title: s.t('challenge'), icon: Icons.flag_circle_rounded, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.checklist_rounded, size: 54, color: gold), const SizedBox(height: 18), Text(s.t('challenge_prompt'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 12), Text(s.t('challenge_detail'), textAlign: TextAlign.center, style: const TextStyle(color: muted)), const SizedBox(height: 24), PrimaryAction(label: s.t(complete ? 'completed_today' : 'mark_complete'), onPressed: complete ? null : () => setState(() => complete=true), icon: Icons.check_circle_outline)])); }
}

class ReminderReading extends StatelessWidget { const ReminderReading({super.key}); @override Widget build(BuildContext context) { final s = context.s; return _ActivityPage(title: s.t('read'), icon: Icons.menu_book_rounded, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [LuxuryCard(child: Column(children: [Text(s.t('quran_arabic'), textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, height: 1.8, color: gold)), const SizedBox(height: 12), Text('“${s.t('quran_translation')}”', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 7), Text(s.t('quran_source'), style: const TextStyle(color: muted, fontSize: 12)), const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Divider(color: Colors.white12)), Text(s.t('hadith_arabic'), textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, height: 1.8, color: gold)), const SizedBox(height: 10), Text('“${s.t('hadith_text')}”', textAlign: TextAlign.center), const SizedBox(height: 8), Text(s.t('hadith_source'), style: const TextStyle(color: muted, fontSize: 12))])), const SizedBox(height: 18), Text(s.t('reflect_reading'), textAlign: TextAlign.center, style: const TextStyle(color: muted))])); } }
