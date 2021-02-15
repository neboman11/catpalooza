import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'Photo.dart';

class CatPhotoRow extends StatefulWidget {
  final Future<Photo> photo;
  CatPhotoRow({this.photo});

  @override
  _CatPhotoRowState createState() => _CatPhotoRowState(photo: photo);
}

class _CatPhotoRowState extends State<CatPhotoRow> {
  final Future<Photo> photo;

  OverlayEntry _overlayEntry;
  bool _focused = false;

  final LayerLink _layerLink = LayerLink();
  // final ScrollController _scrollController = ScrollController();

  _CatPhotoRowState({this.photo});

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject();
    var size = renderBox.size;

    return OverlayEntry(
        builder: (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: this._layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 5.0),
              child: Material(
                elevation: 4.0,
                child: Container(
                  height: 180.0,
                  // child: Scrollbar(
                  //   isAlwaysShown: true,
                  //   controller: this._scrollController,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: <Widget>[
                      ListTile(
                        title: Text('angry'),
                      ),
                      ListTile(
                        title: Text('bad-data'),
                      ),
                      ListTile(
                        title: Text('garbage'),
                      ),
                      ListTile(
                        title: Text('happy'),
                      ),
                      ListTile(
                        title: Text('none'),
                      ),
                      ListTile(
                        title: Text('romantic/love'),
                      ),
                      ListTile(
                        title: Text('sad'),
                      ),
                      ListTile(
                        title: Text('spooked'),
                      ),
                      ListTile(
                        title: Text('violent'),
                      ),
                    ],
                  ),
                  // ),
                ),
              ),
            )
        )
    );
  }

  Future<bool> saveFile(String filename, List<int> fileData) async {
    var permissionStatus = await Permission.storage.status;
    if (permissionStatus.isUndetermined || permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      Permission.storage.request();
    }

    permissionStatus = await Permission.storage.status;
    if (permissionStatus.isGranted) {
      File file = File("/storage/emulated/0/Pictures/$filename");
      file.writeAsBytes(fileData);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    Photo photoTmp;
    return CompositedTransformTarget(
      link: this._layerLink,
      child: ListTile(
        title: FutureBuilder<Photo>(
          future: photo,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              photoTmp = snapshot.data;
              return Image.memory(base64Decode(snapshot.data.imageData));
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
        onLongPress: () async {
          var saved = await saveFile(photoTmp.name, base64Decode(photoTmp.imageData));
          if (saved) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Image saved.")
            ));
          }
        },
        onTap: () {
          if (_focused) {
            this._overlayEntry.remove();
            _focused = false;
          } else {
            this._overlayEntry = this._createOverlayEntry();
            Overlay.of(context).insert(this._overlayEntry);
            _focused = true;
          }
        },
      ),
    );
  }
}
