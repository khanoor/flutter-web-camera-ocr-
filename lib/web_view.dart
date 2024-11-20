import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart'; // For handling JS interop

// Tesseract.js function for OCR
@JS('Tesseract.recognize')
external Object recognizeImage(String imageBase64, String lang);

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  Uint8List? _imageData;
  String? _recognizedText;
  bool isLoading = false;
  String errorMessage = "";

  /// Method to pick an image from the device
  Future<void> _pickImageFromDevice() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final imageBytes = await image.readAsBytes();
      _processImage(imageBytes);
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "No image selected.";
      });
    }
  }

  /// Method to pick an image from the camera
  Future<void> _pickImageFromCamera() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final imageBytes = await image.readAsBytes();
      _processImage(imageBytes);
    } else {
      setState(() {
        isLoading = false;
        errorMessage = "No image captured.";
      });
    }
  }

  /// Process the selected image and perform OCR
  Future<void> _processImage(Uint8List imageBytes) async {
    setState(() {
      _imageData = imageBytes;
      _recognizedText = null;
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
        errorMessage = "Error during OCR: $e";
        isLoading = false;
      });
      if (kDebugMode) {
        print("Error during OCR: $e");
      }
    }
  }

  /// Perform OCR using Tesseract.js
  Future<String> performOCR(String imageBase64) async {
    try {
      // Call the Tesseract.js recognize function
      final jsResult = await promiseToFuture(recognizeImage(imageBase64, 'af'));

      // Use `js_util.getProperty` to access JavaScript object properties safely
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display image preview
                if (_imageData != null)
                  Image.memory(
                    _imageData!,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(height: 20),

                // Display recognized text
                if (_recognizedText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SelectableText(
                      'OCR Text: $_recognizedText',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Display error message if any
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Error: $errorMessage',
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),

                const SizedBox(height: 20),

                // Loading indicator
                if (isLoading) const CircularProgressIndicator(),
                const SizedBox(height: 20),

                // Buttons for picking image
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: isLoading ? null : _pickImageFromDevice,
                      child: const Text('Select Image from Device'),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : _pickImageFromCamera,
                      child: const Text('Capture from Camera'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:js/js.dart';
// import 'package:js/js_util.dart'; // For handling JS interop
// import 'dart:html'; // For accessing the browser's camera

// // Tesseract.js function for OCR
// @JS('Tesseract.recognize')
// external Object recognizeImage(String imageBase64, String lang);

// class WebViewScreen extends StatefulWidget {
//   const WebViewScreen({Key? key}) : super(key: key);

//   @override
//   _WebViewScreenState createState() => _WebViewScreenState();
// }

// class _WebViewScreenState extends State<WebViewScreen> {
//   Uint8List? _imageData;
//   String? _recognizedText;
//   bool isLoading = false;
//   String errorMessage = "";

//   // Method to pick an image from the device
//   Future<void> _pickImageFromDevice() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = "";
//     });

//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);

//     if (image != null) {
//       final imageBytes = await image.readAsBytes();
//       _processImage(imageBytes);
//     } else {
//       setState(() {
//         isLoading = false;
//         errorMessage = "No image selected.";
//       });
//     }
//   }

//   // Method to access the camera, capture the image, and process it for OCR
//   Future<void> _pickImageFromCamera() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = "";
//     });

//     try {
//       // Open camera and capture image
//       final imageBytes = await _captureImageFromCamera();

//       if (imageBytes != null) {
//         _processImage(imageBytes);
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = "No image captured.";
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = "Error accessing camera: $e";
//       });
//       if (kDebugMode) {
//         print("Error accessing camera: $e");
//       }
//     }
//   }

//   Future<Uint8List?> _captureImageFromCamera() async {
//     final completer = Completer<Uint8List>();

//     try {
//       // Request camera access
//       final stream = await window.navigator.mediaDevices!
//           .getUserMedia({'video': true, 'audio': false});

//       // Create a video element to capture the image
//       final video = VideoElement()
//         ..autoplay = true
//         ..width = 640
//         ..height = 480;

//       video.srcObject = stream;

//       // Create a canvas to capture the current frame
//       final canvas = CanvasElement(width: 640, height: 480);
//       final context = canvas.context2D;

//       // Wait until the video element is ready
//       await video.onCanPlay.first;

//       // Create a button to take a snapshot
//       final captureButton = ButtonElement()..text = "Capture Image";

//       // When the capture button is clicked, capture the image
//       captureButton.onClick.listen((_) async {
//         // Capture current frame from the video element into the canvas
//         context.drawImage(video, 0, 0);

//         // Convert canvas to a Data URL (base64 image)
//         final imageData = canvas.toDataUrl('image/png');

//         // Convert the Data URL to image bytes (Uint8List)
//         final imageBytes = await _convertDataUrlToBytes(imageData);

//         // Stop the camera stream after capturing the image
//         stream.getTracks().forEach((track) => track.stop());

//         // Complete the future with the image bytes
//         completer.complete(imageBytes);
//       });

//       // Append the video and button to the document body
//       document.body!.append(video);
//       document.body!.append(captureButton);

//       // Wait for the image capture to complete
//       return completer.future;
//     } catch (e) {
//       throw Exception("Failed to access camera: $e");
//     }
//   }

// // Helper function to convert Data URL to bytes (Uint8List)
//   Future<Uint8List> _convertDataUrlToBytes(String dataUrl) async {
//     final base64 = dataUrl.split(',').last; // Extract base64 part
//     return base64Decode(base64); // Decode to bytes
//   }

//   // Process the selected image and perform OCR
//   Future<void> _processImage(Uint8List imageBytes) async {
//     setState(() {
//       _imageData = imageBytes;
//       _recognizedText = null;
//     });

//     final mimeType = imageBytes[0] == 0x89 ? "image/png" : "image/jpeg";
//     final imageBase64 = "data:$mimeType;base64,${base64Encode(imageBytes)}";

//     try {
//       if (kDebugMode) {
//         print("Sending image to Tesseract.js...");
//       }
//       final recognizedText = await performOCR(imageBase64);

//       setState(() {
//         _recognizedText = recognizedText;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = "Error during OCR: $e";
//         isLoading = false;
//       });
//       if (kDebugMode) {
//         print("Error during OCR: $e");
//       }
//     }
//   }

//   // Perform OCR using Tesseract.js
//   Future<String> performOCR(String imageBase64) async {
//     try {
//       // Call the Tesseract.js recognize function
//       final jsResult =
//           await promiseToFuture(recognizeImage(imageBase64, 'eng'));

//       // Use `js_util.getProperty` to access JavaScript object properties safely
//       final data = getProperty(jsResult, 'data');
//       if (data == null) {
//         throw Exception(
//             "Tesseract.js returned an invalid response: Missing 'data'.");
//       }

//       final text = getProperty(data, 'text');
//       if (text == null) {
//         throw Exception(
//             "Tesseract.js returned an invalid response: Missing 'text'.");
//       }

//       return (text as String).trim();
//     } catch (e) {
//       throw Exception("Failed to process OCR: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('OCR with Camera'),
//       ),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Display image preview
//                 if (_imageData != null)
//                   Image.memory(
//                     _imageData!,
//                     fit: BoxFit.cover,
//                   ),
//                 const SizedBox(height: 20),

//                 // Display recognized text
//                 if (_recognizedText != null)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     child: SelectableText(
//                       'OCR Text: $_recognizedText',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),

//                 // Display error message if any
//                 if (errorMessage.isNotEmpty)
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 10),
//                     child: Text(
//                       'Error: $errorMessage',
//                       style: const TextStyle(color: Colors.red, fontSize: 16),
//                     ),
//                   ),

//                 const SizedBox(height: 20),

//                 // Loading indicator
//                 if (isLoading) const CircularProgressIndicator(),
//                 const SizedBox(height: 20),

//                 // Buttons for picking image
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     ElevatedButton(
//                       onPressed: isLoading ? null : _pickImageFromDevice,
//                       child: const Text('Select Image from Device'),
//                     ),
//                     const SizedBox(width: 20),
//                     ElevatedButton(
//                       onPressed: isLoading ? null : _pickImageFromCamera,
//                       child: const Text('Capture from Camera'),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
