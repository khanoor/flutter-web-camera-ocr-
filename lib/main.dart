// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:ocr1/mobile_view.dart';
// import 'package:ocr1/web_view.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Scalable OCR',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: kIsWeb ? WebViewScreen() : MobileViewScreen(),
//     );
//   }
// }

import 'dart:convert';
import 'dart:html';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Add this import
import 'package:js/js_util.dart';
import 'package:ocr1/web_view.dart'; // Your custom WebView file

Future<void> main() async {
  runApp(const CameraApp());
}

class CameraApp extends StatefulWidget {
  const CameraApp({super.key});

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Camera and OCR test')),
        body: const AppBody(),
      ),
    );
  }
}

class AppBody extends StatefulWidget {
  const AppBody({super.key});

  @override
  _AppBodyState createState() => _AppBodyState();
}

class _AppBodyState extends State<AppBody> {
  bool cameraAccess = false;
  String? error;
  List<CameraDescription>? cameras;

  @override
  void initState() {
    getCameras();
    super.initState();
  }

  Future<void> getCameras() async {
    try {
      await window.navigator.mediaDevices!
          .getUserMedia({'video': true, 'audio': false});
      setState(() {
        cameraAccess = true;
      });
      final cameras = await availableCameras();
      setState(() {
        this.cameras = cameras;
      });
    } on DomException catch (e) {
      setState(() {
        error = '${e.name}: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (!cameraAccess) {
      return const Center(child: Text('Camera access not granted yet.'));
    }
    if (cameras == null) {
      return const Center(child: Text('Reading cameras'));
    }
    return CameraView(cameras: cameras!);
  }
}

class CameraView extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraView({super.key, required this.cameras});

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  String? error;
  CameraController? controller;
  late CameraDescription cameraDescription = widget.cameras[0];
  Uint8List? imageBytes; // To store the captured image

  String? _recognizedText;
  bool isLoading = false;

  Future<void> initCam(CameraDescription description) async {
    setState(() {
      controller = CameraController(description, ResolutionPreset.max);
    });

    try {
      await controller!.initialize();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initCam(cameraDescription);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final file = await controller!.takePicture();
      final bytes = await file.readAsBytes();

      // Decode image bytes
      img.Image image = img.decodeImage(Uint8List.fromList(bytes))!;

      // Flip the image horizontally (if you want to remove the mirrored effect)
      img.Image flippedImage = img.flipHorizontal(image);

      // Convert flipped image back to bytes
      setState(() {
        imageBytes = Uint8List.fromList(img.encodePng(flippedImage));
      });

      // Process the image for OCR
      _processImage(imageBytes!);
    } catch (e) {
      setState(() {
        error = 'Error capturing image: $e';
      });
    }
  }

  Future<void> _processImage(Uint8List imageBytes) async {
    setState(() {
      _recognizedText = null;
      isLoading = true;
    });

    final mimeType = imageBytes[0] == 0x89 ? "image/png" : "image/jpeg";
    final imageBase64 = "data:$mimeType;base64,${base64Encode(imageBytes)}";

    try {
      if (kDebugMode) {
        print("Sending image to Tesseract.js...");
      }
      final recognizedText = await performOCR(imageBase64);

      setState(() {
        _recognizedText = recognizedText;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "Error during OCR: $e";
        isLoading = false;
      });
    }
  }

  Future<String> performOCR(String imageBase64) async {
    try {
      final jsResult =
          await promiseToFuture(recognizeImage(imageBase64, 'eng'));

      final data = getProperty(jsResult, 'data');
      if (data == null) {
        throw Exception(
            "Tesseract.js returned an invalid response: Missing 'data'.");
      }

      final text = getProperty(data, 'text');
      if (text == null) {
        throw Exception(
            "Tesseract.js returned an invalid response: Missing 'text'.");
      }

      return (text as String).trim();
    } catch (e) {
      throw Exception("Failed to process OCR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (controller == null) {
      return const Center(child: Text('Loading controller...'));
    }
    if (!controller!.value.isInitialized) {
      return const Center(child: Text('Initializing camera...'));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: CameraPreview(controller!)),
          Material(
            child: DropdownButton<CameraDescription>(
              value: cameraDescription,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              onChanged: (CameraDescription? newValue) async {
                if (controller != null) {
                  await controller!.dispose();
                }
                setState(() {
                  controller = null;
                  cameraDescription = newValue!;
                });

                initCam(newValue!);
              },
              items: widget.cameras
                  .map<DropdownMenuItem<CameraDescription>>((value) {
                return DropdownMenuItem<CameraDescription>(
                  value: value,
                  child: Text('${value.name}: ${value.lensDirection}'),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            onPressed: controller == null ? null : takePicture,
            child: const Text('Take picture.'),
          ),
          if (imageBytes != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.memory(imageBytes!), // Display the captured image
            ),
          if (isLoading) const CircularProgressIndicator(),
          if (_recognizedText != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SelectableText(
                'OCR Text: $_recognizedText',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
