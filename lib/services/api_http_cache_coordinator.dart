import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/services/http_service.dart';

/// Clears in-memory GET caches on every [HttpService] instance registered here
/// so another account cannot receive cached responses from a previous session.
class ApiHttpCacheCoordinator {
  ApiHttpCacheCoordinator(this._services);

  final List<HttpService> _services;

  void clearAllCaches() {
    for (final s in _services) {
      s.clearCache();
    }
    logDebug(
      '[ApiHttpCacheCoordinator] Cleared HTTP caches on ${_services.length} services',
    );
  }
}
