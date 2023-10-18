import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sample_google_map/model.dart';
import 'package:sample_google_map/walking_record_confirm_page.dart';
import 'package:uuid/uuid.dart';

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
  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};
  late TextEditingController textEditingController;
  late GoogleMapController _controller;
  late StreamSubscription<Position> positionStream;
  final apiKey = const String.fromEnvironment('iosGoogleMapApiKey');
  //初期位置
  late CameraPosition _kGooglePlex;
  final locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );
  bool isRecordingWalk = false;
  bool isLoading = false;
  Timer? timer;
  var time = DateTime.utc(0, 0, 0);
  var _walkingPolyline = const Polyline(
    polylineId: PolylineId('walking'),
    points: [],
    color: Colors.blue,
  );

  @override
  void initState() {
    super.initState();
    startLoading();
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
    });
    Geolocator.getCurrentPosition().then((value) {
      setState(() {
        _kGooglePlex = CameraPosition(
          target: LatLng(
            value.latitude,
            value.longitude,
          ),
          zoom: 16,
        );
        currentPosition = value;
      });
      finishLoading();
    });
    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        currentPosition = position;
        print('位置情報のリアルタイム取得中');
        print(
          '${position.latitude.toString()}, ${position.longitude.toString()}',
        );

        setState(() {
          _walkingPolyline = _walkingPolyline.copyWith(
            pointsParam: [
              ..._walkingPolyline.points,
              LatLng(
                currentPosition!.latitude,
                currentPosition!.longitude,
              ),
            ],
          );
          print(_walkingPolyline.mapsId);
          print(_walkingPolyline.points);
          polyLines.add(_walkingPolyline);
        });

        for (var element in polyLines) {
          print(element.points);
        }
      },
      onError: (error) {
        print('エラーです');
        print(error);
      },
    );
    positionStream.pause();
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

  void addMarker(PlaceDetailModel placeDetail) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(placeDetail.id),
          position: LatLng(placeDetail.lat, placeDetail.lng),
        ),
      );
    });
  }

  void startLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void finishLoading() {
    setState(() {
      isLoading = false;
    });
  }

  void startRecordWalking() {
    setState(() {
      isRecordingWalk = true;
    });
  }

  void finishRecordWalking() {
    setState(() {
      isRecordingWalk = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Stack(
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
                      markers: markers,
                      polylines: polyLines,
                      onMapCreated: (GoogleMapController controller) {
                        _controller = controller;
                      },
                    ),
                  ),
                  secondChild: Container(
                    padding: const EdgeInsets.only(top: 80),
                    height: MediaQuery.sizeOf(context).height,
                    child: _buildPlaceListView(),
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
                    child: _buildSearchTextField(),
                  ),
                ),
                if (isShowFirst && placeDetail != null && !isRecordingWalk)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: MediaQuery.sizeOf(context).height * 0.4,
                      width: MediaQuery.sizeOf(context).width,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(placeDetail == null ? '' : placeDetail!.name),
                          _buildRouteButton(),
                          _buildWalkingRouteButton(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomSheet: isRecordingWalk
          ? Container(
              height: MediaQuery.sizeOf(context).height * 0.2,
              width: MediaQuery.sizeOf(context).width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Text('${currentPosition!.latitude}'),
                  Center(
                    child: Text(time.second.toString()),
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: isShowFirst
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () async => await _showRecordWalkingDialog(),
                  child: Icon(
                    isRecordingWalk ? Icons.stop_circle : Icons.directions_walk,
                  ),
                ),
                const SizedBox(height: 24),
                FloatingActionButton(
                  onPressed: () async => await _zoomCameraLocationToCenter(),
                  child: const Icon(Icons.location_on),
                ),
              ],
            )
          : null,
    );
  }

  ElevatedButton _buildWalkingRouteButton() {
    return ElevatedButton(
      onPressed: () {
        // final targetPoints = _polyline!.points;
        final targetPoints = [
          const LatLng(35.70133, 140.02959),
          const LatLng(35.7013, 140.02947),
          const LatLng(35.70125, 140.02947),
          const LatLng(35.70106, 140.02924),
          const LatLng(35.70086, 140.029),
          const LatLng(35.70068, 140.02878),
          const LatLng(35.70079, 140.02864),
          const LatLng(35.70099, 140.02841),
          const LatLng(35.70094, 140.02835),
          const LatLng(35.70103, 140.02823),
          const LatLng(35.70118, 140.02806),
        ];
        final polyline = Polyline(
          polylineId: const PolylineId('2'),
          points: targetPoints,
          color: Colors.blue,
        );

        setState(() {
          polyLines.add(polyline);
        });
        print(polyLines.length);
      },
      child: const Text('ウォーキング経路'),
    );
  }

  ElevatedButton _buildRouteButton() {
    return ElevatedButton(
      onPressed: () async {
        final destination = PointLatLng(
          placeDetail!.lat,
          placeDetail!.lng,
        );
        final response = await PolylinePoints().getRouteBetweenCoordinates(
          apiKey,
          PointLatLng(currentPosition!.latitude, currentPosition!.longitude),
          destination,
          travelMode: TravelMode.walking,
        );

        log(response.toString());
        log(response.points.length.toString());
        log(response.distance ?? '');
        log(response.distanceText ?? '');
        log(response.distanceValue.toString());
        log(response.durationValue.toString());
        final points = response.points.map((e) {
          print('緯度、経度');
          final latlng = LatLng(e.latitude, e.longitude);
          print(latlng.latitude);
          print(latlng.longitude);
          return latlng;
        }).toList();
        print(points);
        final polyline = Polyline(
          polylineId: const PolylineId('target'),
          points: points,
          color: Colors.red,
        );
        setState(() {
          polyLines.add(polyline);
        });
      },
      child: const Text('経路'),
    );
  }

  TextField _buildSearchTextField() {
    return TextField(
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
          predictions = list.map((e) => PlaceModel.fromJson(e)).toList();
        });
      },
      onTap: () {
        hideFirst();
      },
    );
  }

  ListView _buildPlaceListView() {
    return ListView.builder(
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
            focusNode.unfocus();
            showFirst();
            addMarker(placeDetail!);
            if (!context.mounted) {
              return;
            }

            await _controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(
                    placeDetail!.lat,
                    placeDetail!.lng,
                  ),
                  zoom: 16,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 現在地をカメラで画面中央に表示させる
  Future<void> _zoomCameraLocationToCenter() async {
    try {
      await _controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentPosition == null ? 0 : currentPosition!.latitude,
              currentPosition == null ? 0 : currentPosition!.longitude,
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

  /// 歩数記録開始・停止確認ダイアログの表示
  Future<void> _showRecordWalkingDialog() async {
    await showAdaptiveDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        if (isRecordingWalk) {
          return WalkingRecordStopDialog(
            onPressed: () {
              positionStream.cancel();
              finishRecordWalking();
              timer!.cancel();
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => WalkingRecordConfirmPage(
                    walkingPolyline: _walkingPolyline,
                  ),
                ),
              );
            },
          );
        }

        return WalkingRecordStartDialog(
          onPressed: () {
            startRecordWalking();
            positionStream.resume();
            timer = Timer.periodic(
              const Duration(seconds: 1),
              (value) {
                print('タイマー');
                setState(() {
                  time = time.add(
                    const Duration(seconds: 1),
                  );
                });
              },
            );
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class WalkingRecordStartDialog extends StatelessWidget {
  const WalkingRecordStartDialog({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text(
        'ウォーキングの記録を開始しますが、よろしいでしょうか？',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: onPressed,
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class WalkingRecordStopDialog extends StatelessWidget {
  const WalkingRecordStopDialog({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text(
        'ウォーキングの記録を停止しますが、よろしいでしょうか？',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: onPressed,
          child: const Text('OK'),
        ),
      ],
    );
  }
}
