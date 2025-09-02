import 'dart:async';

import 'package:flutter/material.dart';

import '../../backstage.dart';

class ConsolePanel extends StatefulWidget {
  final BackstageLogger logger;
  const ConsolePanel({super.key, required this.logger});
  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final _logs = <BackstageLog>[];
  late StreamSubscription _sub;
  BackstageLevel? _minLevel;
  String _tagFilter = '';
  bool _paused = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _sub = widget.logger.stream.listen((e) {
      if (_paused) return;
      setState(() {
        _logs.add(e);
      });
      _scrollJump();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollJump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _logs
        .where((l) =>
            (_minLevel == null || l.level.index >= _minLevel!.index) &&
            (_tagFilter.isEmpty || l.tag.contains(_tagFilter)))
        .toList();
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: 340,
        height: 280,
        color: theme.colorScheme.surface,
        child: Column(children: [
          _toolbar(theme),
          const Divider(height: 1),
          Expanded(
              child: ListView.builder(
            controller: _scroll,
            itemCount: filtered.length,
            itemBuilder: (_, i) => _logTile(filtered[i], theme),
          )),
        ]),
      ),
    );
  }

  Widget _toolbar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 40,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(children: [
        IconButton(
            tooltip: 'Pause/Resume',
            onPressed: () => setState(() => _paused = !_paused),
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause)),
        IconButton(
            tooltip: 'Clear',
            onPressed: () => setState(() => _logs.clear()),
            icon: const Icon(Icons.delete_forever)),
        const SizedBox(width: 8),
        DropdownButton<BackstageLevel?>(
          value: _minLevel,
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(
                value: BackstageLevel.debug, child: Text('≥ debug')),
            DropdownMenuItem(value: BackstageLevel.info, child: Text('≥ info')),
            DropdownMenuItem(value: BackstageLevel.warn, child: Text('≥ warn')),
            DropdownMenuItem(
                value: BackstageLevel.error, child: Text('≥ error')),
          ],
          onChanged: (v) => setState(() => _minLevel = v),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: TextField(
          decoration:
              const InputDecoration(isDense: true, hintText: 'Filter by tag'),
          onChanged: (s) => setState(() => _tagFilter = s.trim()),
        )),
        IconButton(
            tooltip: 'Close',
            onPressed: () => Backstage.I.setEnabled(false),
            icon: const Icon(Icons.close)),
      ]),
    );
  }

  Widget _logTile(BackstageLog l, ThemeData theme) {
    IconData icon;
    Color? color;
    switch (l.level) {
      case BackstageLevel.debug:
        icon = Icons.bug_report;
        break;
      case BackstageLevel.info:
        icon = Icons.info_outline;
        break;
      case BackstageLevel.warn:
        icon = Icons.warning_amber_rounded;
        color = Colors.amber;
        break;
      case BackstageLevel.error:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(l.message, maxLines: 4, overflow: TextOverflow.ellipsis),
      subtitle: Text('${l.time.toIso8601String()} • ${l.tag}'),
      trailing: Text(l.level.name),
    );
  }
}
