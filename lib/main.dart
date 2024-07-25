import 'package:flutter/material.dart';
import 'DetailsScreen.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GoogleSignIn google = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: Colors.white,
        ),
      ),
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/child': (context) =>
            DetailsScreen(message: 'Hello from First Screen', google: google),
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DetailsScreen(
                  message: 'Hello from First Screen', google: _googleSignIn)),
        );
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user != null) {
        print('User email: ${user.email}');
        print(user);
        final response =
            await http.post(Uri.parse('http://10.0.2.2:8000/api/login/gmail'),
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
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //       builder: (context) => DetailsScreen(
        //           message: 'Hello from First Screen', google: _googleSignIn)),
        // );
      }
      print('out');
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
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
                ? GoogleLoginButton(
                    onPressed:
                        _handleSignIn // Handle the Google login logic here

                    )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Signed in as ${user.displayName}'),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _handleSignOut,
                        child: Text('Sign out'),
                      ),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  GoogleLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
        ),
        side: const BorderSide(color: Colors.grey),
      ),
      onPressed: onPressed,
      child: const Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: AssetImage("assets/google_logo.png"),
              height: 24.0,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'Sign in with Google',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
