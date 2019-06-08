import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
// import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:image/image.dart' as Img;

import 'package:tflite/tflite.dart';

enum PhotoSource {
  camera,
  gallery,
}

class Camera3Page extends StatefulWidget {
  @override
  _Camera3PageState createState() => _Camera3PageState();
}

class _Camera3PageState extends State<Camera3Page> {
  double _maxSize = 640;
  io.File _image;
  io.File _croppedFile;
  double width = 300;
  Widget wimage;

  requestPermission(Permission p) async {
    PermissionStatus res = await SimplePermissions.requestPermission(p);

    if (res == PermissionStatus.authorized) {
      if (p == Permission.Camera) {
        getImage(PhotoSource.camera);
      } else if (p == Permission.PhotoLibrary) {
        getImage(PhotoSource.gallery);
      }
    }
  }

  checkPermission(Permission p) async {
    bool res = await SimplePermissions.checkPermission(p);
    print("permission is " + res.toString());

    if (!res) {
      requestPermission(p);
    } else {
      getImage(PhotoSource.camera);
    }
  }

  Future getImage(PhotoSource _source) async {
    io.File image;

    if (_source == PhotoSource.camera) {
      image = await ImagePicker.pickImage(
          source: ImageSource.camera, maxHeight: _maxSize, maxWidth: _maxSize);
    } else {
      image = await ImagePicker.pickImage(
          source: ImageSource.gallery, maxHeight: _maxSize, maxWidth: _maxSize);
    }

    if (image != null) {
      // Img.Image img = Img.decodeImage(image.readAsBytesSync());
      // Img.Image crop = Img.copyCrop(img, 0, 0, 100, 100);
      // image.writeAsBytesSync(Img.encodePng(crop));
      setState(() {
        _image = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModelAndLabels();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future _loadModelAndLabels() async {
    Tflite.close();
    String res;

    try {
      res = await Tflite.loadModel(
          model: "assets/mobilenet_v1_1.0_224.tflite",
          labels: "assets/labels.txt",
          numThreads: 1 // defaults to 1
          );
      print(res);
    } on PlatformException {
      print('xxxxxx>> Failed to load model.');
    }
  }

  _detect(io.File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, // required
        model: "YOLO",
        imageMean: 0.0,
        imageStd: 255.0,
        threshold: 0.3, // defaults to 0.1
        numResultsPerClass: 2, // defaults to 5
        // anchors: anchors, // defaults to [0.57273,0.677385,1.87446,2.06253,3.33843,5.47434,7.88282,3.52778,9.77052,9.16828]
        blockSize: 32, // defaults to 32
        numBoxesPerBlock: 5, // defaults to 5
        asynch: true // defaults to true
        );
    print('---> detect : $recognitions');
  }

  @override
  Widget build(BuildContext context) {
    void showPhotoOptions() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Pilih sumber foto"),
            actions: <Widget>[
              FlatButton(
                child: Text("Kamera"),
                onPressed: () {
                  if (io.Platform.isAndroid) {
                    checkPermission(Permission.Camera);
                  } else if (io.Platform.isIOS) {
                    getImage(PhotoSource.camera);
                  }
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text("Galeri"),
                onPressed: () {
                  // api 19+ no need permissions
                  getImage(PhotoSource.gallery);
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Image Cropper'),
      ),
      body: Center(
        child: _image == null ? Text('no image') : Image.file(_image),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            RaisedButton(
              child: Text('Add Picture'),
              onPressed: showPhotoOptions,
            ),
            RaisedButton(
              child: Text('Detect'),
              onPressed: () {
                _detect(_image);
              },
            ),
          ],
        ),
      ),
    );
  }
}
