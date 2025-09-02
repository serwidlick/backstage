import 'dart:async';

typedef BackstageTag = String;

enum BackstageLevel { debug, info, warn, error }

class BackstageLog {
  final DateTime time;
  final String message;
  final BackstageLevel level;
  final BackstageTag tag;
  final StackTrace? stackTrace;
  BackstageLog({
    required this.message,
    required this.level,
    this.tag = 'app',
    this.stackTrace,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class BackstageLogger {
  final _controller = StreamController<BackstageLog>.broadcast();
  Stream<BackstageLog> get stream => _controller.stream;
  void add(BackstageLog log) => _controller.add(log);

  void d(String msg, {BackstageTag tag = 'app'}) =>
      add(BackstageLog(message: msg, level: BackstageLevel.debug, tag: tag));
  void i(String msg, {BackstageTag tag = 'app'}) =>
      add(BackstageLog(message: msg, level: BackstageLevel.info, tag: tag));
  void w(String msg, {BackstageTag tag = 'app'}) =>
      add(BackstageLog(message: msg, level: BackstageLevel.warn, tag: tag));
  void e(String msg, {BackstageTag tag = 'app', StackTrace? st}) =>
      add(BackstageLog(
          message: msg, level: BackstageLevel.error, tag: tag, stackTrace: st));
}
