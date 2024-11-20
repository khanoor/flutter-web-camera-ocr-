
import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scalable_ocr/flutter_scalable_ocr.dart';

List readedText = [];

class MobileViewScreen extends StatefulWidget {
  const MobileViewScreen({super.key,});

  

  @override
  State<MobileViewScreen> createState() => _MobileViewScreenState();
}

class _MobileViewScreenState extends State<MobileViewScreen> {
  String text = "";
  final StreamController<String> controller = StreamController<String>();
  bool torchOn = false;
  int cameraSelection = 0;
  bool lockCamera = true;
  bool loading = false;
  final GlobalKey<ScalableOCRState> cameraKey = GlobalKey<ScalableOCRState>();

  void setText(value) {
    controller.add(value);
  }

  @override
  void dispose() {
    controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OCR'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              !loading
                  ? ScalableOCR(
                      key: cameraKey,
                      torchOn: torchOn,
                      cameraSelection: 0,
                      lockCamera: true,
                      paintboxCustom: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 4.0
                        ..color = const Color.fromARGB(153, 102, 160, 241),
                      boxLeftOff: 5,
                      boxBottomOff: 2.5,
                      boxRightOff: 5,
                      boxTopOff: 2.5,
                      boxHeight: 500,
                      getRawData: (value) {
                        inspect(value);
                      },
                      getScannedText: (value) {
                        setText(value);
                      })
                  : Padding(
                      padding: const EdgeInsets.all(17.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        height: MediaQuery.of(context).size.height / 3,
                        width: MediaQuery.of(context).size.width,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
              StreamBuilder<String>(
                  stream: controller.stream,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    return Column(
                      children: [
                        Result(
                            text: snapshot.data != null ? snapshot.data! : ""),
                        ElevatedButton(
                            onPressed: () {
                              setState(() {
                                addOCRText(snapshot.data != null
                                    ? snapshot.data!
                                    : "null");
                                if (kDebugMode) {
                                  print(
                                      "objectAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
                                }
                              });
                            },
                            child: Text("add data"))
                      ],
                    );
                  }),
              Text('${ocrText}'),
            ],
          ),
        ),
      ),
    );
  }

  void addOCRText(value) {
    setState(() {
      ocrText.add(value);
    });
  }

  List<dynamic> ocrText = ['DATA: '];
}

class Result extends StatelessWidget {
  const Result({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      "OCR TEXT:-  $text",
      style: TextStyle(fontSize: 20),
    );
  }
}

