import 'package:flutter/material.dart';

import 'backstage.dart';
import 'widgets/console_panel.dart';

/// Wrap your whole app with this so the console can appear on top.
class BackstageOverlay extends StatelessWidget {
  final Widget child;
  const BackstageOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: Backstage.I.enabled,
          builder: (_, enabled, __) =>
              enabled ? const _OverlayConsole() : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OverlayConsole extends StatefulWidget {
  const _OverlayConsole();
  @override
  State<_OverlayConsole> createState() => _OverlayConsoleState();
}

class _OverlayConsoleState extends State<_OverlayConsole> {
  Offset pos = const Offset(16, 100);

  late final ConsolePanel _panelWidget;

  @override
  void initState() {
    super.initState();
    _panelWidget = ConsolePanel(logger: Backstage.I.logger);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            pos += details.delta;
          });
        },
        child: Material(
          type: MaterialType.transparency,
          child: _panelWidget,
        ),
      ),
    );
  }
}

/// Wrap any widget to act as the hidden entry (5 taps within 2s or long-press)
class BackstageEntryGate extends StatefulWidget {
  final Widget child;
  final String? passcode;
  const BackstageEntryGate({super.key, required this.child, this.passcode});

  @override
  State<BackstageEntryGate> createState() => _BackstageEntryGateState();
}

class _BackstageEntryGateState extends State<BackstageEntryGate> {
  int taps = 0;
  DateTime? _last;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        if (_last == null ||
            now.difference(_last!) > const Duration(seconds: 2)) {
          taps = 0;
        }
        _last = now;
        taps++;
        if (taps >= 5) {
          taps = 0;
          await _maybeUnlock(context);
        }
      },
      onLongPress: () async => _maybeUnlock(context),
      child: widget.child,
    );
  }

  Future<void> _maybeUnlock(BuildContext ctx) async {
    final needs = widget.passcode;
    if (needs == null) {
      await Backstage.I.setEnabled(true);
      return;
    }
    final ok = await _askPasscode(ctx);
    if (ok) await Backstage.I.setEnabled(true);
  }

  Future<bool> _askPasscode(BuildContext ctx) async {
    final tc = TextEditingController();
    final val = await showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Enter passcode'),
        content: TextField(controller: tc, obscureText: true, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, tc.text),
              child: const Text('Unlock')),
        ],
      ),
    );
    return val == widget.passcode;
  }
}
