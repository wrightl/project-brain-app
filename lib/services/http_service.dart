import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:projectbrain/authentication/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HttpService {
  final AuthService authService;
  final String baseUrl = '${dotenv.env['AUTH_AUDIENCE']}';

  HttpService({required this.authService});

  Future<http.Response> get(String path) async {
    final token = await _getToken();
    return http
        .get(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
    )
        .onError((error, stackTrace) {
      print('Error in GET request: $error');
      throw Exception('Failed to fetch data from $path');
    }).catchError((error) {
      print('Caught error in GET request: $error');
      throw Exception('Failed to fetch data from $path');
    });
  }

  Future<http.StreamedResponse> send(String path, String body) async {
    final token = await _getToken();
    final request = http.Request('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(_authHeaders(token))
      ..body = body != null ? body : '';

    return request.send().onError((error, stackTrace) {
      print('Error in POST request: $error');
      throw Exception('Failed to send data to $path');
    }).catchError((error) {
      print('Caught error in POST request: $error');
      throw Exception('Failed to send data to $path');
    });
  }

  Future<http.Response> post(String path, {Object? body}) async {
    final token = await _getToken();
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
      body: body,
    );
  }

  Future<http.Response> put(String path, {Object? body}) async {
    final token = await _getToken();
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
      body: body,
    );
  }

  Future<http.Response> delete(String path) async {
    final token = await _getToken();
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _authHeaders(token),
    );
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<String> _getToken() async {
    final token = await authService.getAccessToken();
    if (token == null) throw Exception('No access token available');
    return token;
  }
}

// // ignore: file_names
// import 'dart:convert';

// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:projectbrain/authentication/auth_provider.dart';
// import 'package:projectbrain/authentication/authentication_bloc.dart';
// import 'package:provider/provider.dart';

// class HttpService {
//   Future<String> getAuthToken() async {
//     final authProvider = Provider.of<AuthProvider>(context);
//     AuthenticationState state = AuthenticationBloc().state;
//     if (state is LoggedIn) {
//       return state.accessToken;
//     } else {
//       throw Exception('User is not logged in');
//     }
//     // final response = await http.post(
//     //   Uri.parse("https://${dotenv.env['AUTH_DOMAIN']}/oauth/token"),
//     //   headers: {
//     //     'Content-Type': 'application/json',
//     //   },
//     //   body: jsonEncode({
//     //     'client_id': dotenv.env['AUTH_CLIENT_ID'],
//     //     'client_secret': dotenv.env['AUTH_CLIENT_SECRET'],
//     //     'audience': dotenv.env['AUTH_AUDIENCE'],
//     //     'grant_type': 'client_credentials',
//     //   }),
//     // );

//     // if (response.statusCode == 200) {
//     //   var body = json.decode(response.body);
//     //   return body['access_token'];
//     // } else {
//     //   print("statusCode: ${response.statusCode}");
//     //   throw ('Failed to get token');
//     // }
//   }
// }
