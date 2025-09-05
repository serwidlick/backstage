/// UI overlay system and activation controls for the Backstage debugging console.
///
/// This file contains the overlay components that render the debugging console
/// on top of the application UI and the gesture-based activation system that
/// allows users to show/hide the console through hidden interactions.
///
/// Key components:
/// * [BackstageOverlay] - Main overlay wrapper for the entire application
/// * [BackstageEntryGate] - Gesture detection widget for console activation
/// * [_OverlayConsole] - Internal draggable console widget
library;

import 'package:flutter/material.dart';

import 'backstage.dart';
import 'widgets/console_panel.dart';

/// Overlay wrapper that enables the Backstage console to appear over your app.
///
/// [BackstageOverlay] must wrap your entire application to provide the
/// necessary stack context for the debugging console to appear as a floating
/// overlay. The console visibility is controlled by the global Backstage state
/// and responds to user activation gestures.
///
/// **Integration Pattern**: Place this widget as high as possible in your
/// widget tree, typically wrapping your main app widget or MaterialApp.
///
/// **Performance**: The overlay has minimal performance impact when disabled.
/// When enabled, it renders a single console panel that users can interact with.
///
/// **Z-Order**: The console renders above all application content, including
/// dialogs, bottom sheets, and other overlays. This ensures it remains
/// accessible even when the app is in complex UI states.
///
/// Example usage:
/// ```dart
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return BackstageOverlay(
///       child: MaterialApp(
///         home: MyHomePage(),
///       ),
///     );
///   }
/// }
/// ```
///
/// **State Management**: The overlay automatically subscribes to the global
/// Backstage enabled state and shows/hides the console accordingly. No manual
/// state management is required.
class BackstageOverlay extends StatelessWidget {
  /// The application widget tree that should appear beneath the console.
  ///
  /// This is typically your MaterialApp, CupertinoApp, or main application
  /// widget. The console will render as a floating overlay above this content.
  final Widget child;

  /// Creates a new Backstage overlay wrapper.
  ///
  /// The [child] parameter is required and should be your main application
  /// widget. The overlay will render the console above this child when enabled.
  const BackstageOverlay({super.key, required this.child});

  /// Builds the overlay structure with the application content and console.
  ///
  /// Creates a Stack with the application content as the base layer and the
  /// console as a floating overlay. The console visibility is controlled by
  /// a ValueListenableBuilder that responds to global state changes.
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

/// Internal widget that renders the draggable console panel.
///
/// This private widget handles the positioning and drag behavior of the
/// console panel. Users can drag the console around the screen to position
/// it conveniently while debugging.
///
/// **Positioning**: The console starts at a default position (16, 100) and
/// remembers its position during the current session. Position is reset
/// when the console is toggled off and on again.
///
/// **Drag Behavior**: The entire console panel acts as a drag handle,
/// allowing users to reposition it anywhere on screen without interfering
/// with the console's internal controls.
class _OverlayConsole extends StatefulWidget {
  const _OverlayConsole();

  @override
  State<_OverlayConsole> createState() => _OverlayConsoleState();
}

/// State class managing console positioning and drag interactions.
///
/// Handles the draggable behavior of the console panel and maintains
/// its current screen position. The console can be dragged freely
/// around the screen for optimal positioning during debugging sessions.
class _OverlayConsoleState extends State<_OverlayConsole> {
  /// Current position of the console on screen.
  ///
  /// Represents the top-left corner position of the console panel.
  /// Users can modify this by dragging the console around the screen.
  /// Position is maintained for the duration of the console session.
  Offset pos = const Offset(16, 100);

  /// The console panel widget instance.
  ///
  /// Created once during initialization to avoid rebuilding the complex
  /// console UI during drag operations. Contains all the logging display
  /// and filtering functionality.
  late final ConsolePanel _panelWidget;

  /// Initializes the console panel widget.
  ///
  /// Creates the console panel with the global Backstage logger and
  /// prepares it for display. The panel is created once and reused
  /// to maintain efficient rendering during drag operations.
  @override
  void initState() {
    super.initState();
    _panelWidget = ConsolePanel(logger: Backstage.I.logger);
  }

  /// Builds the positioned and draggable console interface.
  ///
  /// Creates a Positioned widget that places the console at the current
  /// [pos] location, wrapped in a GestureDetector for drag handling.
  /// The console can be dragged freely around the screen without
  /// interfering with its internal functionality.
  ///
  /// **Drag Behavior**: The entire console surface acts as a drag handle.
  /// Users can drag from any part of the console to reposition it.
  ///
  /// **Material Design**: Wrapped in a Material widget for proper theming
  /// and elevation effects that integrate well with the app's design system.
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

/// Gesture detection widget that provides hidden console activation.
///
/// [BackstageEntryGate] wraps any widget to add invisible gesture detection
/// that allows users to activate the Backstage console through secret
/// interactions. This is essential for production apps where the console
/// should be hidden from normal users but accessible to developers and
/// support staff.
///
/// **Activation Methods**:
/// * **5 rapid taps**: Tap the wrapped widget 5 times within 2 seconds
/// * **Long press**: Press and hold the wrapped widget
///
/// **Security**: If a passcode is configured, users must enter it after
/// performing the activation gesture to gain access to the console.
///
/// **Typical Usage**: Wrap your app bar, logo, or other appropriate UI
/// element that users won't accidentally trigger but developers can
/// easily remember.
///
/// Example usage:
/// ```dart
/// class MyHomePage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: BackstageEntryGate(
///           passcode: kReleaseMode ? 'debug123' : null,
///           child: Text('My App'),
///         ),
///       ),
///       body: MyContent(),
///     );
///   }
/// }
/// ```
///
/// **Design Considerations**:
/// * Choose wrap targets that are unlikely to be accidentally triggered
/// * Consider the user experience - don't wrap frequently-tapped elements
/// * Ensure the wrapped widget remains fully functional for normal use
class BackstageEntryGate extends StatefulWidget {
  /// The widget to wrap with gesture detection.
  ///
  /// This widget remains fully functional and unmodified for normal user
  /// interactions. The gesture detection is completely transparent and
  /// doesn't interfere with the child's normal behavior.
  final Widget child;

  /// Optional passcode required after gesture activation.
  ///
  /// When provided, users must enter this exact passcode after performing
  /// the activation gesture to enable the console. When null, the console
  /// activates immediately upon gesture completion.
  ///
  /// **Security**: Use a non-obvious passcode in production builds to
  /// prevent unauthorized access to potentially sensitive debug information.
  final String? passcode;

  /// Creates a new gesture detection wrapper.
  ///
  /// The [child] parameter is required and will be wrapped with invisible
  /// gesture detection. The optional [passcode] adds an extra security
  /// layer for production environments.
  const BackstageEntryGate({super.key, required this.child, this.passcode});

  @override
  State<BackstageEntryGate> createState() => _BackstageEntryGateState();
}

/// State class managing gesture detection and activation logic.
///
/// Tracks tap sequences and timing to determine when the activation
/// gesture has been completed. Handles the passcode flow if configured.
class _BackstageEntryGateState extends State<BackstageEntryGate> {
  /// Current count of consecutive taps within the time window.
  ///
  /// Resets to 0 when the time window expires or when the activation
  /// sequence is completed. Must reach 5 for activation.
  int taps = 0;

  /// Timestamp of the most recent tap.
  ///
  /// Used to determine if subsequent taps fall within the 2-second
  /// activation window. Null if no recent taps have occurred.
  DateTime? _last;

  /// Builds the gesture detection wrapper around the child widget.
  ///
  /// Creates a GestureDetector that captures tap and long-press gestures
  /// while allowing the child widget to function normally. The gesture
  /// detection is completely transparent to normal user interactions.
  ///
  /// **Tap Detection**: Counts rapid taps and activates after 5 taps
  /// within a 2-second window. The tap counter resets if the time
  /// window expires.
  ///
  /// **Long Press**: Immediately triggers activation without requiring
  /// multiple taps. Useful for situations where rapid tapping might
  /// be difficult or inappropriate.
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

  /// Handles the activation flow, including passcode verification if required.
  ///
  /// This method is called when the user completes an activation gesture
  /// (either 5 taps or long press). If no passcode is configured, the
  /// console is immediately enabled. Otherwise, a passcode dialog is
  /// shown first.
  ///
  /// Parameters:
  /// * [ctx] - BuildContext for showing the passcode dialog
  ///
  /// **Flow**:
  /// 1. Check if passcode is required
  /// 2. If no passcode: immediately enable console
  /// 3. If passcode required: show dialog and verify
  /// 4. Enable console only if passcode is correct
  Future<void> _maybeUnlock(BuildContext ctx) async {
    final needs = widget.passcode;
    if (needs == null) {
      await Backstage.I.setEnabled(true);
      return;
    }
    final ok = await _askPasscode(ctx);
    if (ok) await Backstage.I.setEnabled(true);
  }

  /// Shows a passcode entry dialog and verifies the entered code.
  ///
  /// Presents a modal dialog with an obscured text field for passcode
  /// entry. The dialog includes cancel and unlock buttons, and the
  /// text field is automatically focused for immediate entry.
  ///
  /// Parameters:
  /// * [ctx] - BuildContext for showing the dialog
  ///
  /// Returns:
  /// * `true` if the entered passcode matches the configured passcode
  /// * `false` if the passcode is incorrect or dialog was cancelled
  ///
  /// **UX Features**:
  /// * Text field is automatically focused for immediate typing
  /// * Input is obscured for security
  /// * Clear cancel/unlock actions
  /// * Modal presentation prevents accidental dismissal
  ///
  /// **Security**: The entered text is compared directly with the
  /// configured passcode. No additional hashing or encoding is performed.
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
