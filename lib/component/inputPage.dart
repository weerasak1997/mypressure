import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';

class InputPage extends StatefulWidget {
  String sys, dia, pul, token;
  final void Function(dynamic) update;
  InputPage(
      {super.key,
      required this.sys,
      required this.dia,
      required this.pul,
      required this.token,
      required this.update});
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  String url = 'https://mypressure.the8th-floor.com';
  late TextEditingController sysController, diaController, pulController;
  @override
  void initState() {
    super.initState();
    // Initialize the controller with widget.initialValue inside initState
    sysController = TextEditingController(text: widget.sys);
    diaController = TextEditingController(text: widget.dia);
    pulController = TextEditingController(text: widget.pul);
  }

  Future<bool> _onWillPop() async {
    bool shouldLeave = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('quastion-sure'.tr()),
        content: Text('quastion-detail'.tr()),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false), // Stay on the page
            child: Text('no'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pop(true);
              Navigator.of(context).pop(true);
            }, // Leave the page
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevents dialog from being dismissed by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text('loading'.tr()),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('blood-form'.tr(),
              style: GoogleFonts.roboto(color: const Color(0xFF397E6F))),
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_left_outlined,
              color: Color(0xFF397E6F),
            ),
            onPressed: _onWillPop,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'blood-information'.tr(),
                style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF397E6F)),
              ),
              const SizedBox(height: 20),
              _buildTextField(sysController, 'systolic'.tr()),
              const SizedBox(height: 20),
              _buildTextField(diaController, 'diastolic'.tr()),
              const SizedBox(height: 20),
              _buildTextField(pulController, 'blood-pressure'.tr()),
              const Spacer(), // Pushes the button to the bottom
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () async {
                    _showLoadingDialog(context);
                    final response = await http.post(
                      Uri.parse(Platform.isAndroid
                          ? '$url/api/add/data'
                          : '$url/api/add/data'),
                      headers: {
                        'Content-Type':
                            'application/json', // Adjust based on image format
                        '_token': widget.token,
                      },
                      body: json.encode({
                        'sys': sysController.text,
                        'dia': diaController.text,
                        'pul': pulController.text
                      }),
                    );
                    if (response.statusCode == 200) {
                      print('Upload successful');
                      var data = jsonDecode(response.body);
                      widget.update(data);
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      print(
                          'Upload failed with status: ${response.statusCode}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Button background color
                    foregroundColor: const Color(0xFF397E6F),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9), // Border radius of 9
                    ),
                  ),
                  child: Text(
                    'submit'.tr(),
                    style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: const Color(0xFF397E6F)), // White text
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.number, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF397E6F), width: 2),
        ),
      ),
    );
  }
}
