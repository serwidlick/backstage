import 'package:flutter/foundation.dart';

import 'logger.dart';

class Capture {
  static void hookPrint(BackstageLogger logger) {
    final original = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logger.add(BackstageLog(
            message: message, level: BackstageLevel.debug, tag: 'print'));
      }
      original(message, wrapWidth: wrapWidth);
    };
  }

  static void hookFlutterErrors(BackstageLogger logger) {
    final prev = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      logger.add(BackstageLog(
        message: details.exceptionAsString(),
        level: BackstageLevel.error,
        tag: 'flutter',
        stackTrace: details.stack,
      ));
      prev?.call(details);
    };
  }
}
