import 'dart:async';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sample_google_map/model.dart';

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
    distanceFilter: 100,
  );
  bool isRecordingWalk = false;
  bool isLoading = false;
  Timer? timer;
  var time = DateTime.utc(0, 0, 0);

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
      },
      onError: (error) {
        print('エラーです');
        print(error);
      },
    );
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
                if (isShowFirst && placeDetail != null)
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
                        children: [
                          Text(placeDetail == null ? '' : placeDetail!.name),
                          ElevatedButton(
                            onPressed: () async {
                              const origin = PointLatLng(35.701314, 140.029601);
                              final destination = PointLatLng(
                                placeDetail!.lat,
                                placeDetail!.lng,
                              );
                              final response = await PolylinePoints()
                                  .getRouteBetweenCoordinates(
                                apiKey,
                                origin,
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
                              final poliLine = Polyline(
                                polylineId: const PolylineId('idです'),
                                points: points,
                                color: Colors.red,
                              );
                              setState(() {
                                polyLines.add(poliLine);
                              });
                            },
                            child: const Text('経路'),
                          ),
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
              child: Center(
                child: Text(time.second.toString()),
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
              finishRecordWalking();
              timer!.cancel();
              Navigator.pop(context);
            },
          );
        }

        return WalkingRecordStartDialog(
          onPressed: () {
            startRecordWalking();
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
