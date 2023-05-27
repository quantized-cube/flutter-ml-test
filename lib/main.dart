import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Text? _text;
  Image? _image;

  // OCRを行う
  Future<void> _ocr() async {
    final pickerFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickerFile == null) {
      return;
    }
    final InputImage imageFile = InputImage.fromFilePath(pickerFile.path);
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.japanese);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(imageFile);
    String text = recognizedText.text;
    /*
    for (TextBlock block in recognizedText.blocks) {
      // ブロック単位で取得したい情報がある場合はここに記載
      for (TextLine line in block.lines) {
        // ライン単位で取得したい情報がある場合はここに記載
      }
    }
    */

    // 画面に反映
    setState(() {
      _text = Text(text);
      _image = Image.file(File(pickerFile.path));
    });

    // リソースの解放
    textRecognizer.close();
  }

  // ラベリングを行う
  Future<void> _labeling() async {
    final pickerFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickerFile == null) {
      return;
    }
    final InputImage imageFile = InputImage.fromFilePath(pickerFile.path);

    final ImageLabelerOptions options =
        ImageLabelerOptions(confidenceThreshold: 0.7);
    final imageLabeler = ImageLabeler(options: options);
    final List<ImageLabel> labels = await imageLabeler.processImage(imageFile);

    String text = "";
    for (ImageLabel label in labels) {
      text +=
          "${label.label} (${(label.confidence * 100).toStringAsFixed(0)}%)\n";
    }

    // 画面に反映
    setState(() {
      _text = Text(text);
      _image = Image.file(File(pickerFile.path));
    });

    // リソースの解放
    imageLabeler.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_text != null) _text!,
              if (_image != null) SafeArea(child: _image!),
            ],
          ),
        ),
        floatingActionButton:
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          FloatingActionButton(
              onPressed: _ocr, child: const Icon(Icons.photo_album)),
          FloatingActionButton(
              onPressed: _labeling, child: const Icon(Icons.photo_camera))
        ]));
  }
}
