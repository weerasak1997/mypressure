import 'dart:convert';
import 'package:mypressure/CameraOverlayPageSingle.dart';
import 'package:mypressure/constantProvider/constantProvider.dart';
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
import 'package:google_fonts/google_fonts.dart';
import '/component/InputPageMany.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsScreen extends StatefulWidget {
  final String message;
  final GoogleSignIn google;
  final String token;
  final String type;
  final bool updated;
  @override
  const DetailsScreen(
      {super.key,
      required this.message,
      required this.google,
      this.type = '',
      this.token = '',
      this.updated = false});
  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Offset? overlay1;
  Offset? overlay2;
  Offset? overlay3;
  String? imagePath;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isDarkMode = false;
  PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Locale? _deviceLocale;
  var type;
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
    _initializeDeviceLocale();
    _getData();
  }

  Future<void> _initializeDeviceLocale() async {
    // Retrieve the device locale
    _deviceLocale = WidgetsBinding.instance.window.locale;
    setState(() {});
  }

  Future<void> _getData() async {
    var request = http.MultipartRequest(
        'GET',
        Uri.parse(
            Platform.isAndroid ? '$url/api/get/data' : '$url/api/get/data'));
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

  void updateData(var data) {
    setState(() {
      dataArray = data;
    });
  }

  Future<void> _takePictureSingle() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              CameraOverlayPageSingle(token: widget.token, update: updateData)),
    );
  }

  Future<void> _takePicture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraOverlayPage()),
    );
    if (result != null) {
      try {
        _showLoadingDialog(context);
        final response = await http.post(
          Uri.parse(Platform.isAndroid
              ? '$url/api/image/stroe'
              : '$url/api/image/stroe'),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InputPageMany(
                  sys: data['sys'].toString(),
                  dia: data['dia'].toString(),
                  pul: data['pul'].toString(),
                  token: widget.token,
                  update: updateData),
            ),
          );
          // List<String>? result = await _showModal(
          //     context,
          //     data['sys'].toString(),
          //     data['dia'].toString(),
          //     data['pul'].toString());

          // if (result != null) {
          //   _showLoadingDialog(context);
          //   final response = await http.post(
          //     Uri.parse(Platform.isAndroid
          //         ? url + '/api/add/data'
          //         : url + '/api/add/data'),
          //     headers: {
          //       'Content-Type':
          //           'application/json', // Adjust based on image format
          //       '_token': widget.token,
          //     },
          //     body: json.encode(
          //         {'sys': result[0], 'dia': result[1], 'pul': result[2]}),
          //   );
          //   if (response.statusCode == 200) {
          //     print('Upload successful');
          //     var data = jsonDecode(response.body);
          //     setState(() {
          //       dataArray = data;
          //     });
          //     Navigator.of(context).pop();
          //   } else {
          //     Navigator.of(context).pop();
          //     print('Upload failed with status: ${response.statusCode}');
          //   }
          // }
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
        return WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text('loading'.tr()),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToPreviousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
              child: Text('submit'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month,
          DateTime.now().day, 0, 0, 10)
      .subtract(const Duration(days: 6));
  DateTime endDate = DateTime(DateTime.now().year, DateTime.now().month,
      DateTime.now().day, 23, 59, 50);

  void updateDates(int days) {
    setState(() {
      startDate = startDate.add(Duration(days: days));
      endDate = endDate.add(Duration(days: days));
      _getDataByDate();
    });
  }

  void selectStartDate() async {
    DateTime initialDate = startDate;
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate != null) {
      setState(() {
        startDate = pickedDate;
        endDate = pickedDate.add(const Duration(days: 7));
        _getDataByDate();
      });
    }
  }

  Future<void> _getDataByDate() async {
    var request = http.MultipartRequest(
        'GET',
        Uri.parse(
            Platform.isAndroid ? '$url/api/get/data' : '$url/api/get/data'));
    request.headers['_token'] = widget.token;
    request.headers['startDate'] = endDate.toString();
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

  @override
  Widget build(BuildContext context) {
    Future<void> handleSignOut() async {
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
    final constantProvider = Provider.of<ConstantProvider>(context);
    final double previewHeight = MediaQuery.of(context).size.height;
    final double previewWidth = MediaQuery.of(context).size.width;
    final dateFormatter = DateFormat('dd/MM/yyyy');
    void showModalSelect() {
      _pageController = PageController(initialPage: constantProvider.type);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(
              child: Text(
                'select-camera'.tr(),
                style: GoogleFonts.lato(fontSize: 20), // Apply Google Font here
              ),
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: _goToPreviousPage,
                ),
                SizedBox(
                  width: 100,
                  height: 50,
                  child: PageView.builder(
                    itemBuilder: (context, index) {
                      if (index % 2 == 0) {
                        return Center(
                          child: Text(
                            'multiple'.tr(),
                            style: GoogleFonts.lato(
                                fontSize: 24), // Use Google Font here
                          ),
                        );
                      } else {
                        return Center(
                          child: Text(
                            'single'.tr(),
                            style: GoogleFonts.lato(
                                fontSize: 24), // Use Google Font here
                          ),
                        );
                      }
                    },
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                      constantProvider.setType(page % 2);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: _goToNextPage,
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button background color
                      foregroundColor: const Color(0xFF397E6F), //
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (_currentPage % 2 == 0) {
                        _takePicture();
                      } else {
                        _takePictureSingle();
                      }
                    },
                    child: Text(
                      'confirm'.tr(),
                      style: GoogleFonts.lato(
                          fontSize: 16), // Use Google Font here
                    ),
                  ),
                  // Uncomment if you want to add a cancel button
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.of(context).pop();
                  //   },
                  //   child: const Text('Cancel', style: TextStyle(fontSize: 18)),
                  // ),
                ],
              ),
            ],
          );
        },
      ).then((selectedDate) {
        if (selectedDate != null) {
          print('User selected: $selectedDate');
        }
      });
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        actions: <Widget>[
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu),
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
                    color: Color(0xFF397E6F),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: Align(
                          alignment: Alignment.topLeft, // Adjust as needed
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              'menu'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.only(
                              right: (Platform.isAndroid ? 10 : 20)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 0, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language,
                        color: Color(0xFF397E6F)), // Add your icon here
                    const SizedBox(width: 8),
                    DropdownButton<Locale>(
                      value: context.locale,
                      onChanged: (Locale? locale) {
                        context.setLocale(locale!);
                      },
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: Locale('th'),
                          child: Text('ภาษาไทย'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'logout'.tr(),
                  style: const TextStyle(
                    color: Colors.red, // Change this to any color you like
                  ),
                ),
                onTap: handleSignOut,
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
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () => updateDates(-7),
                  ),
                  TextButton(
                    onPressed: () => {selectStartDate()},
                    child: Text(
                      "${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}",
                      style: const TextStyle(
                          fontSize: 16, color: Color(0xFF397E6F)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () => updateDates(7),
                  ),
                ],
              ),
            ),
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
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'SYS/DIA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 40, 25, 40),
                        child: BarChartSample(
                          dataArray: dataArray,
                          type: 'sys',
                          startDate: startDate,
                          endDate: endDate,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        width: previewWidth - 66,
                        child: Center(
                          // Center the text
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 4, // Height of the line
                                width: 15, // Width of the line
                                color: const Color(0xFF397E6F),
                              ),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(3, 0, 8, 0),
                                child: Text("SYS"),
                              ),
                              Container(
                                height: 4, // Height of the line
                                width: 15, // Width of the line
                                color: Colors.blue,
                              ),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(3, 0, 0, 0),
                                child: Text("DIA"),
                              )
                            ],
                          ),
                        ),
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
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            'PUL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 40, 25, 40),
                        child: BarChartSample(
                          dataArray: dataArray,
                          type: 'pul',
                          startDate: startDate,
                          endDate: endDate,
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        width: previewWidth - 66,
                        child: Center(
                          // Center the text
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: 4, // Height of the line
                                width: 15, // Width of the line
                                color: const Color(0xFF397E6F),
                              ),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(3, 0, 8, 0),
                                child: Text("PUL"),
                              ),
                            ],
                          ),
                        ),
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
        backgroundColor: const Color(0xFF397E6F),
        foregroundColor: Colors.white,
        onPressed: showModalSelect,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class BarChartSample extends StatelessWidget {
  // final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Random random = Random();
  final String type;
  var dataArray = [];
  DateTime startDate, endDate;
  FlLine _getDrawingVerticalLine(double value) {
    return const FlLine(
      color: Colors.grey, // Color of the vertical grid lines
      strokeWidth: 0.8, // Thickness of the vertical grid lines
    );
  }

  BarChartSample({
    super.key,
    required this.dataArray,
    required this.type,
    required this.startDate,
    required this.endDate,
  });
  @override
  Widget build(BuildContext context) {
    if (dataArray.isNotEmpty) {
      List<String> days = dataArray
          .map((item) => ((item['created_at'].replaceAll('T', ' '))
                  .replaceAll('.000000Z', ''))
              .replaceAll(' ', 'T') as String)
          .toList();
      List<FlSpot> dataSys = [], dataDia = [], dataPul = [];
      List<String> day = [];
      if (type == 'sys') {
        for (int i = 0; i < dataArray.length; i++) {
          dataSys.add(FlSpot(
              (DateTime.parse(days[i]).millisecondsSinceEpoch)
                  .round()
                  .toDouble(),
              dataArray[i]['sys'].toDouble()));
          dataDia.add(FlSpot(
              (DateTime.parse(days[i]).millisecondsSinceEpoch)
                  .round()
                  .toDouble(),
              dataArray[i]['dia'].toDouble()));
        }
        return LineChart(
          LineChartData(
            maxY: 200,
            minY: 0,
            minX: startDate.millisecondsSinceEpoch.toDouble(),
            maxX: endDate.millisecondsSinceEpoch.toDouble(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: const Duration(days: 1)
                      .inMilliseconds
                      .toDouble(), // 1-day intervals
                  getTitlesWidget: (value, meta) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    String text = DateFormat('dd').format(date);
                    if (value == meta.min) {
                      day = [];
                    }
                    if (!day.contains(text)) {
                      day.add(text);
                    } else {
                      text = '';
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        text, // Show day of week
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, // Show titles if needed
                  reservedSize: 30, // Increase width of the right side
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        value.toInt().toString(), // Customize title as needed
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: 10,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: dataSys,
                isCurved: true,
                color: const Color(0xFF397E6F),
                barWidth: 3,
                belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF397E6F).withOpacity(0.3)),
                dotData: const FlDotData(show: true),
              ),
              // Second Line
              LineChartBarData(
                spots: dataDia,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                belowBarData: BarAreaData(
                    show: true, color: Colors.blue.withOpacity(0.3)),
                dotData: const FlDotData(show: true),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    // Format the date from the x coordinate
                    final date = DateFormat('dd/MM/yyyy HH:mm:ss').format(
                      DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()),
                    );

                    final isFirst = touchedSpots.first == spot;

                    if (isFirst) {
                      return LineTooltipItem(
                        '$date\nSys: ${spot.y}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    } else {
                      return LineTooltipItem(
                        'Dia: ${spot.y}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }
                  }).toList();
                },
              ),
            ),
          ),
        );
      } else {
        for (int i = 0; i < dataArray.length; i++) {
          dataPul.add(FlSpot(
              (DateTime.parse(days[i]).millisecondsSinceEpoch)
                  .round()
                  .toDouble(),
              dataArray[i]['pul'].toDouble()));
        }
        return LineChart(
          LineChartData(
            maxY: 200,
            minY: 0,
            minX: startDate.millisecondsSinceEpoch.toDouble(),
            maxX: endDate.millisecondsSinceEpoch.toDouble(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: const Duration(days: 1)
                      .inMilliseconds
                      .toDouble(), // 1-day intervals
                  getTitlesWidget: (value, meta) {
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    String text = DateFormat('dd').format(date);
                    if (value == meta.min) {
                      day = [];
                    }
                    if (!day.contains(text)) {
                      day.add(text);
                    } else {
                      text = '';
                    }
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        text, // Show day of week
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true, // Show titles if needed
                  reservedSize: 30, // Increase width of the right side
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(
                        value.toInt().toString(), // Customize title as needed
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: 10,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: dataPul,
                isCurved: true,
                color: const Color(0xFF397E6F),
                barWidth: 3,
                belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF397E6F).withOpacity(0.3)),
                dotData: const FlDotData(show: true),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    // Format the date from the x coordinate
                    final date = DateFormat('dd/MM/yyyy HH:mm:ss').format(
                      DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()),
                    );

                    final isFirst = touchedSpots.first == spot;

                    if (isFirst) {
                      return LineTooltipItem(
                        '$date\nPul: ${spot.y}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    } else {
                      return LineTooltipItem(
                        'Dia: ${spot.y}',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    }
                  }).toList();
                },
              ),
            ),
          ),
        );
      }
    } else {
      List<String> day = [];
      return LineChart(
        LineChartData(
          maxY: 200,
          minY: 0,
          minX: startDate.millisecondsSinceEpoch.toDouble(),
          maxX: endDate.millisecondsSinceEpoch.toDouble(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: const Duration(days: 1)
                    .inMilliseconds
                    .toDouble(), // 1-day intervals
                getTitlesWidget: (value, meta) {
                  final date =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  String text = DateFormat('dd').format(date);
                  if (value == meta.min) {
                    day = [];
                  }
                  if (!day.contains(text)) {
                    day.add(text);
                  } else {
                    text = '';
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      text, // Show day of week
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Show titles if needed
                reservedSize: 30, // Increase width of the right side
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      value.toInt().toString(), // Customize title as needed
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      );
    }
  }
}
