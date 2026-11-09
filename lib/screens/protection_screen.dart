import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_data.dart';
import '../services/native_bridge.dart';
import '../localization/strings.dart';
import '../widgets/ui.dart';

class ProtectionScreen extends StatefulWidget {
  const ProtectionScreen({super.key, required this.data});
  final AppData data;
  @override State<ProtectionScreen> createState() => _ProtectionScreenState();
}
class _ProtectionScreenState extends State<ProtectionScreen> {
  final domainController = TextEditingController();
  bool busy = false;
  @override void dispose() { domainController.dispose(); super.dispose(); }

  Future<void> _toggle() async {
    final s = context.s;
    if (widget.data.protectionOn) {
      final approved = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(s.t('turn_off')), content: Text(s.t('dns_note')), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))), TextButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('turn_off')))]));
      if (approved == true) await widget.data.disableProtection();
      return;
    }
    var accepted = false;
    accepted = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      backgroundColor: panel, title: Text(s.t('turn_on')),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.t('protection_disclosure')), const SizedBox(height: 12), Text(s.t('permission_explain'), style: const TextStyle(color: gold))])),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('cancel'))), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('agree_start')))],
    )) ?? false;
    if (!accepted || !mounted) return;
    setState(() => busy = true);
    try {
      await NativeBridge.requestNotifications();
      final started = await widget.data.enableProtection();
      if (!mounted) return;
      if (!started) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('permission_denied'))));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('not_android'))));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _addDomain() async {
    final s = context.s;
    final valid = await widget.data.addDomain(domainController.text);
    if (!mounted) return;
    if (valid) { domainController.clear(); FocusScope.of(context).unfocus(); }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(valid ? s.t('added') : s.t('invalid_domain'))));
  }

  @override Widget build(BuildContext context) {
    final s = context.s;
    return PagePadding(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      LuxuryCard(gradient: true, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconHeading(icon: Icons.shield_moon_rounded, title: s.t(widget.data.protectionOn ? 'protection_on' : 'protection_off'), subtitle: s.t(widget.data.protectionOn ? 'active' : 'inactive'), color: widget.data.protectionOn ? const Color(0xFF77D99E) : muted),
        const SizedBox(height: 18), SizedBox(width: double.infinity, child: widget.data.protectionOn ? OutlinedButton.icon(onPressed: busy ? null : _toggle, icon: const Icon(Icons.pause_circle_outline), label: Text(s.t('turn_off'))) : ElevatedButton.icon(onPressed: busy ? null : _toggle, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ink)) : const Icon(Icons.lock_outline_rounded), label: Text(s.t('turn_on')))),
        const SizedBox(height: 12), Text(s.t('dns_note'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
      const SizedBox(height: 18),
      SectionTitle(s.t('your_blocklist'), subtitle: s.t('domain_help')),
      Row(children: [Expanded(child: TextField(controller: domainController, textInputAction: TextInputAction.done, onSubmitted: (_) => _addDomain(), decoration: InputDecoration(hintText: s.t('domain_hint'), prefixIcon: const Icon(Icons.language_rounded)))), const SizedBox(width: 8), IconButton.filled(onPressed: _addDomain, style: IconButton.styleFrom(backgroundColor: gold, foregroundColor: ink), icon: const Icon(Icons.add_rounded), tooltip: s.t('add_domain'))]),
      if (widget.data.customDomains.isEmpty) EmptyHint(icon: Icons.playlist_add_rounded, text: s.t('no_domains')) else ...widget.data.customDomains.map((domain) => Padding(padding: const EdgeInsets.only(top: 8), child: LuxuryCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [const Icon(Icons.block_rounded, color: gold, size: 18), const SizedBox(width: 10), Expanded(child: Text(domain, style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(tooltip: s.t('remove_domain'), onPressed: () => widget.data.removeDomain(domain), icon: const Icon(Icons.close_rounded, color: muted, size: 19))])))),
      const SizedBox(height: 18),
      SectionTitle(s.t('blocked_attempts')),
      if (widget.data.attempts.isEmpty) EmptyHint(icon: Icons.shield_outlined, text: s.t('no_attempts')) else ...widget.data.attempts.reversed.take(30).map((entry) => Padding(padding: const EdgeInsets.only(bottom: 8), child: LuxuryCard(padding: const EdgeInsets.all(13), child: Row(children: [const Icon(Icons.block_rounded, color: gold, size: 19), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry.domain, style: const TextStyle(fontWeight: FontWeight.w600)), Text(MaterialLocalizations.of(context).formatMediumDate(entry.at), style: const TextStyle(color: muted, fontSize: 11))])), Text('${entry.at.hour.toString().padLeft(2,'0')}:${entry.at.minute.toString().padLeft(2,'0')}', style: const TextStyle(color: muted, fontSize: 12))])))),
      const SizedBox(height: 12),
      Text(s.t('privacy_text'), style: const TextStyle(color: muted, fontSize: 11)),
    ]));
  }
}
