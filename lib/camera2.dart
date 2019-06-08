import 'package:flutter/material.dart';
import 'dart:io' as io;
// import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:simple_permissions/simple_permissions.dart';
// import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as Img;
// import 'package:extended_image_library/extended_image_library.dart';

enum PhotoSource {
  camera,
  gallery,
}

class Camera2Page extends StatefulWidget {
  @override
  _Camera2PageState createState() => _Camera2PageState();
}

class _Camera2PageState extends State<Camera2Page> {
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
      Img.Image img = Img.decodeImage(image.readAsBytesSync());
      Img.Image crop = Img.copyCrop(img, 0, 0, 100, 100);
      image.writeAsBytesSync(Img.encodePng(crop));
      setState(() {
        _image = image;
      });
    }
  }

  // Future<Null> _cropImage(io.File imageFile) async {
  //   io.File croppedFile = await ImageCropper.cropImage(
  //     sourcePath: imageFile.path,
  //     ratioX: 1.0,
  //     ratioY: 1.0,
  //     maxWidth: 512,
  //     maxHeight: 512,
  //   );

  //   setState(() {
  //     _croppedFile = croppedFile;
  //   });
  // }

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
            // RaisedButton(
            //   child: Text('Crop'),
            //   onPressed: () {
            //     _cropImage(_image);
            //   },
            // ),
          ],
        ),
      ),
    );
  }
}
