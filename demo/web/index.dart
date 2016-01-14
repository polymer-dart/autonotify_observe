import 'package:polymer/init.dart';
import 'package:polymer/polymer.dart';
import "dart:html";
import "package:demo_polymer_autonotify/demo.dart";

import "package:logging/logging.dart";

main() async {
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName} - ${rec.message}');
  });

  await initPolymer();
}
