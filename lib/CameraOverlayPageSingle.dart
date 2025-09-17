import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '/component/inputPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class CameraOverlayPageSingle extends StatefulWidget {
  final String token;
  final void Function(dynamic) update;
  const CameraOverlayPageSingle(
      {super.key, required this.token, required this.update});
  @override
  _CameraOverlayPageSingleState createState() =>
      _CameraOverlayPageSingleState();
}

class _CameraOverlayPageSingleState extends State<CameraOverlayPageSingle> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  final GlobalKey _overlay_1 = GlobalKey();
  final GlobalKey _overlay_2 = GlobalKey();
  final GlobalKey _overlay_3 = GlobalKey();
  String url = 'https://mypressure.the8th-floor.com';
  int sys = 0;
  int dia = 0;
  int pul = 0;
  int state = 0;
  @override
  void initState() {
    super.initState();
    // Initialize the camera
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      final camera = cameras.first;

      // Initialize the camera controller
      _controller = CameraController(camera, ResolutionPreset.high);
      _initializeControllerFuture = _controller.initialize();
      setState(() {});
    } catch (e) {
      // Handle initialization errors
      print('Error initializing camera: $e');
    }
  }

  Widget _getOverlay(double width, double height, int type, double position) {
    EdgeInsets? edge;
    switch (type) {
      case 1:
        edge = EdgeInsets.only(bottom: position);
        break;
      case 2:
        edge = EdgeInsets.only(bottom: position);
        break;
      case 3:
        edge = EdgeInsets.only(top: position);
        break;
    }
    // print('w: ' + width.toString());
    // print('H: ' + height.toString());

    return Center(
      child: Container(
        margin: edge,
        child: Container(
          key: (type == 1 ? _overlay_1 : (type == 2 ? _overlay_2 : _overlay_3)),
          width: width, // Width of the square
          height: height, // Height of the square
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 3),
            borderRadius: BorderRadius.circular(8), // Optional: rounded corners
          ),
        ),
      ),
    );
  }

  List<int> encodeImageToBytes(img.Image image, {String format = 'png'}) {
    if (format == 'png') {
      return img.encodePng(image);
    } else if (format == 'jpg') {
      return img.encodeJpg(image);
    } else {
      throw ArgumentError('Unsupported format: $format');
    }
  }

  Future<void> applyRotationFix(String originalPath) async {
    try {
      Map<String?, IfdTag>? data = await readExifFromFile(File(originalPath));
      if (data != null) {
        String orientation = data['Image Orientation'].toString();
        if (orientation.contains('Rotated 90 CW')) {
          img.Image original =
              img.decodeImage(File(originalPath).readAsBytesSync())!;
          img.Image fixed = img.copyRotate(original, 90);
          File(originalPath).writeAsBytesSync(img.encodeJpg(fixed));
        } else if (orientation.contains('Rotated 180 CW')) {
          img.Image original =
              img.decodeImage(File(originalPath).readAsBytesSync())!;
          img.Image fixed = img.copyRotate(original, 180);
          File(originalPath).writeAsBytesSync(img.encodeJpg(fixed));
        } else if (orientation.contains('Rotated 270 CW')) {
          img.Image original =
              img.decodeImage(File(originalPath).readAsBytesSync())!;
          img.Image fixed = img.copyRotate(original, 270);
          File(originalPath).writeAsBytesSync(img.encodeJpg(fixed));
        }
      }
    } catch (e) {
      print(e.toString());
    }
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

  void getDataFrom(var croppedImageBytes1, int type) async {
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
        body: json.encode(type == 1
            ? {
                'image1': base64Encode(croppedImageBytes1),
              }
            : (type == 2
                ? {
                    'image2': base64Encode(croppedImageBytes1),
                  }
                : {
                    'image3': base64Encode(croppedImageBytes1),
                  })),
      );
      if (response.statusCode == 200) {
        print('Upload successful');
        Navigator.of(context).pop();
        var data = jsonDecode(response.body);
        setState(() {
          switch (type) {
            case 1:
              sys = data['sys'] is int
                  ? data['sys']
                  : double.parse(data['sys']).toInt();
              break;
            case 2:
              dia = data['dia'] is int
                  ? data['dia']
                  : double.parse(data['dia']).toInt();
              break;
            case 3:
              pul = data['pul'] is int
                  ? data['pul']
                  : double.parse(data['pul']).toInt();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InputPage(
                      sys: sys.toString(),
                      dia: dia.toString(),
                      pul: pul.toString(),
                      token: widget.token,
                      update: widget.update),
                ),
              );
              break;
          }
          state += 1;
        });
      } else {
        Navigator.of(context).pop();
        print('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context).pop();
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double widthShow = MediaQuery.of(context).size.width;
    double heightShow = MediaQuery.of(context).size.height;
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    double width = widthShow * devicePixelRatio;
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Full-screen camera preview
                Positioned.fill(
                  child: CameraPreview(_controller),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.fromLTRB(26, 16, 16, 16),
                        backgroundColor: Colors.black
                            .withOpacity(0.7), // Button background color
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                (width <= 720
                    ? _getOverlay((62.5 / 100) * widthShow,
                        (14.5 / 100) * heightShow, 2, 0)
                    : _getOverlay(
                        (60 / 100) * widthShow, (12 / 100) * heightShow, 2, 0)),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        Offset? position1, position2, position3;
                        final BuildContext? overlay1 =
                            _overlay_1.currentContext;
                        if (overlay1 != null) {
                          final RenderBox? renderBox =
                              overlay1.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            position1 = renderBox.localToGlobal(Offset.zero);
                          } else {
                            print("RenderBox is null");
                          }
                        }
                        final BuildContext? overlay2 =
                            _overlay_2.currentContext;
                        if (overlay2 != null) {
                          final RenderBox? renderBox =
                              overlay2.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            position2 = renderBox.localToGlobal(Offset.zero);
                          } else {
                            print("RenderBox is null");
                          }
                        }
                        final BuildContext? overlay3 =
                            _overlay_3.currentContext;
                        if (overlay3 != null) {
                          final RenderBox? renderBox =
                              overlay3.findRenderObject() as RenderBox?;
                          if (renderBox != null) {
                            position3 = renderBox.localToGlobal(Offset.zero);
                          } else {
                            print("RenderBox is null");
                          }
                        }
                        var cameraAspectRatio = _controller.value.aspectRatio;
                        final size = MediaQuery.of(context).size;

                        // Calculate the scale factor
                        var scale = size.aspectRatio * cameraAspectRatio;
                        if (scale < 1) scale = 1 / scale;
                        try {
                          // Take picture
                          await _initializeControllerFuture;
                          final XFile image = await _controller.takePicture();
                          if (image != null) {
                            File file = File(image.path);
                            // applyRotationFix(image.path);
                            List<int> fileByte = await file.readAsBytes();
                            img.Image? imageDecode = img.decodeImage(fileByte);
                            // Assuming we know the actual image resolution, e.g., 4000x3000
                            int imageWidth = imageDecode!.width;
                            int imageHeight = imageDecode.height;
                            // Calculate the scale factors
                            final double previewWidth =
                                MediaQuery.of(context).size.width;
                            final double previewHeight =
                                MediaQuery.of(context).size.height;

                            final double scaleX = imageWidth / previewWidth;
                            final double scaleY = imageHeight / previewHeight;

                            img.Image overlayRegion2 =
                                img.copyCrop(imageDecode, 0, 0, 1, 1);
                            if (position2 != null) {
                              overlayRegion2 = img.copyCrop(
                                imageDecode,
                                (position2.dx * scaleX).toInt(),
                                (position2.dy * scaleY).toInt(),
                                ((width <= 720
                                            ? (62.5 / 100) * widthShow
                                            : 240) *
                                        scaleX)
                                    .toInt(),
                                ((width <= 720
                                            ? (14.5 / 100) * widthShow
                                            : 120) *
                                        scaleY)
                                    .toInt(),
                              );
                            } else {
                              // Handle the case where position2 is null
                            }
                            final croppedImageBytes1 =
                                img.encodeJpg(overlayRegion2, quality: 30);
                            // Navigator.pop(context, {
                            //   "overlay1": croppedImageBytes1,
                            // });

                            if (state == 0) {
                              getDataFrom(croppedImageBytes1, 1);
                            } else if (state == 1) {
                              getDataFrom(croppedImageBytes1, 2);
                            } else if (state == 2) {
                              getDataFrom(croppedImageBytes1, 3);
                              // Navigator.pop(context);
                            }
                          }
                        } catch (e) {
                          print('Error capturing image: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.black
                            .withOpacity(0.7), // Button background color
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Center(
                    child: (state > 0
                        ? ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              backgroundColor: Colors.black
                                  .withOpacity(0.7), // Button background color
                            ),
                            child: Text(
                              state.toString(),
                              style: GoogleFonts.roboto(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Section title color
                              ),
                            ),
                          )
                        : null),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
