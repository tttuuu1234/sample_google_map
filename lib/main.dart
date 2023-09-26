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
  BitmapDescriptor customMarkerIcon = BitmapDescriptor.defaultMarker;
  late GoogleMapController _controller;
  late StreamSubscription<Position> positionStream;
  //初期位置
  final _kGooglePlex = const CameraPosition(
    target: LatLng(35.604560, 140.123154),
    zoom: 16,
  );
  final locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100,
  );

  @override
  void initState() {
    // BitmapDescriptor.fromAssetImage(
    //   const ImageConfiguration(size: Size(10, 10)),
    //   'assets/S__300580868.jpg',
    // ).then((value) {
    //   setState(() {
    //     print('成功');
    //     print(value);
    //     customMarkerIcon = value;
    //   });
    // });
    Future(() async {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((position) {
        currentPosition = position;
        print(
          '${position.latitude.toString()}, ${position.longitude.toString()}',
        );
      }, onError: (error) {
        print('エラーです');
        print(error);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: {
          Marker(
            markerId: const MarkerId('test1'),
            position: const LatLng(
              35.701314,
              140.029601,
            ),
            infoWindow: const InfoWindow(title: '交差点です'),
            draggable: true,
            icon: customMarkerIcon,
          ),
          const Marker(
            markerId: MarkerId('test2'),
            position: LatLng(
              35.698905419103,
              140.0310452971,
            ),
          ),
        },
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
    try {
      await _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(
              // currentPosition == null ? 0 : currentPosition!.latitude,
              35.701314,
              // currentPosition == null ? 0 : currentPosition!.longitude,
              140.029601,
            ),
            zoom: 16,
          ),
        ),
      );
    } on Exception catch (e) {
      print('エラーーーーー');
      print(e);
    }
  }
}
