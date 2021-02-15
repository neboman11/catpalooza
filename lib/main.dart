import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'Photo.dart';
import 'CatPhotoRow.dart';

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
