import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' as io;
// import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:image/image.dart' as Img;

import 'package:tflite/tflite.dart';
import 'package:path_provider/path_provider.dart';

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
  io.File _imageCrop;
  io.File image;
  io.File _croppedFile;
  bool isCrop = false;
  double width = 300;
  Widget wimage;
  String tempPath;

  // Tflite
  List _recognitions;

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
      // _imageCrop = image;
      setState(() {
        isCrop = false;
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
          model: "assets/yolov2_tiny.tflite",
          labels: "assets/yolov2_tiny.txt",
          numThreads: 1 // defaults to 1
          );
      print('---> sukses load model: $res');
    } on PlatformException {
      print('xxxxxx>> Failed to load model.');
    }

    Directory tempDir = await getTemporaryDirectory();
    tempPath = tempDir.path;

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
  }

  _cropImage() {
    print('---> crop image');
    // setState(() {
    //   _image = null;
    // });

    Img.Image _img = Img.decodeImage(image.readAsBytesSync());
    // Img.Image _img = Img.readJpg(image.readAsBytesSync());

    Img.Image crop = Img.copyCrop(_img, 0, 0, 100, 100);
    // Img.Image thumb = Img.copyResize(_img, 120);
    image.writeAsBytesSync(Img.encodePng(crop));

    io.File result = io.File('$tempPath/result.png')
      ..writeAsBytesSync(Img.encodePng(crop));

    setState(() {
      isCrop = true;
      _imageCrop = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future _detect(io.File img) async {
      var recognitions = await Tflite.detectObjectOnImage(
          path: img.path, // required
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

      print('---> detect : ${recognitions[0]['rect']}');

      double _dx = recognitions[0]['rect']['x'];
      double _dy = recognitions[0]['rect']['y'];
      double _dw = recognitions[0]['rect']['w'];
      double _dh = recognitions[0]['rect']['h'];

      _dx = _dx * 100;
      _dy = _dy * 100;
      _dw = _dw * 10;
      _dh = _dh * 10;

      int _x = _dx.toInt();
      int _y = _dy.toInt();
      int _w = _dw.toInt();
      int _h = _dh.toInt();

      Img.Image _img = Img.decodeImage(img.readAsBytesSync());
      // Img.Image crop = Img.copyCrop(_img, _x, _y, _w, _h);
      Img.Image crop = Img.copyCrop(_img, 5, 5, 100, 100);
      image.writeAsBytesSync(Img.encodePng(crop));

      setState(() {
        // _recognitions = recognitions;

        _image = image;
      });
    }

    Future _recognize() async {
      await _detect(_image);
    }

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
      body: Column(children: <Widget>[
        Expanded(
            flex: 1,
            child: _image == null
                ? Text('no image')
                : Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey,
                    child: Image.file(
                      _image,
                      fit: BoxFit.fill,
                    ),
                  )),
        // Expanded(
        //   flex: 1,
        //   child: isCrop == false
        //       ? Text('no cropped image')
        //       : Image.file(_imageCrop),
        // ),
      ]),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            RaisedButton(
              child: Text('Add Picture'),
              onPressed: showPhotoOptions,
            ),
            // RaisedButton(
            //   child: Text('Crop'),
            //   onPressed: () {
            //     if (_image != null) {
            //       // _recognize();
            //       _cropImage();
            //     }
            //   },
            // ),
            RaisedButton(
              child: Text('Detect'),
              onPressed: () {
                if (_image != null) {
                  _recognize();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
