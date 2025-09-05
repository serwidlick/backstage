/// User interface layout and behavior configuration.
///
/// This file defines configuration options for the console user interface
/// including layout preferences, interaction modes, view options, and
/// accessibility features.
library;

import 'package:flutter/material.dart';

/// Console layout modes for different screen sizes and use cases.
enum ConsoleLayout {
  /// Compact single-panel layout for mobile devices
  compact,

  /// Expandable layout that can grow based on content
  expandable,

  /// Multi-tab layout for organizing different data types
  tabbed,

  /// Side-by-side panel layout for desktop/tablet
  sideBySide,

  /// Full-screen overlay for detailed analysis
  fullScreen,
}

/// Default console position on screen.
enum DefaultPosition {
  /// Top-left corner of the screen
  topLeft,

  /// Top-right corner of the screen
  topRight,

  /// Bottom-left corner of the screen
  bottomLeft,

  /// Bottom-right corner of the screen
  bottomRight,

  /// Center of the screen
  center,

  /// Remember last user-positioned location
  lastPosition,
}

/// Configuration options for console user interface and behavior.
///
/// [UIConfig] provides comprehensive control over the console's user
/// interface layout, interaction modes, accessibility features, and
/// behavioral characteristics to optimize the debugging experience
/// across different platforms and use cases.
///
/// **Layout Adaptivity**:
/// * Responsive design for different screen sizes
/// * Platform-specific optimizations (mobile, desktop, web)
/// * Accessibility compliance and customization
/// * Performance-conscious rendering options
///
/// **Interaction Modes**:
/// * Touch-optimized for mobile platforms
/// * Mouse/keyboard optimized for desktop
/// * Gesture support for modern interfaces
/// * Customizable shortcuts and commands
///
/// Example configurations:
/// ```dart
/// // Mobile-optimized configuration
/// const mobileConfig = UIConfig(
///   layout: ConsoleLayout.compact,
///   defaultPosition: DefaultPosition.bottomRight,
///   enableGestures: true,
///   minPanelWidth: 280,
///   maxPanelWidth: double.infinity,
/// );
///
/// // Desktop-optimized configuration
/// const desktopConfig = UIConfig(
///   layout: ConsoleLayout.tabbed,
///   defaultPosition: DefaultPosition.topRight,
///   enableKeyboardShortcuts: true,
///   minPanelWidth: 400,
///   maxPanelWidth: 800,
///   showResizeHandles: true,
/// );
/// ```
class UIConfig {
  /// Primary layout mode for the console interface.
  ///
  /// Determines the overall structure and organization of the console
  /// interface. Different layouts are optimized for different screen
  /// sizes, use cases, and interaction patterns.
  ///
  /// **Default**: `ConsoleLayout.expandable`
  /// **Adaptivity**: Choose based on target platform and screen size
  final ConsoleLayout layout;

  /// Default position for the console panel on screen.
  ///
  /// Where the console should initially appear when activated.
  /// Some positions may be automatically adjusted based on screen
  /// size and safe areas to ensure full visibility.
  ///
  /// **Default**: `DefaultPosition.topRight`
  /// **UX**: Balance accessibility with content obstruction
  final DefaultPosition defaultPosition;

  /// Minimum width for the console panel in logical pixels.
  ///
  /// Prevents the console from becoming too narrow to be usable.
  /// Should accommodate the minimum content width needed for
  /// effective debugging while considering mobile screen constraints.
  ///
  /// **Default**: `320.0`
  /// **Usability**: Ensure minimum viable debugging interface width
  final double minPanelWidth;

  /// Maximum width for the console panel in logical pixels.
  ///
  /// Prevents the console from becoming excessively wide on large
  /// screens. Set to double.infinity to allow unlimited expansion
  /// or constrain based on optimal reading width.
  ///
  /// **Default**: `600.0`
  /// **Readability**: Prevent excessively wide text columns
  final double maxPanelWidth;

  /// Minimum height for the console panel in logical pixels.
  ///
  /// Ensures the console shows enough content to be useful while
  /// preventing it from becoming too small to interact with effectively.
  /// Consider toolbar height and minimum log entry visibility.
  ///
  /// **Default**: `200.0`
  /// **Utility**: Show meaningful amount of debugging information
  final double minPanelHeight;

  /// Maximum height for the console panel in logical pixels.
  ///
  /// Prevents the console from obscuring too much application content.
  /// Set to double.infinity for unlimited expansion or constrain
  /// based on typical screen usage patterns.
  ///
  /// **Default**: `400.0`
  /// **Balance**: Debugging utility vs application content visibility
  final double maxPanelHeight;

  /// Whether the console panel can be resized by the user.
  ///
  /// Enables resize handles on the console panel allowing users to
  /// adjust size based on their debugging needs and screen real estate.
  /// Particularly useful on desktop and tablet platforms.
  ///
  /// **Default**: `true`
  /// **Flexibility**: User control over interface sizing
  final bool isResizable;

  /// Whether to show visual resize handles on the console panel.
  ///
  /// Makes resize functionality more discoverable by showing explicit
  /// resize handles. May be unnecessary on touch platforms where
  /// gestures are more natural than visual affordances.
  ///
  /// **Default**: `false` (rely on edge detection)
  /// **Discoverability**: Balance visual clarity with interface clutter
  final bool showResizeHandles;

  /// Whether the console can be minimized to save screen space.
  ///
  /// Allows users to collapse the console to a minimal state (toolbar
  /// only or small icon) while keeping it available for quick access.
  /// Useful for maintaining debugging capability without screen obstruction.
  ///
  /// **Default**: `true`
  /// **Efficiency**: Preserve screen real estate when not actively debugging
  final bool canMinimize;

  /// Whether the console should start in minimized state.
  ///
  /// When enabled, the console will initially appear in its minimized
  /// form until the user explicitly expands it. Reduces initial
  /// screen obstruction while maintaining quick access.
  ///
  /// **Default**: `false`
  /// **UX**: Balance immediate utility with screen real estate
  final bool startMinimized;

  /// Whether to enable gesture-based interactions.
  ///
  /// Enables swipe, pinch, and other gesture controls for console
  /// interaction. Particularly useful on touch platforms but may
  /// conflict with application gestures if not carefully implemented.
  ///
  /// **Default**: `true`
  /// **Touch UX**: Natural interaction patterns for mobile platforms
  final bool enableGestures;

  /// Whether to enable keyboard shortcuts for console control.
  ///
  /// Provides keyboard shortcuts for common actions like toggle,
  /// clear, export, and navigation. Most useful on desktop platforms
  /// with physical keyboards.
  ///
  /// **Default**: `false`
  /// **Desktop UX**: Efficient keyboard-driven workflow
  final bool enableKeyboardShortcuts;

  /// Whether to show a floating action button for quick console access.
  ///
  /// Displays a small floating button that provides quick access to
  /// console functions without requiring the full activation gesture.
  /// Can be positioned and styled to minimize interference.
  ///
  /// **Default**: `false`
  /// **Accessibility**: Alternative activation method for users with mobility issues
  final bool showFloatingActionButton;

  /// Position for the floating action button.
  ///
  /// Where to place the floating action button when enabled.
  /// Should avoid interference with application UI while remaining
  /// easily accessible for debugging purposes.
  ///
  /// **Default**: `FloatingActionButtonLocation.miniEndFloat`
  /// **Positioning**: Balance accessibility with UI interference
  final FloatingActionButtonLocation floatingButtonPosition;

  /// Whether to automatically hide the console when app loses focus.
  ///
  /// Hides the console when the application goes to background or
  /// loses focus, preventing debugging information from being visible
  /// in app switchers or screenshots. Security and privacy benefit.
  ///
  /// **Default**: `true`
  /// **Privacy**: Prevent debugging info exposure in app switchers
  final bool autoHideOnFocusLoss;

  /// Whether to show entry animations when console appears/disappears.
  ///
  /// Smooth animations for console transitions improve user experience
  /// and provide visual feedback for state changes. May be disabled
  /// for performance reasons or user preference.
  ///
  /// **Default**: `true`
  /// **Polish**: Smooth visual transitions improve perceived quality
  final bool enableAnimations;

  /// Duration for console show/hide animations.
  ///
  /// How long console appearance transitions should take. Longer
  /// animations feel more polished but may slow down debugging
  /// workflow. Balance responsiveness with visual quality.
  ///
  /// **Default**: `Duration(milliseconds: 250)`
  /// **Responsiveness**: Balance animation polish with workflow speed
  final Duration animationDuration;

  /// Whether to maintain console state across app lifecycle changes.
  ///
  /// Preserves console position, size, and visibility state when
  /// the app is backgrounded and restored. Improves debugging
  /// continuity but uses additional storage and memory.
  ///
  /// **Default**: `true`
  /// **Continuity**: Preserve debugging context across sessions
  final bool persistUIState;

  /// Whether to adapt layout automatically based on screen orientation.
  ///
  /// Automatically adjusts console layout and sizing when device
  /// orientation changes. Optimizes space usage and readability
  /// for both portrait and landscape orientations.
  ///
  /// **Default**: `true`
  /// **Adaptivity**: Optimize layout for different orientations
  final bool adaptToOrientation;

  /// Whether to respect system accessibility settings.
  ///
  /// Adapts console interface to system accessibility preferences
  /// including text scaling, contrast preferences, and animation
  /// settings. Essential for inclusive debugging experience.
  ///
  /// **Default**: `true`
  /// **Accessibility**: Support users with diverse accessibility needs
  final bool respectAccessibilitySettings;

  /// Semantic labels for screen reader accessibility.
  ///
  /// Map of UI element identifiers to semantic labels for screen
  /// readers and other assistive technologies. Improves debugging
  /// accessibility for visually impaired developers.
  ///
  /// **Default**: `{}` (use default labels)
  /// **Inclusion**: Support developers using assistive technologies
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'console_panel': 'Debugging console panel',
  ///   'log_entry': 'Log entry',
  ///   'clear_button': 'Clear all log entries',
  ///   'export_button': 'Export log data',
  /// }
  /// ```
  final Map<String, String> semanticLabels;

  /// Custom toolbar actions to add to the console interface.
  ///
  /// Additional buttons or controls to include in the console toolbar.
  /// Allows extension of console functionality with application-specific
  /// debugging tools or integrations.
  ///
  /// **Default**: `[]` (no custom actions)
  /// **Extensibility**: Application-specific debugging tools
  final List<Widget> customToolbarActions;

  /// Whether to show performance metrics overlay within console.
  ///
  /// Displays real-time performance information (FPS, memory usage)
  /// as an overlay within the console interface. Useful for monitoring
  /// performance impact of debugging activities.
  ///
  /// **Default**: `false`
  /// **Monitoring**: Track debugging overhead and system performance
  final bool showPerformanceOverlay;

  /// Whether to enable developer mode features.
  ///
  /// Unlocks advanced features, experimental options, and detailed
  /// technical information that may be useful for package developers
  /// or advanced users but could overwhelm typical debugging workflows.
  ///
  /// **Default**: `false`
  /// **Advanced**: Additional features for experienced users
  final bool enableDeveloperMode;

  /// Elevation for the console panel.
  ///
  /// The Material Design elevation value for the console panel.
  /// Higher values create more prominent shadows.
  ///
  /// **Default**: `8.0`
  final double? panelElevation;

  /// Border radius for the console panel.
  ///
  /// Corner radius in logical pixels for the console panel.
  /// Set to 0 for sharp corners or higher values for rounded corners.
  ///
  /// **Default**: `12.0`
  final double? borderRadius;

  /// Opacity for the console panel background.
  ///
  /// Controls the transparency of the console panel background.
  /// Range from 0.0 (fully transparent) to 1.0 (fully opaque).
  ///
  /// **Default**: `0.95`
  final double? panelOpacity;

  /// Creates a new UI configuration with the specified options.
  ///
  /// All parameters are optional and have balanced defaults that provide
  /// good user experience across platforms while maintaining debugging
  /// effectiveness. Customize based on your specific UI requirements.
  ///
  /// Example:
  /// ```dart
  /// const config = UIConfig(
  ///   layout: ConsoleLayout.tabbed,
  ///   defaultPosition: DefaultPosition.topRight,
  ///   minPanelWidth: 350,
  ///   maxPanelWidth: 700,
  ///   isResizable: true,
  ///   enableKeyboardShortcuts: true,
  ///   enableGestures: true,
  ///   respectAccessibilitySettings: true,
  /// );
  /// ```
  const UIConfig({
    this.layout = ConsoleLayout.expandable,
    this.defaultPosition = DefaultPosition.topRight,
    this.minPanelWidth = 320.0,
    this.maxPanelWidth = 600.0,
    this.minPanelHeight = 200.0,
    this.maxPanelHeight = 400.0,
    this.isResizable = true,
    this.showResizeHandles = false,
    this.canMinimize = true,
    this.startMinimized = false,
    this.enableGestures = true,
    this.enableKeyboardShortcuts = false,
    this.showFloatingActionButton = false,
    this.floatingButtonPosition = FloatingActionButtonLocation.miniEndFloat,
    this.autoHideOnFocusLoss = true,
    this.enableAnimations = true,
    this.animationDuration = const Duration(milliseconds: 250),
    this.persistUIState = true,
    this.adaptToOrientation = true,
    this.respectAccessibilitySettings = true,
    this.semanticLabels = const {},
    this.customToolbarActions = const [],
    this.showPerformanceOverlay = false,
    this.enableDeveloperMode = false,
    this.panelElevation = 8.0,
    this.borderRadius = 12.0,
    this.panelOpacity = 0.95,
  });
}
