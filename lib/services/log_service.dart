import 'package:flutter/foundation.dart';
import 'package:logger/web.dart';

/// Simple log output service that prints to console
/// TODO: Add remote logging capability if needed
class LogService extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      if (kDebugMode) {
        print("${event.level.toString()}: $line");
      }
    }
  }
}
