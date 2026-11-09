import 'package:flutter/material.dart';
import '../theme.dart';

class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child});
  final Widget child;
  @override Widget build(BuildContext context) => SafeArea(top: false, child: LayoutBuilder(builder: (context, box) {
    final horizontal = box.maxWidth > 640 ? (box.maxWidth - 560) / 2 : 20.0;
    return SingleChildScrollView(padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 28), child: child);
  }));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle});
  final String title; final String? subtitle;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 14, top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -.3)),
    if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: const TextStyle(color: muted, fontSize: 13))],
  ]));
}

class LuxuryCard extends StatelessWidget {
  const LuxuryCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.gradient = false});
  final Widget child; final EdgeInsets padding; final bool gradient;
  @override Widget build(BuildContext context) => Container(
    width: double.infinity, padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .055)),
      color: panel,
      gradient: gradient ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF153C2B), Color(0xFF101913), Color(0xFF111A15)]) : null,
    ), child: child,
  );
}

class IconHeading extends StatelessWidget {
  const IconHeading({super.key, required this.icon, required this.title, this.subtitle, this.color = gold});
  final IconData icon; final String title; final String? subtitle; final Color color;
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 21)),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle!, style: const TextStyle(fontSize: 12, color: muted))]])),
  ]);
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = emerald});
  final String text; final Color color;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(30)), child: Text(text, style: TextStyle(color: color == emerald ? const Color(0xFF81D0A5) : color, fontSize: 11, fontWeight: FontWeight.w700)));
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key, required this.label, required this.onPressed, this.icon});
  final String label; final VoidCallback? onPressed; final IconData? icon;
  @override Widget build(BuildContext context) => SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 18), label: Text(label)));
}

class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text});
  final IconData icon; final String text;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Column(children: [Icon(icon, color: muted, size: 28), const SizedBox(height: 8), Text(text, style: const TextStyle(color: muted), textAlign: TextAlign.center)]));
}
