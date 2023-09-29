class PlaceModel {
  const PlaceModel._({required this.id, required this.mainText});

  final String id;
  final String mainText;

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>;
    return PlaceModel._(
      id: json['place_id'].toString(),
      mainText: structuredFormatting['main_text'].toString(),
    );
  }
}

class PlaceDetailModel {
  const PlaceDetailModel._({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;

  factory PlaceDetailModel.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    final location = result['geometry']['location'] as Map<String, dynamic>;
    return PlaceDetailModel._(
      id: result['place_id'].toString(),
      name: result['name'].toString(),
      lat: location['lat'] as double,
      lng: location['lng'] as double,
    );
  }
}
