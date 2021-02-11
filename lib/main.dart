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

  Future saveFile(String filename, List<int> fileData) async {
    var permissionStatus = await Permission.storage.status;
    if (permissionStatus.isUndetermined || permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      Permission.storage.request();
    }

    permissionStatus = await Permission.storage.status;
    if (permissionStatus.isGranted) {
      File file = File("/storage/emulated/0/Pictures/$filename");
      file.writeAsBytes(fileData);
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
    Photo photoTmp;
    return ListTile(
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
        await saveFile(photoTmp.name, base64Decode(photoTmp.imageData));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Image saved.")
        ));
      },
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
