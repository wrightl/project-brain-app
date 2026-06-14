import 'dart:io';
import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/core/config/app_config.dart';

/// Custom HTTP overrides for development SSL certificate handling
///
/// WARNING: This should ONLY be used in local development environments
/// where you're connecting to localhost with self-signed certificates.
/// NEVER use this in production or staging environments.
class DevelopmentHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only bypass certificate validation for localhost in debug mode
        if (AppConfig.isLocalDevelopment && host == 'localhost') {
          logDebug(
              '[HttpOverrides] Bypassing certificate validation for localhost:$port');
          return true;
        }

        // For all other cases, use default certificate validation
        return false;
      };
  }
}

/// Initialize HTTP overrides if needed
void initializeHttpOverrides() {
  if (AppConfig.isLocalDevelopment) {
    logDebug(
        '[HttpOverrides] Initializing development HTTP overrides for localhost');
    HttpOverrides.global = DevelopmentHttpOverrides();
  } else {
    logDebug(
        '[HttpOverrides] Using default certificate validation (production mode)');
  }
}
