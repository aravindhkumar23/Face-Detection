import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Face Detection Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _imageFile;
  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (_imageFile == null)
              ? Center(child: Text('No image selected'))
              : Center(
                  child: FittedBox(
                    child: SizedBox(
                      width: _image.width.toDouble(),
                      height: _image.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(_image, _faces),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: UnicornDialer(
        parentButtonBackground: Colors.blue[700],
        orientation: UnicornOrientation.VERTICAL,
        parentButton: Icon(Icons.add),
        childButtons: _getOptionsMenu(),
      ),
    );
  }

  List<UnicornButton> _getOptionsMenu() {
    List<UnicornButton> children = [];
    children.add(
      _generateOption(
          iconData: Icons.camera_alt,
          onPressed: () {
            _getImageAndDetectFaces(isCamera: true);
          }),
    );
    children.add(
      _generateOption(
          iconData: Icons.insert_drive_file,
          onPressed: () {
            _getImageAndDetectFaces(isCamera: false);
          }),
    );

    return children;
  }

  Widget _generateOption({IconData iconData, Function onPressed}) {
    return UnicornButton(
        currentButton: FloatingActionButton(
      backgroundColor: Colors.blue[500],
      mini: true,
      child: Icon(iconData),
      onPressed: onPressed,
    ));
  }

  void _getImageAndDetectFaces({bool isCamera}) async {
    final imageFile = await ImagePicker.pickImage(
        source: isCamera ? ImageSource.camera : ImageSource.gallery);
    setState(() {
      isLoading = true;
    });
    final image = FirebaseVisionImage?.fromFile(imageFile);
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector?.processImage(image);
    if (mounted) {
      setState(() {
        _imageFile = imageFile;
        _faces = faces;
        _loadImage(imageFile);
      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
