import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'capture.dart';
import 'logger.dart';
import 'storage.dart';

class BackstageConfig {
  final bool capturePrint; // intercept print/debugPrint
  final bool captureFlutterErrors; // FlutterError.onError
  final bool captureZoneErrors; // runZonedGuarded wrapper
  final String? passcode; // optional passcode for activation
  final bool enabledByDefault; // if true, starts enabled
  final bool persistEnabled;
  const BackstageConfig({
    this.capturePrint = true,
    this.captureFlutterErrors = true,
    this.captureZoneErrors = false,
    this.passcode,
    this.enabledByDefault = false,
    this.persistEnabled = true,
  });
}

class Backstage {
  static final Backstage _i = Backstage._();
  Backstage._();
  factory Backstage() => _i;
  final _store = BackstageStore();
  final logger = BackstageLogger();
  BackstageConfig _cfg = const BackstageConfig();
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  Future<void> init(BackstageConfig cfg) async {
    _cfg = cfg;
    if (_cfg.persistEnabled) {
      final persisted = await _store.readEnabled();
      enabled.value = persisted ?? _cfg.enabledByDefault;
    } else {
      enabled.value = _cfg.enabledByDefault;
    }
    if (_cfg.capturePrint) Capture.hookPrint(logger);
    if (_cfg.captureFlutterErrors) Capture.hookFlutterErrors(logger);
  }

  /// Wrap your `runApp` inside this if you set `captureZoneErrors: true`.
  T runZoned<T>(T Function() body) {
    if (!_cfg.captureZoneErrors) return body();
    late T result; // capture the non-null result
    runZonedGuarded(() {
      result = body();
    }, (e, st) {
      logger.add(BackstageLog(
        message: e.toString(),
        level: BackstageLevel.error,
        tag: 'zone',
        stackTrace: st,
      ));
    });
    return result;
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    if (_cfg.persistEnabled) {
      await _store.writeEnabled(value);
    }
  }

  bool get isEnabled => enabled.value;

  static Backstage get I => _i;
}
