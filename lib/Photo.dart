class Photo {
  final int id;
  final String name;
  final String imageData;
  final int size;
  final int score;

  Photo({this.id, this.name, this.imageData, this.size, this.score});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      name: json['name'],
      imageData: json['photo'],
      size: json['size'],
      score: json['score'],
    );
  }
}
