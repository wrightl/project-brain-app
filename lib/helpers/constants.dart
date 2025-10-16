import 'package:flutter_dotenv/flutter_dotenv.dart';

final AUTH_DOMAIN = dotenv.env['AUTH_DOMAIN']!;
final AUTH_CLIENT_ID = dotenv.env['AUTH_CLIENT_ID']!;
final AUTH_ISSUER = 'https://$AUTH_DOMAIN';
final AUTH_AUDIENCE = dotenv.env['AUTH_AUDIENCE']!;
const BUNDLE_IDENTIFIER = 'com.dotdash.projectbrain';
const AUTH_REDIRECT_URI = '$BUNDLE_IDENTIFIER://login-callback';
const REFRESH_TOKEN_KEY = 'refresh_token';
