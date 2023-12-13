import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_address_from_latlng/flutter_address_from_latlng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mapdemo/customWidgets/custom_text.dart';
import 'package:mapdemo/utils/app_string.dart';

class UserTrackingScreen extends StatefulWidget {
  UserTrackingScreen({Key? key}) : super(key: key);

  @override
  _UserTrackingScreenState createState() => _UserTrackingScreenState();
}

class _UserTrackingScreenState extends State<UserTrackingScreen> {
  late double height, width;
  String startLocation = "", endLocation = "";
  GoogleMapController? mapController;
  final Set<Polygon> _polygon = HashSet<Polygon>();
  Map<MarkerId, Marker> markers = {};
  List<LatLng> polylineCoordinates = [];
  Position? _currentPosition;  // This variable saves the current location of user and displays the marker on map
  Timer? timer;  // This variable manages the lat long of user when tracking is ongoing
  int trackingData = -1;   // This variable manages the start/stop tracking button

  @override
  void initState() {
    super.initState();
    getPermission();
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: _currentPosition == null
          ? const Center(
              child: Text(AppStrings.strLoading),
            )
          : SafeArea(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentPosition!.latitude,
                          _currentPosition!.longitude),
                      zoom: 12,
                    ),
                    myLocationEnabled: true,
                    tiltGesturesEnabled: true,
                    compassEnabled: true,
                    scrollGesturesEnabled: true,
                    zoomGesturesEnabled: true,
                    onMapCreated: _onMapCreated,
                    markers: Set<Marker>.of(markers.values),
                    polygons: _polygon,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        top: 15,
                      ),
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: trackingData == 1 ? height * 0.3 : height * 0.13,
                      width: width,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 15,
                          right: 15,
                          top: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Visibility(
                              visible: trackingData == 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      containerWithHeigh8Width8(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      buildContainerWithBorder(),
                                      sizedBox5(),
                                      containerWithHeigh8Width8(),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.strStartLocation,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            ?.copyWith(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                      ),
                                      sizedBox5(),
                                      CustomTextWidget(text: startLocation),
                                      const SizedBox(
                                        height: 25,
                                      ),
                                      Text(
                                        AppStrings.strEndLocation,
                                        style: Theme.of(context)
                                            .textTheme
                                            .caption
                                            ?.copyWith(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                      ),
                                      sizedBox5(),
                                      CustomTextWidget(text: endLocation),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: width,
                              padding: const EdgeInsets.only(
                                  bottom: 16.0, left: 32.0, right: 32.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  trackingData == -1 || trackingData == 1
                                      ? trackUserLocations()
                                      : stopTrackUserLocation();
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey),
                                child: Text(
                                    trackingData == 0
                                        ? AppStrings.strStop
                                        : AppStrings.strStart,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(
      markerId: markerId,
      icon: descriptor,
      position: position,
    );
    markers[markerId] = marker;
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;

        _addMarker(LatLng(position.latitude, position.longitude), 'source',
            BitmapDescriptor.defaultMarker);

        // Update the map with the current location
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 12.0,
            ),
          ),
        );
      });
      // _getPolyline();
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  _getPolyline() async {
    _polygon.add(Polygon(
      // given polygonId
      polygonId: const PolygonId('1'),
      // initialize the list of points to display polygon
      points: polylineCoordinates,
      // given color to polygon
      fillColor: Colors.blueAccent.withOpacity(0.3),
      // given border color to polygon
      strokeColor: Colors.blueAccent,
      geodesic: true,
      // given width of border
      strokeWidth: 4,
    ));
  }

  Future<void> getPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    LocationPermission permissionAccept = await Geolocator.requestPermission();

    _getCurrentLocation();
  }

  void trackUserLocations() async {
    polylineCoordinates.clear();
    setState(() {
      trackingData = 0;
    });
    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentLatLan = LatLng(position.latitude, position.longitude);
      polylineCoordinates.add(currentLatLan);
    });
  }

  void stopTrackUserLocation() async {
    setState(() {
      timer?.cancel();
      trackingData = 1;
    });
    String formattedStartAddress =
        await FlutterAddressFromLatLng().getFormattedAddress(
      latitude: polylineCoordinates.first.latitude,
      longitude: polylineCoordinates.first.longitude,
      googleApiKey: AppStrings.googleApiKey,
    );
    String formattedEndAddress =
        await FlutterAddressFromLatLng().getFormattedAddress(
      latitude: polylineCoordinates.last.latitude,
      longitude: polylineCoordinates.last.longitude,
      googleApiKey: AppStrings.googleApiKey,
    );
    setState(() {
      startLocation = formattedStartAddress;
      endLocation = formattedEndAddress;
    });
    _getPolyline();
  }

  Container containerWithHeigh8Width8() {
    return Container(
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8 / 2),
      ),
    );
  }

  Container buildContainerWithBorder() {
    return Container(
      height: 3,
      width: 3,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(3 / 2),
      ),
    );
  }

  SizedBox sizedBox5() {
    return const SizedBox(
      height: 5,
    );
  }
}
