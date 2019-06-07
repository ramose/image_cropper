import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:image_cropper/image_cropper.dart';

enum PhotoSource {
  camera,
  gallery,
}

class Camera1Page extends StatefulWidget {
  @override
  _Camera1PageState createState() => _Camera1PageState();
}

class _Camera1PageState extends State<Camera1Page> {
  double _maxSize = 640;
  File _image;
  File _croppedFile;

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
    File image;

    if (_source == PhotoSource.camera) {
      image = await ImagePicker.pickImage(
          source: ImageSource.camera, maxHeight: _maxSize, maxWidth: _maxSize);
    } else {
      image = await ImagePicker.pickImage(
          source: ImageSource.gallery, maxHeight: _maxSize, maxWidth: _maxSize);
    }

    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  Future<Null> _cropImage(File imageFile) async {
    File croppedFile = await ImageCropper.cropImage(
      sourcePath: imageFile.path,
      ratioX: 1.0,
      ratioY: 1.0,
      maxWidth: 512,
      maxHeight: 512,
    );

    setState(() {
      _croppedFile = croppedFile;
    });
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
                  if (Platform.isAndroid) {
                    checkPermission(Permission.Camera);
                  } else if (Platform.isIOS) {
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
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: _image == null
                ? Center(
                    child: Text('no image'),
                  )
                : Image.file(
                    File(_image.path),
                    fit: BoxFit.cover,
                  ),
          ),
          Expanded(
            flex: 1,
            child: _croppedFile == null
                ? Center(
                    child: Text('no cropped image'),
                  )
                : Image.file(
                    File(_croppedFile.path),
                    fit: BoxFit.cover,
                  ),
          )
        ],
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
              child: Text('Crop'),
              onPressed: () {
                _cropImage(_image);
              },
            ),
          ],
        ),
      ),
    );
  }
}
