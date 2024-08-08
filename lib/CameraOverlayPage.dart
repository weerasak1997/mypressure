import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';

class CameraOverlayPage extends StatefulWidget {
  @override
  _CameraOverlayPageState createState() => _CameraOverlayPageState();
}

class _CameraOverlayPageState extends State<CameraOverlayPage> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  final GlobalKey _overlay_1 = GlobalKey();
  final GlobalKey _overlay_2 = GlobalKey();
  final GlobalKey _overlay_3 = GlobalKey();
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
        if (orientation != null) {
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
      }
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    width = width * devicePixelRatio;
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
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 36,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.fromLTRB(26, 16, 16, 16),
                        backgroundColor: Colors.black
                            .withOpacity(0.7), // Button background color
                      ),
                    ),
                  ),
                ),
                // width <= 1280
                (width <= 720
                    ? _getOverlay(300, 145, 1, 300)
                    : _getOverlay(240, 140, 1, 252)),
                (width <= 720
                    ? _getOverlay(300, 145, 2, 0)
                    : _getOverlay(240, 120, 2, 0)),
                (width <= 720
                    ? _getOverlay(300, 145, 3, 300)
                    : _getOverlay(240, 120, 3, 232)),
                // Centered square overlay
                // Center(
                //   child: Container(
                //     key: _overlay_1,
                //     margin: const EdgeInsets.only(bottom: 300),
                //     width: 300, // Width of the square
                //     height: 145, // Height of the square
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.green, width: 3),
                //       borderRadius:
                //           BorderRadius.circular(8), // Optional: rounded corners
                //     ),
                //   ),
                // ),
                // Center(
                //   child: Container(
                //     key: _overlay_2,
                //     width: 300, // Width of the square
                //     height: 145, // Height of the square
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.green, width: 3),
                //       borderRadius:
                //           BorderRadius.circular(8), // Optional: rounded corners
                //     ),
                //   ),
                // ),
                // Center(
                //   child: Container(
                //     key: _overlay_3,
                //     margin: const EdgeInsets.only(top: 300),
                //     width: 300, // Width of the square
                //     height: 145, // Height of the square
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.green, width: 3),
                //       borderRadius:
                //           BorderRadius.circular(8), // Optional: rounded corners
                //     ),
                //   ),
                // ),
                // Centered button at the bottom

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
                          final XFile? image = await _controller.takePicture();
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
                            var overlayRegion1;
                            if (position1 != null) {
                              overlayRegion1 = img.copyCrop(
                                imageDecode,
                                (position1.dx * scaleX).toInt(),
                                (position1.dy * scaleY).toInt(),
                                ((width <= 720 ? 300 : 240) * scaleX).toInt(),
                                ((width <= 720 ? 145 : 140) * scaleY).toInt(),
                              );
                            } else {
                              // Handle the case where position1 is null
                              print('position1 is null');
                            }
                            var overlayRegion2;
                            if (position2 != null) {
                              overlayRegion2 = img.copyCrop(
                                imageDecode,
                                (position2.dx * scaleX).toInt(),
                                (position2.dy * scaleY).toInt(),
                                ((width <= 720 ? 300 : 240) * scaleX).toInt(),
                                ((width <= 720 ? 145 : 120) * scaleY).toInt(),
                              );
                            } else {
                              // Handle the case where position2 is null
                              print('position1 is null');
                            }
                            var overlayRegion3;
                            if (position3 != null) {
                              overlayRegion3 = img.copyCrop(
                                imageDecode,
                                (position3.dx * scaleX).toInt(),
                                (position3.dy * scaleY).toInt(),
                                ((width <= 720 ? 300 : 240) * scaleX).toInt(),
                                ((width <= 720 ? 145 : 120) * scaleY).toInt(),
                              );
                            } else {
                              // Handle the case where position3 is null
                              print('position1 is null');
                            }
                            final croppedImageBytes1 = encodeImageToBytes(
                                overlayRegion1,
                                format: 'png');
                            final croppedImageBytes2 = encodeImageToBytes(
                                overlayRegion2,
                                format: 'png');
                            final croppedImageBytes3 = encodeImageToBytes(
                                overlayRegion3,
                                format: 'png');
                            // Use Navigator to go back and return the image path
                            Navigator.pop(context, {
                              "overlay1": croppedImageBytes1,
                              "overlay2": croppedImageBytes2,
                              "overlay3": croppedImageBytes3,
                            });
                          }
                        } catch (e) {
                          print('Error capturing image: $e');
                        }
                      },
                      child: Icon(
                        Icons.camera_alt,
                        size: 36,
                        color: Colors.white,
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.black
                            .withOpacity(0.7), // Button background color
                      ),
                    ),
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
