import 'package:shared_preferences/shared_preferences.dart';

class BackstageStore {
  static const _key = 'backstage.enabled';
  Future<bool?> readEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_key);
  }

  Future<void> writeEnabled(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, v);
  }
}
