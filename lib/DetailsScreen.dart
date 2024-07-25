import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class DetailsScreen extends StatefulWidget {
  final String message;
  final GoogleSignIn google;

  @override
  DetailsScreen({required this.message, required this.google});
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  File? _image;
  // Define the constructor to accept a message argument
  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleSignOut() async {
    await widget.google.disconnect();
    Navigator.pushNamedAndRemoveUntil(
        context, '/home', ModalRoute.withName('/home'));
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text(
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
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        child: Stack(children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                margin: EdgeInsets.all(16),
                height: constraints.maxHeight / 3,
                child: Card(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            'SYS',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: BarChartSample(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                margin: EdgeInsets.fromLTRB(
                    16.0, (constraints.maxHeight / 3) + 20, 16.0, 16.0),
                height: constraints.maxHeight / 3,
                child: Card(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            'DIA',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: BarChartSample(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                margin: EdgeInsets.fromLTRB(
                    16.0, (2 * constraints.maxHeight / 3) + 20, 16.0, 16.0),
                height: constraints.maxHeight / 3,
                child: Card(
                  color: Colors.white,
                  child: Stack(
                    children: [
                      const SizedBox(
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            'PUL',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(25),
                        child: BarChartSample(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: Icon(Icons.camera_alt),
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
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Random random = Random();

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(days[index]),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: false,
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: random.nextInt(20).toDouble(),
                color: Colors.primaries[index % Colors.primaries.length],
                width: 8,
              )
            ],
          );
        }),
      ),
    );
  }
}
