import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:mypressure/constantProvider/constantProvider.dart';
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
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart' as Foundation;
import 'package:in_app_update/in_app_update.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => ConstantProvider()),
    ],
    child: EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('th')],
      path: 'assets/lang', // path to translation files
      fallbackLocale: const Locale('en'),
      child: MyApp(),
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
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
  const HomeScreen({super.key});

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
                ? '$url/api/login/gmail'
                : '$url/api/login/gmail'),
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
        Map<String, dynamic> user = jsonDecode(response.body);
        bool update = false;

        if (Foundation.defaultTargetPlatform == Foundation.TargetPlatform.iOS) {
          print("Running on iOS");
        } else if (Foundation.defaultTargetPlatform ==
            Foundation.TargetPlatform.android) {
          print("Running on Android");
          InAppUpdate.checkForUpdate().then((info) {
            if (info.updateAvailability == UpdateAvailability.updateAvailable) {
              InAppUpdate.performImmediateUpdate();
            }
          }).catchError((e) {
            print("Error checking for updates: $e");
          });
        } else {
          print("Running on an unknown platform");
          // if (version != user['android_version']) {
          //   update = true;
          // }
        }
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
                  token: user['token'],
                  updated: update)),
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
                ? '$url/api/login/apple'
                : '$url/api/login/apple'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'token':
                  'Rs6EuSuMkhzWfYkyV7pRV3A0F7jITjLoAv8xly7IG4O0H0tFOGqaUShm2as6Trgc'
            },
            body: jsonEncode({
              "idToken": prefs.getString('idToken'),
            }));
        Map<String, dynamic> user = jsonDecode(response.body);
        bool update = false;

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String version = packageInfo.version;

        if (Foundation.defaultTargetPlatform == Foundation.TargetPlatform.iOS) {
          print("Running on iOS");
        } else if (Foundation.defaultTargetPlatform ==
            Foundation.TargetPlatform.android) {
          print("Running on Android");
          InAppUpdate.checkForUpdate().then((info) {
            if (info.updateAvailability == UpdateAvailability.updateAvailable) {
              InAppUpdate.performImmediateUpdate();
            }
          }).catchError((e) {
            print("Error checking for updates: $e");
          });
        } else {
          print("Running on an unknown platform");
          // if (version != user['android_version']) {
          //   update = true;
          // }
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              message: 'Hello from First Screen',
              google: _googleSignIn,
              type: 'apple',
              token: user['toke'],
            ),
          ),
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
                ? '$url/api/login/gmail'
                : '$url/api/login/gmail'),
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
        Map<String, dynamic> useres = jsonDecode(response.body);
        bool update = false;

        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        String version = packageInfo.version;

        if (Foundation.defaultTargetPlatform == Foundation.TargetPlatform.iOS) {
          print("Running on iOS");
        } else if (Foundation.defaultTargetPlatform ==
            Foundation.TargetPlatform.android) {
          print("Running on Android");
          InAppUpdate.checkForUpdate().then((info) {
            if (info.updateAvailability == UpdateAvailability.updateAvailable) {
              InAppUpdate.performImmediateUpdate();
            }
          }).catchError((e) {
            print("Error checking for updates: $e");
          });
        } else {
          print("Running on an unknown platform");
          // if (version != user['android_version']) {
          //   update = true;
          // }
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              message: 'Hello from First Screen',
              google: _googleSignIn,
              type: 'google',
              token: useres['token'],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    GoogleSignInAccount? user = _currentUser;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Google Sign-In'),
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_inside.png',
              height: screenWidth * 0.8, // Adjust size as needed
              width: screenWidth * 0.8,
            ),
            SizedBox(height: screenWidth * 0.2),
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
                : const Text('')
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
  GoogleLoginButton({super.key, required this.onPressed});

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
                          ? '$url/api/login/apple'
                          : '$url/api/login/apple'),
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
