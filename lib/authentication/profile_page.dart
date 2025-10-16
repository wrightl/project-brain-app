import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // Add for clipboard

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage:
                    NetworkImage(authProvider.profile?.picture ?? ''),
              ),
              const SizedBox(height: 16),
              Text(
                authProvider.profile?.name ?? '',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.profile?.email ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (kDebugMode)
                FutureBuilder<String?>(
                  future: authProvider.authService.getAccessToken(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading access token...');
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final token = snapshot.data ?? "";
                    String truncated = token.length > 32
                        ? '${token.substring(0, 16)}...${token.substring(token.length - 8)}'
                        : token;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          'Access Token:\n$truncated',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy Full Token'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: token.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: token));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Token copied to clipboard')),
                                  );
                                },
                        ),
                      ],
                    );
                  },
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  await authProvider.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:auth0_flutter/auth0_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:projectbrain/authentication/authentication_bloc.dart';

// class UserProfilePage extends StatelessWidget {
//   const UserProfilePage({super.key});

//   final TextStyle _textStyle = const TextStyle(fontWeight: FontWeight.bold);

//   @override
//   Widget build(BuildContext context) {
//     final status = context.read<AuthenticationBloc>().state;
//     final UserProfile? userProfile =
//         status is LoggedIn ? status.userProfile : null;
//     return Scaffold(
//       appBar: _appBar(
//           '${userProfile!.nickname}', '${userProfile.pictureUrl}', context),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(children: [
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text(
//                   '[ NOTE: Use the "--web-renderer=html" option to show the picture avatar properly. ]'),
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(50, 20, 50, 0),
//               child: Table(
//                   border: TableBorder.all(),
//                   columnWidths: const <int, TableColumnWidth>{
//                     0: FlexColumnWidth(1),
//                     1: FlexColumnWidth(3),
//                   },
//                   children: [
//                     TableRow(children: [
//                       _paddedWidget(_boldText('Email')),
//                       _paddedWidget(Text('${userProfile.email}')),
//                     ]),
//                     TableRow(children: [
//                       _paddedWidget(_boldText('Name')),
//                       _paddedWidget(Text('${userProfile.name}')),
//                     ]),
//                     TableRow(children: [
//                       _paddedWidget(_boldText('Picture')),
//                       _paddedWidget(Container(
//                         alignment: Alignment.centerLeft,
//                         child: CircleAvatar(
//                           radius: 16,
//                           child: ClipOval(
//                             child: Image.network(
//                               '${userProfile.pictureUrl}',
//                             ),
//                           ),
//                         ),
//                       )),
//                     ]),
//                     TableRow(children: [
//                       _paddedWidget(_boldText('Nickname')),
//                       _paddedWidget(Text('${userProfile.nickname}')),
//                     ]),
//                     TableRow(children: [
//                       _paddedWidget(_boldText('IsEmailVerified')),
//                       _paddedWidget(Text('${userProfile.isEmailVerified}'))
//                     ]),
//                     TableRow(children: [
//                       _paddedWidget(_boldText('UpdatedAt')),
//                       _paddedWidget(Text('${userProfile.updatedAt}'))
//                     ]),
//                   ]),
//             ),
//           ]),
//         ),
//       ),
//     );
//   }

//   Widget _paddedWidget(Widget widget) {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: widget,
//     );
//   }

//   Widget _boldText(String text) {
//     return Text(text, style: _textStyle);
//   }

//   AppBar _appBar(String nickname, String pictureUrl, BuildContext context) {
//     return AppBar(
//         leading: const Icon(Icons.menu, color: Colors.white),
//         title: const Center(
//             child: Text('User Profile', style: TextStyle(color: Colors.white))),
//         backgroundColor: Colors.black87,
//         actions: [
//           _paddedWidget(
//               Text(nickname, style: const TextStyle(color: Colors.white))),
//           CircleAvatar(
//             radius: 16,
//             child: ClipOval(
//               child: Image.network(
//                 pictureUrl,
//               ),
//             ),
//           ),
//           IconButton(
//               onPressed: () {
//                 context.read<AuthenticationBloc>().add(LogOut());
//               },
//               icon: const Icon(Icons.logout, color: Colors.white))
//         ]);
//   }
// }
