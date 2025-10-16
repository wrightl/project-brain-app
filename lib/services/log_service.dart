import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/web.dart';

class LogService extends LogOutput {
  final String _aspireEndpoint =
      'http://localhost:4318/v1/logs'; // Aspire's OpenTelemetry endpoint

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      final logEntry = {
        "resourceLogs": [
          {
            "resource": {
              "attributes": [
                {
                  "key": "service.name",
                  "value": {"stringValue": "flutter-app"}
                }
              ]
            },
            "scopeLogs": [
              {
                "logRecords": [
                  {
                    "timeUnixNano":
                        DateTime.now().microsecondsSinceEpoch * 1000,
                    "severityText": event.level.toString().toUpperCase(),
                    "body": {"stringValue": line}
                  }
                ]
              }
            ]
          }
        ]
      };

      print("${event.level.toString()}: ${line}");

      try {
        // var response = http.post(
        //   Uri.parse(_aspireEndpoint),
        //   headers: {"Content-Type": "application/json"},
        //   body: jsonEncode(logEntry),
        // );

        // if (response.statusCode == 200) {
        //   if (kDebugMode) print("Log sent to Aspire: $message");
        // } else {
        //   if (kDebugMode) print("Failed to send log: ${response.body}");
        // }
      } catch (e) {
        if (kDebugMode) print("Error sending log to Aspire: $e");
      }
    }
  }
}
