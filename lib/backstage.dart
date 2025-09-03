/// Backstage: A production-ready in-app debugging console for Flutter.
///
/// Backstage provides a hidden debugging console that can be safely shipped
/// to production. It captures print statements, Flutter framework errors,
/// and custom log entries, making them visible through a gesture-activated
/// overlay that won't interfere with normal app usage.
///
/// **Core Features**:
/// * Hidden activation via gestures (5 taps or long press)
/// * Captures print(), debugPrint(), and Flutter errors
/// * Optional passcode protection for production security
/// * Persistent state across app restarts
/// * Filterable log display with level and tag filtering
/// * Draggable console interface that stays out of the way
///
/// **Quick Setup**:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Initialize Backstage
///   await Backstage().init(BackstageConfig(
///     capturePrint: true,
///     captureFlutterErrors: true,
///     passcode: kReleaseMode ? 'debug123' : null,
///   ));
///   
///   // Wrap your app
///   runApp(MyApp());
/// }
/// 
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return BackstageOverlay(
///       child: MaterialApp(
///         home: BackstageEntryGate(
///           child: MyHomePage(),
///         ),
///       ),
///     );
///   }
/// }
/// ```
///
/// **Main Classes**:
/// * [Backstage] - Core initialization and management
/// * [BackstageConfig] - Configuration options
/// * [BackstageOverlay] - UI overlay wrapper for your app
/// * [BackstageEntryGate] - Gesture activation wrapper
/// * [BackstageLogger] - Direct logging interface
/// * [BackstageLog] - Individual log entry data structure
///
/// **Usage in Production**:
/// * Set a passcode to prevent unauthorized access
/// * Consider disabling enabledByDefault in release builds
/// * Be mindful of captured content containing sensitive data
/// * Test activation gestures work correctly in your UI
///
/// For detailed documentation and examples, see the individual class
/// documentation and the project README.
library backstage;

// Core system and configuration
export 'src/backstage.dart' show Backstage, BackstageConfig;

// Logging system
export 'src/logger.dart'
    show BackstageLog, BackstageLevel, BackstageTag, BackstageLogger;

// UI components
export 'src/overlay.dart' show BackstageOverlay, BackstageEntryGate;
