import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catpalooza',
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      home: RandomCats()
    );
  }
}

class Photo {
  final int id;
  final String name;
  final String imageData;
  final int size;

  Photo({this.id, this.name, this.imageData, this.size});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      name: json['name'],
      imageData: json['photo'],
      size: json['size'],
    );
  }
}

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


class RandomCats extends StatefulWidget {
  @override
  _RandomCatsState createState() => _RandomCatsState();
}

class _RandomCatsState extends State<RandomCats> {
  final _photos = <Future<Photo>>[];

  Future<Photo> fetchPicture() async {
    final response = await http.get('https://www.nesbitt.rocks/catpalooza/random');

    if (response.statusCode == 200) {
      return Photo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to download image\n' + response.body);
    }
  }

  Widget _buildPhotos() {
    return ListView.builder(
      padding: EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        if (i.isOdd) return Divider();

        final index = i ~/ 2;
        if (index >= _photos.length) {
          _photos.add(fetchPicture());
        }
        return _buildRow(_photos[index]);
      },
    );
  }

  Widget _buildRow(Future<Photo> photo) {
    return CatPhotoRow(
      photo: photo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catpalooza'),
        /*actions: [
          IconButton(icon: Icon(Icons.list), onPressed: _pushSaved),
        ],*/
      ),
      body: _buildPhotos(),
    );
  }
}
