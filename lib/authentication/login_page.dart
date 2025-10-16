import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => authProvider.login(),
          child: const Text('Login with Auth0'),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'auth_service.dart';

// class LoginPage extends StatelessWidget {
//   final AuthService authService;
//   const LoginPage(this.authService, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Login')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () {
//             authService.login(); // Redirects immediately
//           },
//           child: Text('Login with Auth0'),
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:projectbrain/authentication/authentication_bloc.dart';

// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//           title: const Text('Flutter Web Authentication with Auth0',
//               style: TextStyle(color: Colors.white)),
//           backgroundColor: Colors.black87),
//       body: Center(
//         child: Column(children: [
//           const Spacer(),
//           const Flexible(
//               flex: 10,
//               child: Text(
//                   '[ This app uses Go_Router for navigation and BloC for state management. ]')),
//           const Spacer(),
//           Flexible(
//             flex: 2,
//             child: ElevatedButton(
//                 onPressed: () {
//                   context.read<AuthenticationBloc>().add(LogIn());
//                 },
//                 child: const Text('Login')),
//           )
//         ]),
//       ),
//     );
//   }
// }
