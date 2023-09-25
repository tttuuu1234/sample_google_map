import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  Position? currentPosition;
  late GoogleMapController _controller;
  late StreamSubscription<Position> positionStream;
  //初期位置
  final _kGooglePlex = const CameraPosition(
    target: LatLng(35.604560, 140.123154),
    zoom: 14,
  );
  final locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    super.initState();
    Future(() async {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          currentPosition = position;
          print(
            '${position.latitude.toString()}, ${position.longitude.toString()}',
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async => await _zoomCameraLocationToCenter(),
        child: const Icon(Icons.location_on),
      ),
    );
  }

  /// 現在地をカメラで画面中央に表示させる
  Future<void> _zoomCameraLocationToCenter() async {
    await _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            currentPosition == null ? 0 : currentPosition!.latitude,
            currentPosition == null ? 0 : currentPosition!.longitude,
          ),
          zoom: 14,
        ),
      ),
    );
  }
}
