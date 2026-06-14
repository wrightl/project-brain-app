import 'dart:convert';

import 'package:projectbrain/core/logging/app_logger.dart';
import 'package:projectbrain/models/connection.dart';
import 'package:projectbrain/services/http_service.dart';

/// Service for coach–user connection records.
class ConnectionService extends HttpService {
  ConnectionService({required super.authService});

  /// Fetch paginated connections for the current user.
  Future<List<Connection>> getConnections({
    int page = 1,
    int pageSize = 50,
  }) async {
    logDebug('[ConnectionService] Fetching connections page=$page');

    final response = await get(
      '/connections?page=$page&pageSize=$pageSize',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] ?? data['Items'] ?? [];
      final connections = (items as List)
          .map((item) => Connection.fromJson(item as Map<String, dynamic>))
          .toList();
      logDebug('[ConnectionService] Fetched ${connections.length} connections');
      return connections;
    }

    logError(
      '[ConnectionService] Failed to fetch connections: '
      '${response.statusCode} ${response.reasonPhrase}',
    );
    throw Exception(
      'Failed to fetch connections: ${response.statusCode} ${response.reasonPhrase}',
    );
  }

  /// Accepted connections only (for coach messaging).
  Future<List<Connection>> getAcceptedConnections() async {
    final connections = await getConnections();
    return connections.where((c) => c.isAccepted).toList();
  }

  /// Accepted and pending connections (for network management UI).
  Future<List<Connection>> getActiveConnections() async {
    final connections = await getConnections();
    return connections.where((c) => c.isAccepted || c.isPending).toList();
  }

  /// Remove or cancel a connection.
  Future<void> deleteConnection(String connectionId) async {
    logDebug('[ConnectionService] Deleting connection: $connectionId');

    final response = await delete('/connections/$connectionId');

    if (response.statusCode == 200 ||
        response.statusCode == 204 ||
        response.statusCode == 404) {
      logDebug('[ConnectionService] Connection deleted: $connectionId');
      return;
    }

    logError(
      '[ConnectionService] Failed to delete connection: '
      '${response.statusCode} ${response.reasonPhrase}',
    );
    throw Exception(
      'Failed to delete connection: ${response.statusCode} ${response.reasonPhrase}',
    );
  }

  /// Fetch a single connection by id.
  Future<Connection> getConnectionById(String connectionId) async {
    logDebug('[ConnectionService] Fetching connection: $connectionId');

    final response = await get(
      '/connections/$connectionId',
      useCache: false,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return Connection.fromJson(data);
    }

    logError(
      '[ConnectionService] Failed to fetch connection: '
      '${response.statusCode} ${response.reasonPhrase}',
    );
    throw Exception(
      'Failed to fetch connection: ${response.statusCode} ${response.reasonPhrase}',
    );
  }
}
