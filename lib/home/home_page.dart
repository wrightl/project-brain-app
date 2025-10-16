import 'package:flutter/material.dart';
import 'package:projectbrain/authentication/auth_provider.dart';
import 'package:projectbrain/authentication/auth_service.dart';
import 'package:provider/provider.dart';

// class HomePage extends StatefulWidget {
//   static String routeName = 'homePage';
//   static Route<HomePage> route() {
//     return MaterialPageRoute<HomePage>(
//       settings: RouteSettings(name: routeName),
//       builder: (BuildContext context) => HomePage(),
//     );
//   }

//   @override
//   _HomePageState createState() => _HomePageState();
// }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // bool isProgressing = false;
  // bool isLoggedIn = false;
  // String errorMessage = '';
  // String? name;

  // @override
  // void initState() {
  //   initAction();
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final name = authProvider.profile?.name ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // if (isProgressing)
                // CircularProgressIndicator()
                // else if (!isLoggedIn)
                // IconButton(
                // icon: Icon(Icons.login),
                // onPressed: loginAction,
                // )
                // else
                Text('Welcome $name'),
              ],
            ),
            // if (errorMessage.isNotEmpty) Text(errorMessage),
          ],
        ),
      ),
    );
  }

  // setSuccessAuthState() async {
  //   setState(() {
  //     isProgressing = false;
  //     isLoggedIn = true;
  //     name = AuthService.instance.idToken?.name;
  //   });

  //   Navigator.pushReplacementNamed(context, '/eggs');
  // }

  // setLoadingState() {
  //   setState(() {
  //     isProgressing = true;
  //     errorMessage = '';
  //   });
  // }

  // Future<void> loginAction() async {
  //   setLoadingState();
  //   final message = await AuthService.instance.login();
  //   if (message == 'Success') {
  //     setSuccessAuthState();
  //   } else {
  //     setState(() {
  //       isProgressing = false;
  //       errorMessage = message;
  //     });
  //   }
  // }

  // initAction() async {
  //   setLoadingState();
  //   final bool isAuth = await AuthService.instance.init();
  //   if (isAuth) {
  //     setSuccessAuthState();
  //   } else {
  //     setState(() {
  //       isProgressing = false;
  //     });
  //   }
  // }
}

// class HomePage extends StatelessWidget {
//   final AuthService authService;
//   const HomePage(this.authService, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Welcome'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () async {
//               await authService.logout();
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           )
//         ],
//       ),
//       body: Center(
//         child: Text(
//           'Hello, ${authService.userName}!',
//           style: TextStyle(fontSize: 24),
//         ),
//       ),
//     );
//   }
// }
