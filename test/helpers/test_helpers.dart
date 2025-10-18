import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Initialize test environment with mock configuration
Future<void> initializeTestEnvironment() async {
  // Load dotenv with test values (mergeWith allows us to provide values without a file)
  try {
    await dotenv.load(mergeWith: {
      'AUTH_DOMAIN': 'test.auth0.com',
      'AUTH_CLIENT_ID': 'test_client_id',
      'AUTH_CLIENT_SECRET': 'test_client_secret',
      'AUTH_AUDIENCE': 'https://test.example.com',
      'AUTH_REDIRECT': 'http://localhost:6099',
    });
  } catch (e) {
    // If already loaded or file doesn't exist, just add the values
    dotenv.env.addAll({
      'AUTH_DOMAIN': 'test.auth0.com',
      'AUTH_CLIENT_ID': 'test_client_id',
      'AUTH_CLIENT_SECRET': 'test_client_secret',
      'AUTH_AUDIENCE': 'https://test.example.com',
      'AUTH_REDIRECT': 'http://localhost:6099',
    });
  }
}

/// Reset test environment (useful for tearDown)
void resetTestEnvironment() {
  // No-op for now - clearing might affect other tests
  // dotenv persists across tests which is actually what we want
}
