/// Visual theming and appearance configuration.
///
/// This file defines configuration options for customizing the visual
/// appearance of the Backstage debugging console, including colors,
/// typography, spacing, and component styling.
library;

import 'package:flutter/material.dart';

/// Configuration options for console visual theming and appearance.
///
/// [ThemeConfig] provides comprehensive control over the visual styling
/// of the debugging console, allowing customization to match application
/// design systems or organizational branding requirements.
///
/// **Theme Integration**:
/// * Respects system light/dark mode preferences
/// * Integrates with Flutter Material Design theming
/// * Supports custom color schemes and typography
/// * Maintains accessibility standards
///
/// **Customization Levels**:
/// * **System**: Follow device theme settings
/// * **Material**: Use Material Design defaults
/// * **Custom**: Full control over appearance
/// * **Brand**: Align with organizational branding
///
/// Example configurations:
/// ```dart
/// // System-integrated theme (follows device preferences)
/// const systemConfig = ThemeConfig(
///   followSystemTheme: true,
///   respectMaterialTheme: true,
/// );
///
/// // Custom branded theme
/// const brandConfig = ThemeConfig(
///   primaryColor: Color(0xFF2196F3), // Company blue
///   backgroundColor: Color(0xFF121212), // Dark background
///   textColor: Color(0xFFFFFFFF), // White text
///   fontFamily: 'Roboto',
///   borderRadius: 12.0,
/// );
/// ```
class ThemeConfig {
  /// Whether to follow the system light/dark theme preference.
  ///
  /// When enabled, the console will automatically switch between
  /// light and dark themes based on the device's system settings.
  /// This provides consistent theming with the user's preferences.
  ///
  /// **Default**: `true`
  /// **UX**: Consistent with user's system preferences
  final bool followSystemTheme;

  /// Whether to respect the application's Material theme.
  ///
  /// When enabled, the console will inherit colors, typography,
  /// and styling from the application's Material theme. This
  /// provides visual consistency with the host application.
  ///
  /// **Default**: `true`
  /// **Consistency**: Visual integration with host application
  final bool respectMaterialTheme;

  /// Primary color for console UI elements.
  ///
  /// Used for accent elements, highlights, active states, and
  /// primary actions within the console interface. Should provide
  /// good contrast against the background color.
  ///
  /// **Default**: `null` (use Material theme primary color)
  /// **Branding**: Align with organizational color scheme
  final Color? primaryColor;

  /// Background color for the main console surface.
  ///
  /// The base color for the console panel and dialog backgrounds.
  /// Should provide good readability for text content and appropriate
  /// contrast for UI elements.
  ///
  /// **Default**: `null` (use Material theme surface color)
  /// **Accessibility**: Ensure adequate contrast ratios
  final Color? backgroundColor;

  /// Background color for the console surface container.
  ///
  /// Used for elevated surfaces within the console such as cards,
  /// dialogs, and panels. Typically slightly different from the
  /// main background to provide visual hierarchy.
  ///
  /// **Default**: `null` (use Material theme surfaceVariant)
  /// **Hierarchy**: Visual distinction for layered interfaces
  final Color? surfaceColor;

  /// Primary text color for console content.
  ///
  /// Used for main content text, log messages, and primary
  /// information display. Must provide excellent readability
  /// against the background color.
  ///
  /// **Default**: `null` (use Material theme onSurface color)
  /// **Accessibility**: Meet WCAG contrast requirements
  final Color? textColor;

  /// Secondary text color for less prominent content.
  ///
  /// Used for timestamps, metadata, secondary information,
  /// and supporting text elements. Should be readable but
  /// less prominent than primary text.
  ///
  /// **Default**: `null` (use Material theme onSurfaceVariant)
  /// **Hierarchy**: Visual distinction for secondary content
  final Color? secondaryTextColor;

  /// Color for error-level log entries and error states.
  ///
  /// Used to highlight errors, critical issues, and failure
  /// states within the console. Should be attention-grabbing
  /// while maintaining readability.
  ///
  /// **Default**: `null` (use Material theme error color)
  /// **Attention**: Clear indication of error conditions
  final Color? errorColor;

  /// Color for warning-level log entries and warning states.
  ///
  /// Used to highlight warnings, potential issues, and
  /// caution states within the console. Should indicate
  /// concern without being as severe as error color.
  ///
  /// **Default**: `null` (use Material theme onErrorContainer)
  /// **Caution**: Indicate potential issues requiring attention
  final Color? warningColor;

  /// Color for success states and positive feedback.
  ///
  /// Used to indicate successful operations, positive states,
  /// and confirmation feedback within the console interface.
  ///
  /// **Default**: `null` (use green from Material theme)
  /// **Feedback**: Positive reinforcement for successful actions
  final Color? successColor;

  /// Color for informational log entries and neutral states.
  ///
  /// Used for general information, status updates, and
  /// neutral feedback that doesn't require special attention
  /// but provides useful context.
  ///
  /// **Default**: `null` (use Material theme primary color)
  /// **Information**: Neutral informational content
  final Color? infoColor;

  /// Font family for console text content.
  ///
  /// The primary font family used throughout the console interface.
  /// Consider using monospace fonts for log content to improve
  /// alignment and readability of structured data.
  ///
  /// **Default**: `null` (use Material theme text font)
  /// **Readability**: Choose fonts optimized for debugging content
  final String? fontFamily;

  /// Font family specifically for log content display.
  ///
  /// Monospace font used for log messages, stack traces, and
  /// other debugging content where character alignment and
  /// consistent spacing improve readability.
  ///
  /// **Default**: `'monospace'`
  /// **Alignment**: Consistent character spacing for structured data
  final String logFontFamily;

  /// Base font size for console text content.
  ///
  /// The standard text size used throughout the console interface.
  /// Should balance readability with information density based
  /// on typical viewing conditions and screen sizes.
  ///
  /// **Default**: `14.0`
  /// **Readability**: Balance information density with legibility
  final double fontSize;

  /// Font size specifically for log content display.
  ///
  /// Text size for log messages, which may need to be smaller
  /// or larger than standard UI text depending on information
  /// density requirements and debugging workflows.
  ///
  /// **Default**: `12.0`
  /// **Density**: Optimize for debugging content readability
  final double logFontSize;

  /// Border radius for console UI elements.
  ///
  /// Consistent border radius applied to console panels, buttons,
  /// input fields, and other UI elements to create a cohesive
  /// visual style that matches application design patterns.
  ///
  /// **Default**: `8.0`
  /// **Consistency**: Cohesive visual style throughout interface
  final double borderRadius;

  /// Elevation for the main console panel.
  ///
  /// Material elevation applied to the console panel to create
  /// visual hierarchy and ensure it appears above application
  /// content. Higher values create more prominent shadows.
  ///
  /// **Default**: `8.0`
  /// **Hierarchy**: Visual prominence over application content
  final double panelElevation;

  /// Opacity for the console panel background.
  ///
  /// Controls transparency of the console panel, allowing some
  /// visibility of underlying application content. Lower values
  /// increase transparency but may reduce readability.
  ///
  /// **Default**: `0.95` (95% opaque)
  /// **Balance**: Visibility vs readability trade-off
  final double panelOpacity;

  /// Padding inside console UI elements.
  ///
  /// Standard padding applied inside buttons, input fields,
  /// and other interactive elements to provide appropriate
  /// touch targets and visual breathing room.
  ///
  /// **Default**: `EdgeInsets.all(8.0)`
  /// **Usability**: Adequate touch targets and visual spacing
  final EdgeInsets elementPadding;

  /// Padding around log entries in the console display.
  ///
  /// Spacing around individual log entries to improve readability
  /// and visual separation between entries. Should balance
  /// information density with visual clarity.
  ///
  /// **Default**: `EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0)`
  /// **Readability**: Visual separation between log entries
  final EdgeInsets logEntryPadding;

  /// Whether to show dividers between log entries.
  ///
  /// Visual separators between log entries can improve readability
  /// and scanning but may create visual clutter with dense logs.
  /// Consider based on typical log density and user preferences.
  ///
  /// **Default**: `false`
  /// **Clarity**: Visual separation vs information density
  final bool showLogDividers;

  /// Color for dividers between log entries.
  ///
  /// Subtle line color used to separate log entries when
  /// [showLogDividers] is enabled. Should provide gentle
  /// separation without creating visual distraction.
  ///
  /// **Default**: `null` (use Material theme dividerColor)
  /// **Subtlety**: Gentle separation without visual interference
  final Color? dividerColor;

  /// Animation duration for theme transitions.
  ///
  /// Duration of color and style transitions when switching
  /// between themes or updating appearance. Smooth transitions
  /// improve user experience during theme changes.
  ///
  /// **Default**: `Duration(milliseconds: 300)`
  /// **UX**: Smooth visual transitions during theme changes
  final Duration animationDuration;

  /// Custom color scheme for specific log levels.
  ///
  /// Map of log level names to colors for custom highlighting
  /// of different types of log entries. Allows fine-grained
  /// control over visual distinction between log categories.
  ///
  /// **Default**: `{}` (use default level colors)
  /// **Customization**: Fine-grained control over log appearance
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'debug': Colors.grey,
  ///   'info': Colors.blue,
  ///   'warn': Colors.orange,
  ///   'error': Colors.red,
  ///   'critical': Colors.purple,
  /// }
  /// ```
  final Map<String, Color> levelColors;

  /// Custom icon set for different log levels.
  ///
  /// Map of log level names to icons for visual indication
  /// of log entry types. Icons should be recognizable and
  /// consistent with the application's icon style.
  ///
  /// **Default**: `{}` (use default level icons)
  /// **Recognition**: Visual categorization of log entries
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'debug': Icons.bug_report,
  ///   'info': Icons.info_outline,
  ///   'warn': Icons.warning_amber,
  ///   'error': Icons.error_outline,
  /// }
  /// ```
  final Map<String, IconData> levelIcons;

  /// Creates a new theme configuration with the specified options.
  ///
  /// All parameters are optional and have sensible defaults that integrate
  /// well with Material Design and system themes. Customize based on your
  /// application's visual design requirements and branding guidelines.
  ///
  /// Example:
  /// ```dart
  /// const config = ThemeConfig(
  ///   followSystemTheme: true,
  ///   respectMaterialTheme: true,
  ///   primaryColor: Color(0xFF2196F3),
  ///   logFontFamily: 'Monaco', // Custom monospace font
  ///   fontSize: 14.0,
  ///   logFontSize: 12.0,
  ///   borderRadius: 12.0,
  ///   panelOpacity: 0.98,
  /// );
  /// ```
  const ThemeConfig({
    this.followSystemTheme = true,
    this.respectMaterialTheme = true,
    this.primaryColor,
    this.backgroundColor,
    this.surfaceColor,
    this.textColor,
    this.secondaryTextColor,
    this.errorColor,
    this.warningColor,
    this.successColor,
    this.infoColor,
    this.fontFamily,
    this.logFontFamily = 'monospace',
    this.fontSize = 14.0,
    this.logFontSize = 12.0,
    this.borderRadius = 8.0,
    this.panelElevation = 8.0,
    this.panelOpacity = 0.95,
    this.elementPadding = const EdgeInsets.all(8.0),
    this.logEntryPadding = const EdgeInsets.symmetric(
      horizontal: 12.0,
      vertical: 4.0,
    ),
    this.showLogDividers = false,
    this.dividerColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.levelColors = const {},
    this.levelIcons = const {},
  });
}
