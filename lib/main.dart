import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:sample_google_map/model.dart';

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
  bool isShowFirst = true;
  FocusNode focusNode = FocusNode();
  var predictions = <PlaceModel>[];
  PlaceDetailModel? placeDetail;
  late TextEditingController textEditingController;
  late GoogleMapController _controller;
  late StreamSubscription<Position> positionStream;
  final apiKey = const String.fromEnvironment('iosGoogleMapApiKey');
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
    textEditingController = TextEditingController();
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

  void showFirst() {
    setState(() {
      isShowFirst = true;
    });
  }

  void hideFirst() {
    setState(() {
      isShowFirst = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedCrossFade(
            firstChild: SizedBox(
              height: MediaQuery.sizeOf(context).height,
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onTap: (argument) {
                  print('タップしました');
                },
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
            ),
            secondChild: Container(
              padding: const EdgeInsets.only(top: 80),
              height: MediaQuery.sizeOf(context).height,
              child: ListView.builder(
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final place = predictions[index];
                  return ListTile(
                    title: Text(place.mainText),
                    onTap: () async {
                      final response = await Dio().get(
                        'https://maps.googleapis.com/maps/api/place/details/json?placeid=${place.id}&key=$apiKey',
                      );
                      setState(() {
                        placeDetail = PlaceDetailModel.fromJson(
                          response.data as Map<String, dynamic>,
                        );
                      });
                      log(placeDetail!.lat.toString());
                      log(placeDetail!.lng.toString());
                    },
                  );
                },
              ),
            ),
            crossFadeState: isShowFirst
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
          Positioned(
            top: 80,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.9,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 3,
                    color: Colors.grey,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: textEditingController,
                focusNode: focusNode,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: 'ここで検索',
                  prefixIcon: isShowFirst
                      ? const Icon(Icons.pin_drop)
                      : IconButton(
                          onPressed: () {
                            showFirst();
                            focusNode.unfocus();
                          },
                          icon: const Icon(Icons.arrow_back),
                        ),
                  suffixIcon: const Icon(Icons.mic),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onChanged: (value) async {
                  log('検索するよー');
                  final response = await Dio().get(
                    'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$value&key=$apiKey',
                  );
                  log(response.data['predictions'].toString());
                  final list = response.data['predictions'] as List;
                  setState(() {
                    predictions =
                        list.map((e) => PlaceModel.fromJson(e)).toList();
                  });
                },
                onTap: () {
                  hideFirst();
                },
              ),
            ),
          ),
        ],
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
