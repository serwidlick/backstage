import 'package:backstage/backstage.dart';
import 'package:flutter/material.dart';

void main() {
  // Capture zone errors too
  Backstage.I.runZoned(() {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Backstage.I.init(const BackstageConfig(
        passcode: '1234',
        capturePrint: true,
        captureFlutterErrors: true,
        captureZoneErrors: true,
        enabledByDefault: false,
        persistEnabled: false,
      )),
      builder: (_, __) => const MaterialApp(
        home: BackstageOverlay(
          child: DemoHome(),
        ),
      ),
    );
  }
}

class DemoHome extends StatelessWidget {
  const DemoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final log = Backstage.I.logger;
    return Scaffold(
      appBar: AppBar(title: const Text('Backstage Demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BackstageEntryGate(
              passcode: '1234',
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.transparent,
                child:
                    const Text('Tap 5× or long-press here to open Backstage'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                log.d('Debug message', tag: 'demo');
                log.i('Informational event', tag: 'demo');
                log.w('Heads up', tag: 'demo');
                try {
                  throw Exception('Boom');
                } catch (e, st) {
                  log.e(e.toString(), tag: 'demo', st: st);
                }
                debugPrint('Hello from debugPrint');
              },
              child: const Text('Emit sample logs'),
            ),
          ],
        ),
      ),
    );
  }
}
