import 'dart:convert';
import 'package:mypressure/user/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mypressure/theme/theme_provider.dart';
import 'dart:io';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mypressure/CameraOverlayPage.dart';
import 'package:flutter/services.dart';

class DetailsScreen extends StatefulWidget {
  final String message;
  final GoogleSignIn google;
  final String token;
  final String type;
  @override
  DetailsScreen(
      {required this.message,
      required this.google,
      this.type = '',
      this.token = ''});
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Offset? overlay1;
  Offset? overlay2;
  Offset? overlay3;
  String? imagePath;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isDarkMode = false;
  // url variable
  // String url =
  //     Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000';
  String url = 'https://mypressure.the8th-floor.com';
  // File? _image;
  var dataArray = [];
  // Define the constructor to accept a message argument
  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    var request = http.MultipartRequest(
        'GET',
        Uri.parse(Platform.isAndroid
            ? url + '/api/get/data'
            : url + '/api/get/data'));
    request.headers['_token'] = widget.token;
    var streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        dataArray = data;
      });
    } else {
      print('Failed to load data: ${response.statusCode}');
    }
  }

  Future<void> _takePicture() async {
    // final picker = ImagePicker();
    // final pickedFile = await picker.pickImage(source: ImageSource.camera);

    // if (pickedFile != null) {
    //   // setState(() {
    //   //   _image = File(pickedFile.path);
    //   // });
    //   File file = File(pickedFile.path);
    //   await _sendImageToApi(file);
    // }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraOverlayPage()),
    );
    if (result != null) {
      try {
        _showLoadingDialog(context);
        final response = await http.post(
          Uri.parse(Platform.isAndroid
              ? url + '/api/image/stroe'
              : url + '/api/image/stroe'),
          headers: {
            'Content-Type': 'application/json', // Adjust based on image format
            '_token': widget.token,
          },
          body: json.encode({
            'image1': base64Encode(result['overlay1']),
            'image2': base64Encode(result['overlay2']),
            'image3': base64Encode(result['overlay3'])
          }),
        );

        if (response.statusCode == 200) {
          print('Upload successful');
          Navigator.of(context).pop();
          var data = jsonDecode(response.body);
          List<String>? result = await _showModal(
              context,
              data['sys'].toString(),
              data['dia'].toString(),
              data['pul'].toString());

          if (result != null) {
            _showLoadingDialog(context);
            final response = await http.post(
              Uri.parse(Platform.isAndroid
                  ? url + '/api/add/data'
                  : url + '/api/add/data'),
              headers: {
                'Content-Type':
                    'application/json', // Adjust based on image format
                '_token': widget.token,
              },
              body: json.encode(
                  {'sys': result[0], 'dia': result[1], 'pul': result[2]}),
            );
            if (response.statusCode == 200) {
              print('Upload successful');
              var data = jsonDecode(response.body);
              setState(() {
                dataArray = data;
              });
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pop();
              print('Upload failed with status: ${response.statusCode}');
            }
          }
        } else {
          Navigator.of(context).pop();
          print('Upload failed with status: ${response.statusCode}');
        }
      } catch (e) {
        Navigator.of(context).pop();
        print('Error uploading image: $e');
      }
    }
  }

// Show the loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dialog from being dismissed by tapping outside
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Loading...'),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>?> _showModal(
      BuildContext context, String sys, String dia, String pul) {
    TextEditingController sysController = TextEditingController(text: sys);
    TextEditingController diaController = TextEditingController(text: dia);
    TextEditingController pulController = TextEditingController(text: pul);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('My Pressure'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sysController,
                decoration: const InputDecoration(
                  labelText: 'Sys',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ], // Only numbers can be entered
              ),
              TextField(
                controller: diaController,
                decoration: const InputDecoration(
                  labelText: 'Dia',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ], // Only numbers can be entered
              ),
              TextField(
                controller: pulController,
                decoration: const InputDecoration(
                  labelText: 'Pul',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ], // Only numbers can be entered
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the modal
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Handle the submit action
                String sys = sysController.text;
                String dia = diaController.text;
                String pul = pulController.text;

                print('Sys: $sys, Dia: $dia, Pul: $pul');

                // Do something with the values, then close the modal
                Navigator.of(context).pop([
                  sys,
                  dia,
                  pul,
                ]);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _handleSignOut() async {
      if (widget.type == 'google') {
        await widget.google.disconnect();
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      }
      Navigator.pushNamedAndRemoveUntil(
          context, '/home', ModalRoute.withName('/home'));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final double previewHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        // title: Text('Home Page'),
        // leading: IconButton(
        //   icon: Icon(Icons.menu), // Hamburger menu icon
        //   onPressed: () {
        //     scaffoldKey.currentState!.openDrawer(); // Open the drawer
        //   },
        // ),
        actions: <Widget>[
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  scaffoldKey.currentState!.openEndDrawer();
                },
              );
            },
          ),
        ],
      ),
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              SizedBox(
                height: 120.0,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 7,
                        child: Align(
                          alignment: Alignment.topLeft, // Adjust as needed
                          child: Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.only(
                              right: (Platform.isAndroid ? 0 : 20)),
                          child: Align(
                            alignment: Alignment.topLeft, // Adjust as needed
                            child: Switch(
                              value: Provider.of<ThemeProvider>(context,
                                      listen: false)
                                  .getIsDarkMode(),
                              activeColor: Colors.grey.shade400,
                              activeTrackColor: Colors.blueGrey.shade600,
                              inactiveThumbColor: Colors.grey.shade400,
                              inactiveTrackColor: Colors.white,
                              trackOutlineColor:
                                  WidgetStateProperty.resolveWith(
                                (final Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return null;
                                  }

                                  return Colors.grey.shade400;
                                },
                              ),
                              onChanged: (value) {
                                setState(() {
                                  isDarkMode = value;
                                });
                                Provider.of<ThemeProvider>(context,
                                        listen: false)
                                    .toggleTheme();
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                              0, Platform.isAndroid ? 12 : 4, 20, 0),
                          child: (isDarkMode
                              ? const Align(
                                  alignment:
                                      Alignment.topLeft, // Adjust as needed
                                  child: Icon(
                                    Icons
                                        .brightness_2, // Moon icon for dark mode
                                    color: Colors.blueGrey,
                                    size: 24,
                                  ),
                                )
                              : const Align(
                                  alignment:
                                      Alignment.topLeft, // Adjust as needed
                                  child: Icon(
                                    Icons.wb_sunny, // Sun icon for light mode
                                    color: Colors.yellow,
                                    size: 24,
                                  ),
                                )),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              // ListTile(
              //   leading: Icon(Icons.home),
              //   title: Text('Home'),
              //   onTap: () {
              //     Navigator.pop(context); // Close the drawer
              //   },
              // ),
              // ListTile(
              //   leading: Icon(Icons.settings),
              //   title: Text('Settings'),
              //   onTap: () {
              //     Navigator.pop(context); // Close the drawer
              //   },
              // ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red, // Change this to any color you like
                  ),
                ),
                onTap: _handleSignOut,
              ),
            ],
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                height: (previewHeight / 3),
                child: Card(
                  color: themeProvider.isDarkMode
                      ? const Color(0x203858FF)
                      : Colors.white,
                  child: Stack(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'SYS',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 40, 25, 25),
                        child:
                            BarChartSample(dataArray: dataArray, type: 'sys'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16.0, 10, 16.0, 10.0),
                height: (previewHeight / 3),
                child: Card(
                  color: themeProvider.isDarkMode
                      ? const Color(0x203858FF)
                      : Colors.white,
                  child: Stack(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'DIA',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child:
                            BarChartSample(dataArray: dataArray, type: 'dia'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16.0, 10, 16.0, 10.0),
                height: (previewHeight / 3),
                child: Card(
                  color: themeProvider.isDarkMode
                      ? const Color(0x203858FF)
                      : Colors.white,
                  child: Stack(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'PUL',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child:
                            BarChartSample(dataArray: dataArray, type: 'pul'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
    // body: Builder(
    //   builder: (context) => Align(
    //       alignment: Alignment.center,
    //       child: AspectRatio(
    //           aspectRatio: 2.0,
    //           child: Container(
    //             margin: const EdgeInsets.only(top: 24),
    //             child: BarChart(
    //               BarChartData(
    //                   // read about it in the BarChartData section
    //                   ),
    //               swapAnimationDuration:
    //                   Duration(milliseconds: 150), // Optional
    //               swapAnimationCurve: Curves.linear, // Optional
    //             ),
    //           ))),
    // ));
  }
}

class BarChartSample extends StatelessWidget {
  // final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Random random = Random();
  final String type;
  var dataArray = [];
  BarChartSample({required this.dataArray, required this.type});
  @override
  Widget build(BuildContext context) {
    if (dataArray.length > 0) {
      List<String> days =
          dataArray.map((item) => item['created_at'] as String).toList();
      List<double> dataShow;
      if (type == 'sys') {
        dataShow =
            dataArray.map((item) => item['sys'].toDouble() as double).toList();
      } else if (type == 'dia') {
        dataShow =
            dataArray.map((item) => item['dia'].toDouble() as double).toList();
      } else {
        dataShow =
            dataArray.map((item) => item['pul'].toDouble() as double).toList();
      }
      days = days.reversed.toList();
      dataShow = dataShow.reversed.toList();
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 200,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  DateTime dateTime = DateTime.parse(days[index]);
                  String text = DateFormat('dd').format(dateTime);
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 10.0, // set the desired font size here
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(
            show: false,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            verticalInterval: 1,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(14, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  // toY: random.nextInt(20).toDouble(),
                  toY: dataShow[index],
                  color: Colors.primaries[index % Colors.primaries.length],
                  width: 8,
                )
              ],
            );
          }),
        ),
      );
    } else {
      return Container();
    }
  }
}
