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
  _CatPhotoRowState createState() => _CatPhotoRowState(futurePhoto: photo);
}

class _CatPhotoRowState extends State<CatPhotoRow> {
  final Future<Photo> futurePhoto;
  Photo _photo;

  OverlayEntry _overlayEntry;
  bool _focused = false;

  final LayerLink _layerLink = LayerLink();
  // final ScrollController _scrollController = ScrollController();

  _CatPhotoRowState({this.futurePhoto});

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
                child: ScorerList(
                  photo: _photo
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
    return CompositedTransformTarget(
      link: this._layerLink,
      child: ListTile(
        title: FutureBuilder<Photo>(
          future: futurePhoto,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _photo = snapshot.data;
              return Image.memory(base64Decode(snapshot.data.imageData));
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
        onLongPress: () async {
          var saved = await saveFile(_photo.name, base64Decode(_photo.imageData));
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

class ScorerList extends StatefulWidget {
  final Photo photo;

  ScorerList({this.photo});

  @override
  _ScorerListState createState() => _ScorerListState(
    photo: this.photo,
    selectedScore: this.photo.score,
  );
}

class _ScorerListState extends State<ScorerList> {
  static const ScorerRowNames = {"angry", "bad-data", "garbage", "happy", "none", "romantic/love", "sad", "spooked", "violent"};

  final Photo photo;

  int selectedScore;

  _ScorerListState({this.photo, this.selectedScore});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 180.0,
        // child: Scrollbar(
        //   isAlwaysShown: true,
        //   controller: this._scrollController,
        child: ListView.builder(
          itemCount: ScorerRowNames.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, i) {
            String currentScoreText = ScorerRowNames.elementAt(i);
            return ListTile(
              title: Text("$currentScoreText"),
              onTap: () {
                setState(() {
                  selectedScore = i;
                });
              },
              trailing: Icon(
                (selectedScore == i) ? Icons.check : Icons.check_outlined,
                color: (selectedScore == i) ? Colors.blue : Colors.black12,
              ),
            );
          },
        )
      // ),
    );
  }
}
