class PlaceModel {
  const PlaceModel._({required this.mainText});

  final String mainText;

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>;
    return PlaceModel._(mainText: structuredFormatting['main_text'].toString());
  }
}

class PlaceListModel {
  const PlaceListModel({required this.list});

  final List<PlaceModel> list;
}
