import 'package:flutter/material.dart';
import 'package:mypressure/theme/theme_provider.dart';
import 'package:mypressure/user/user_provider.dart';
import 'package:provider/provider.dart';
import 'DetailsScreen.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GoogleSignIn google = GoogleSignIn();
  var first = true;
  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;
    if (isDarkMode && first) {
      Provider.of<ThemeProvider>(context, listen: false).darkTheme();
    }
    first = false;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: Provider.of<ThemeProvider>(context).themeData,
      themeMode: ThemeMode.system,
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/child': (context) => DetailsScreen(
              message: 'Hello from First Screen',
              google: google,
            ),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<HomeScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _currentUser;
  // url variable
  // String url =
  //     Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  String url = 'https://mypressure.the8th-floor.com';
  // void _signInWithApple() async {
  //   try {
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );

  //     // Use the credential to sign in to your app
  //     // For example, send the credential to your backend for verification
  //     print('Apple ID Credential: ${credential.identityToken}');
  //   } catch (error) {
  //     print('Error signing in with Apple: $error');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      setState(() {
        _currentUser = account;
      });
      if (account != null) {
        final response = await http.post(
            // Uri.parse('https://mypressure.the8th-floor.com/api/login/gmail'),
            Uri.parse(Platform.isAndroid
                ? url + '/api/login/gmail'
                : url + '/api/login/gmail'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'token':
                  'Rs6EuSuMkhzWfYkyV7pRV3A0F7jITjLoAv8xly7IG4O0H0tFOGqaUShm2as6Trgc'
            },
            body: jsonEncode({
              "displayName": account.displayName,
              "email": account.email,
              "id": account.id,
              "photoUrl": account.photoUrl,
            }));
        // Provider.of<UserProvider>(context, listen: false)
        //     .setUser(convertAccountToJson(account));
        //Navigator
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsScreen(
                  message: 'Hello from First Screen',
                  google: _googleSignIn,
                  type: 'google',
                  token: response.body)),
        );
      }
    });
    _googleSignIn.signInSilently();
    SharedPreferences.getInstance().then((prefs) async {
      if (prefs.getBool('isSignedIn') ?? false) {
        // User is signed in
        final response = await http.post(
            // Uri.parse('https://mypressure.the8th-floor.com/api/login/gmail'),
            Uri.parse(Platform.isAndroid
                ? url + '/api/login/apple'
                : url + '/api/login/apple'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'token':
                  'Rs6EuSuMkhzWfYkyV7pRV3A0F7jITjLoAv8xly7IG4O0H0tFOGqaUShm2as6Trgc'
            },
            body: jsonEncode({
              "idToken": prefs.getString('idToken'),
            }));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsScreen(
                  message: 'Hello from First Screen',
                  google: _googleSignIn,
                  type: 'apple',
                  token: response.body)),
        );
        print('sign in');
      } else {
        // User is not signed in
        print('not sign in');
      }
    });
  }

  // Function to convert GoogleSignInAccount to JSON string
  String convertAccountToJson(GoogleSignInAccount account) {
    final Map<String, dynamic> accountData = {
      'displayName': account.displayName,
      'email': account.email,
      'photoUrl': account.photoUrl,
      'id': account.id,
    };

    return jsonEncode(accountData);
  }

  Future<void> _handleSignIn() async {
    try {
      GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user != null) {
        print('User email: ${user.email}');
        print(user);
        final response = await http.post(
            Uri.parse(Platform.isAndroid
                ? url + '/api/login/gmail'
                : url + '/api/login/gmail'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'token':
                  'Rs6EuSuMkhzWfYkyV7pRV3A0F7jITjLoAv8xly7IG4O0H0tFOGqaUShm2as6Trgc'
            },
            body: jsonEncode({
              "displayName": user.displayName,
              "email": user.email,
              "id": user.id,
              "photoUrl": user.photoUrl,
            }));
        if (response.statusCode == 200) {
          print(json.decode(response.body));
        } else {
          throw Exception('Failed to load posts');
        }
        Provider.of<UserProvider>(context, listen: false)
            .setUser(convertAccountToJson(user));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsScreen(
                  message: 'Hello from First Screen',
                  google: _googleSignIn,
                  type: 'google',
                  token: response.body)),
        );
      }
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSignedIn', false);
  }

  Widget build(BuildContext context) {
    GoogleSignInAccount? user = _currentUser;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Google Sign-In'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            user == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GoogleLoginButton(
                          onPressed:
                              _handleSignIn // Handle the Google login logic here

                          ),
                    ],
                  )
                : Text('')
            // Column(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Text('Signed in as ${user.displayName}'),
            //       SizedBox(height: 20),
            //       ElevatedButton(
            //         onPressed: _handleSignOut,
            //         child: Text('Sign out'),
            //       ),
            //     ],
            //   )
          ],
        ),
      ),
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // url variable
  // String url =
  //     Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  String url = 'https://mypressure.the8th-floor.com';
  GoogleLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    const background = Color(0x131314FF);
    // const foregroundColor = Color(0xE3E3E3FF);
    const color = Color(0xE3E3E3FF);
    const border = Color(0x8E918FFF);
    return Column(children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.isDarkMode ? background : Colors.white,
          foregroundColor:
              themeProvider.isDarkMode ? Colors.white : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          side: BorderSide(
              color: themeProvider.isDarkMode ? border : Colors.grey),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Image(
                image: AssetImage("assets/google_logo.png"),
                height: 20.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode ? color : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      Platform.isAndroid
          ? const Center()
          : Container(
              margin:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 75.0),
              child: SignInWithAppleButton(
                onPressed: () async {
                  final credential = await SignInWithApple.getAppleIDCredential(
                    scopes: [
                      AppleIDAuthorizationScopes.email,
                      AppleIDAuthorizationScopes.fullName,
                    ],
                  );
                  // Store sign-in state
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('isSignedIn', true);
                  await prefs.setString(
                      'idToken', credential.userIdentifier.toString());
                  print(credential.userIdentifier);
                  final response = await http.post(
                      Uri.parse(Platform.isAndroid
                          ? url + '/api/login/apple'
                          : url + '/api/login/apple'),
                      headers: <String, String>{
                        'Content-Type': 'application/json; charset=UTF-8',
                        'token':
                            'Rs6EuSuMkhzWfYkyV7pRV3A0F7jITjLoAv8xly7IG4O0H0tFOGqaUShm2as6Trgc'
                      },
                      body: jsonEncode({
                        "idToken": credential.userIdentifier.toString(),
                      }));
                  if (response.statusCode == 200) {
                    print(response.body);
                  } else {
                    throw Exception('Failed to load posts');
                  }
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DetailsScreen(
                            message: 'Hello from First Screen',
                            google: _googleSignIn,
                            type: 'apple',
                            token: response.body)),
                  );
                  // Use the credential to authenticate with your backend or Firebase
                  // print(credential);
                },
              ),
            )
    ]);
  }
}

// class AppleButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//           child: SignInWithAppleButton(
//             onPressed: () async {
//               try {
//                 final credential = await SignInWithApple.getAppleIDCredential(
//                   scopes: [
//                     AppleIDAuthorizationScopes.email,
//                     AppleIDAuthorizationScopes.fullName,
//                   ],
//                 );

//                 print(credential);
//                 // Handle credential (send to your server or authenticate user)
//               } catch (error) {
//                 print(error);
//                 // Handle error
//               }
//             },
//         ),
//       ),
//     );
//   }
// }
