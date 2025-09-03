/// Persistent storage functionality for the Backstage debugging console.
///
/// This file provides secure, platform-agnostic storage capabilities for
/// persisting Backstage configuration data across application sessions.
/// Currently handles the enabled/disabled state persistence.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Handles persistent storage of Backstage configuration and state.
///
/// [BackstageStore] provides a simple interface for storing and retrieving
/// Backstage-related data that should persist across application restarts.
/// It uses Flutter's SharedPreferences plugin for platform-appropriate
/// storage mechanisms.
///
/// The store currently manages:
/// * Console enabled/disabled state
/// * Future configuration options (planned)
///
/// Example usage:
/// ```dart
/// final store = BackstageStore();
/// 
/// // Save the current enabled state
/// await store.writeEnabled(true);
/// 
/// // Retrieve the enabled state on app restart
/// final isEnabled = await store.readEnabled() ?? false;
/// ```
///
/// **Thread Safety**: All operations are async and thread-safe as they
/// delegate to the SharedPreferences plugin which handles platform-specific
/// threading requirements.
///
/// **Platform Support**: Supported on all platforms where SharedPreferences
/// is available (iOS, Android, Web, Windows, macOS, Linux).
class BackstageStore {
  /// Storage key for the console enabled state.
  ///
  /// This key is used consistently across all storage operations
  /// to ensure data integrity and avoid conflicts with other
  /// SharedPreferences usage in the host application.
  static const _key = 'backstage.enabled';
  
  /// Retrieves the persisted enabled state from platform storage.
  ///
  /// Returns `true` if the console was previously enabled, `false` if it was
  /// disabled, or `null` if no preference has been stored yet (first run).
  ///
  /// This method is safe to call frequently as SharedPreferences implements
  /// internal caching to minimize platform storage access overhead.
  ///
  /// Returns:
  /// * `true` - Console was previously enabled
  /// * `false` - Console was previously disabled  
  /// * `null` - No preference stored (first run or cleared data)
  ///
  /// Example:
  /// ```dart
  /// final store = BackstageStore();
  /// final enabled = await store.readEnabled();
  /// 
  /// if (enabled == null) {
  ///   // First run - use default configuration
  ///   print('First run detected, using defaults');
  /// } else {
  ///   // Restore previous state
  ///   print('Restoring console state: $enabled');
  /// }
  /// ```
  ///
  /// Throws:
  /// * [PlatformException] if platform storage access fails
  Future<bool?> readEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key);
  }

  /// Persists the console enabled state to platform storage.
  ///
  /// Stores the provided [v] value using platform-appropriate persistence
  /// mechanisms. The stored value will be available in future application
  /// sessions via [readEnabled].
  ///
  /// Parameters:
  /// * [v] - The enabled state to persist (`true` for enabled, `false` for disabled)
  ///
  /// This operation is atomic - either the write succeeds completely or fails
  /// without partially corrupting the stored data.
  ///
  /// Example:
  /// ```dart
  /// final store = BackstageStore();
  /// 
  /// // Enable the console and persist the choice
  /// await store.writeEnabled(true);
  /// print('Console enabled and preference saved');
  /// 
  /// // Later disable and persist
  /// await store.writeEnabled(false);  
  /// print('Console disabled and preference saved');
  /// ```
  ///
  /// Throws:
  /// * [PlatformException] if platform storage write fails
  /// * [StateError] if SharedPreferences instance cannot be obtained
  Future<void> writeEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }
}
