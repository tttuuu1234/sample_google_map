import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class WalkingRecordConfirmPage extends StatelessWidget {
  const WalkingRecordConfirmPage({
    super.key,
    required this.walkingPolyline,
  });

  final Polyline walkingPolyline;

  @override
  Widget build(BuildContext context) {
    final points = walkingPolyline.points;

    return Scaffold(
      appBar: AppBar(
        title: const Text('確認画面'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('ウォーキング登録のapiのリクエストに設定できる、ウォーキングの緯度、経度'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: points.length,
              itemBuilder: (context, index) {
                final point = points[index];
                final latitude = point.latitude;
                final longitude = point.longitude;
                return Card(
                  child: ListTile(
                    title: Text('$index番目 \n緯度: $latitude \n経度: $longitude'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
