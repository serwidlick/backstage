/// Interactive console panel widget for displaying and filtering log entries.
///
/// This file contains the main UI components for the Backstage debugging console,
/// including log display, filtering controls, and interactive features that allow
/// developers to efficiently browse and analyze captured log data.
///
/// The console provides:
/// * Real-time log entry display with automatic scrolling
/// * Filtering by log level and tag
/// * Pause/resume functionality for detailed inspection
/// * Clear log history action
/// * Visual indicators for different log levels
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../backstage.dart';

/// Main console panel widget that displays log entries with filtering controls.
///
/// [ConsolePanel] provides a comprehensive interface for viewing and interacting
/// with captured log data. It automatically scrolls to show the latest entries,
/// supports filtering by level and tag, and includes controls for managing
/// the log display.
///
/// **Features**:
/// * **Real-time Updates**: Automatically displays new log entries as they arrive
/// * **Auto-scroll**: Keeps the most recent entries visible
/// * **Level Filtering**: Show only logs at or above a selected severity level
/// * **Tag Filtering**: Filter entries by tag substring matching
/// * **Pause/Resume**: Temporarily stop new entries for detailed inspection
/// * **Clear History**: Remove all displayed log entries
///
/// **Performance**: The console efficiently handles moderate log volumes.
/// For extremely high-volume logging, consider using the pause functionality
/// to prevent UI performance issues.
///
/// **Visual Design**: Follows Material Design principles and adapts to the
/// app's theme for consistent appearance.
class ConsolePanel extends StatefulWidget {
  /// The logger instance whose stream will be displayed.
  ///
  /// The console subscribes to this logger's stream and displays all
  /// log entries that are emitted. Typically this is the global
  /// Backstage logger instance.
  final BackstageLogger logger;

  /// Creates a new console panel for the specified logger.
  ///
  /// The [logger] parameter is required and determines which log stream
  /// will be displayed in this console instance.
  const ConsolePanel({super.key, required this.logger});

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

/// State class managing console display, filtering, and user interactions.
///
/// Handles the complex state management required for the console including
/// log entry collection, filtering logic, scroll management, and user
/// interface controls.
class _ConsolePanelState extends State<ConsolePanel> {
  /// Complete list of all received log entries.
  ///
  /// This list grows as new entries arrive and is only cleared when
  /// the user explicitly clears the console. Filtered views are
  /// derived from this master list.
  final _logs = <BackstageLog>[];

  /// Subscription to the logger's stream for receiving new log entries.
  ///
  /// Automatically receives and processes new log entries from the
  /// logger. Cancelled when the console is disposed.
  late StreamSubscription _sub;

  /// Minimum log level filter for display.
  ///
  /// When set, only log entries at or above this level are shown.
  /// When null, all log levels are displayed.
  BackstageLevel? _minLevel;

  /// Text filter for log tags.
  ///
  /// When non-empty, only log entries whose tags contain this
  /// substring are displayed. Case-sensitive matching.
  String _tagFilter = '';

  /// Whether new log entry processing is paused.
  ///
  /// When true, new log entries from the stream are ignored,
  /// allowing users to examine existing entries without
  /// constant updates disrupting their inspection.
  bool _paused = false;

  /// Scroll controller for the log entry list.
  ///
  /// Used to automatically scroll to the bottom when new entries
  /// arrive, keeping the most recent entries visible.
  final _scroll = ScrollController();

  /// Initializes the console by subscribing to the logger stream.
  ///
  /// Sets up the stream subscription to receive new log entries and
  /// automatically update the display. New entries are only processed
  /// when the console is not paused.
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

  /// Cleans up resources when the console is destroyed.
  ///
  /// Cancels the logger stream subscription and disposes of the
  /// scroll controller to prevent memory leaks.
  @override
  void dispose() {
    _sub.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Automatically scrolls to the bottom to show the latest log entries.
  ///
  /// Uses a post-frame callback to ensure the scroll happens after
  /// the widget tree has been updated with new content. Only scrolls
  /// if the scroll controller has active clients.
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
