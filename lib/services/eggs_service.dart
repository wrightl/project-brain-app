// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:logger/logger.dart';
// import 'package:projectbrain/eggs/domain/model/eggs_model.dart';
// import 'package:projectbrain/services/http_service.dart';

// import '../constants/constants.dart';

// class EggsService extends HttpService {
//   final String url;
//   final Logger logger;

//   EggsService({this.url = "$BASE_URL/eggs", required this.logger});

//   Future<List<Egg>> fetchEggs() async {
//     // logger.i("Fetching eggs");
//     // logger.i(await getAuthToken());
//     // return <Egg>[];
//     Timeline.startSync('fetchEggs');
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         HttpHeaders.authorizationHeader: "Bearer ${await getAuthToken()}",
//         HttpHeaders.contentTypeHeader: "application/json",
//       },
//     );
//     Timeline.finishSync();
//     logger.i("response.statusCode: ${response.statusCode}");

//     if (response.statusCode == 200) {
//       List<dynamic> body = json.decode(response.body);
//       List<Egg> eggs = body.map((dynamic item) => Egg.fromJson(item)).toList();
//       return eggs;
//     } else {
//       print('Failed to load eggs: ${response.statusCode}');
//       return <Egg>[];
//     }
//   }

//   Future<void> addEgg(Egg egg) async {
//     print("Adding egg");
//     var eggJson = egg.toJson();
//     eggJson.remove('id');
//     var body = json.encode(eggJson);
//     final response = await http.post(
//       Uri.parse(url),
//       headers: {
//         // HttpHeaders.authorizationHeader: "Bearer ${await getAuthToken()}",
//         HttpHeaders.contentTypeHeader: "application/json",
//       },
//       body: body,
//     );

//     print(response.statusCode);
//     if (response.statusCode != 201 && response.statusCode != 200) {
//       print('Failed to add egg');
//     }
//   }

//   Future<void> removeEgg(String id) async {
//     logger.i("Removing egg");
//     final response = await http.delete(
//       Uri.parse("$url/$id"),
//       headers: {
//         // HttpHeaders.authorizationHeader: "Bearer ${await getAuthToken()}",
//         HttpHeaders.contentTypeHeader: "application/json",
//       },
//     );
//     logger.i("response.statusCode: ${response.statusCode}");
//     if (response.statusCode != 200) {
//       print('Failed to remove egg');
//     }
//   }
// }
