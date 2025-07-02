import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hungerz_delivery/Account/UI/account_page.dart';
import 'package:hungerz_delivery/Components/bottom_bar.dart';
import 'package:hungerz_delivery/OrderMap/UI/slide_up_panel.dart';
import 'package:hungerz_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:hungerz_delivery/OrderMapBloc/order_map_state.dart';
import 'package:hungerz_delivery/Routes/routes.dart';
import 'package:hungerz_delivery/Services/location_service.dart';
import 'package:hungerz_delivery/Themes/colors.dart';
import 'package:hungerz_delivery/map_utils.dart';

class NewDeliveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: NewDeliveryBody(),
    );
  }
}

class NewDeliveryBody extends StatefulWidget {
  @override
  _NewDeliveryBodyState createState() => _NewDeliveryBodyState();
}

class _NewDeliveryBodyState extends State<NewDeliveryBody> {
  Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  Set<Marker> _markers = {};
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _positionStreamSubscription;
  Marker? _driverMarker;
  final String _driverId = "driver123";

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    _initializeLocationTracking();
  }

  void _initializeLocationTracking() async {
    bool hasPermission = await _locationService.requestPermission();
    if (hasPermission) {
      Position? initialPosition = await _locationService.getCurrentLocation();
      if (initialPosition != null) {
        _updateDriverMarker(initialPosition);
        _locationService.sendLocationToFirebase(_driverId, initialPosition);
      }

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        _updateDriverMarker(position);
        _locationService.sendLocationToFirebase(_driverId, position);
      });
    } else {
      print("Location permission denied.");
    }
  }

  void _updateDriverMarker(Position position) {
    setState(() {
      _driverMarker = Marker(
        markerId: MarkerId("driverMarker"),
        position: LatLng(position.latitude, position.longitude),
        icon: markerss.isNotEmpty ? markerss[0] : BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: "You are here"),
      );
      _markers.removeWhere((m) => m.markerId.value == "driverMarker");
      if (_driverMarker != null) {
        _markers.add(_driverMarker!);
      }
    });
  }

  bool isPicked = false;
  bool isAccepted = false;
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    List<String?> itemName = [
      "Sandwich",
      "Chicken",
      "Juice",
    ];
    return Scaffold(
      drawer: Account(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: AppBar(
            title: Text("New Delivery Task",
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium!
                    .copyWith(fontWeight: FontWeight.w500)),
            actions: <Widget>[
              isAccepted
                  ? Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
                      child: TextButton.icon(
                        icon: Icon(
                          isOpen ? Icons.close : Icons.shopping_basket,
                          color: kMainColor,
                          size: 13.0,
                        ),
                        label: Text(
                            isOpen
                                ? "Close"
                                : "Order Info",
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontSize: 11.7,
                                      fontWeight: FontWeight.bold,
                                      color: kMainColor,
                                    )),
                        onPressed: () {
                          setState(() {
                            if (isOpen)
                              isOpen = false;
                            else
                              isOpen = true;
                          });
                        },
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Expanded(
                child: BlocBuilder<OrderMapBloc, OrderMapState>(
                    builder: (context, state) {
                  print('polyyyy' + (state.polylines ?? const {}).toString());
                  return GoogleMap(
                    polylines: state.polylines ?? const {},
                    mapType: MapType.normal,
                    initialCameraPosition: kGooglePlex,
                    markers: _markers,
                    style: mapStyle,
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController.complete(controller);
                      mapStyleController = controller;
                      setState(() {
                        _markers.add(
                          Marker(
                            markerId: MarkerId('mark1'),
                            position:
                                LatLng(37.42796133580664, -122.085749655962),
                            icon: markerss.first,
                          ),
                        );
                        _markers.add(
                          Marker(
                            markerId: MarkerId('mark2'),
                            position:
                                LatLng(37.42496133180663, -122.081743655960),
                            icon: markerss[0],
                          ),
                        );
                      });
                    },
                  );
                }),
              ),
              Column(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    height: 50.0,
                    color: kCardBackgroundColor,
                    child: Row(
                      children: [
                        Image.asset(
                          'images/ride.png',
                          color: kMainColor,
                          scale: 1.8,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            '16.5 km ',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    fontSize: 11.7,
                                    letterSpacing: 0.06,
                                    color:
                                        Theme.of(context).secondaryHeaderColor,
                                    fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '(10 min)',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                  fontSize: 11.7,
                                  letterSpacing: 0.06,
                                  color: kLightTextColor),
                        ),
                        Spacer(),
                        isAccepted
                            ? TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                ),
                                onPressed: () {
                                  /*...*/
                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.navigation,
                                      color: kMainColor,
                                      size: 14.0,
                                    ),
                                    SizedBox(
                                      width: 8.0,
                                    ),
                                    Text(
                                      "Direction",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color: kMainColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.7,
                                              letterSpacing: 0.06),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(
                              left: 28.0, bottom: 6.0, top: 6.0, right: 10.0),
                          child: Icon(
                            Icons.location_on,
                            size: 14.0,
                            color: kMainColor,
                          )),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Store",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      letterSpacing: 0.05,
                                      fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              '1024, Hemiltone Street, USA',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontSize: 11.0, letterSpacing: 0.05),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.message,
                                  color: kMainColor,
                                  size: 14.0,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, PageRoutes.chatPageRestaurant);
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.phone,
                                  color: kMainColor,
                                  size: 14.0,
                                ),
                                onPressed: () {
                                  /*...........*/
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 5.0,
                  ),
                  Row(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(
                              left: 28.0, bottom: 12.0, top: 12.0, right: 10.0),
                          child: Icon(
                            Icons.navigation,
                            size: 14.0,
                            color: kMainColor,
                          )),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Sam Smith',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      letterSpacing: 0.05,
                                      fontWeight: FontWeight.bold),
                            ),
                            SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              'D-32, Deniel Street, USA',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontSize: 11.0, letterSpacing: 0.05),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: Icon(
                                  Icons.message,
                                  color: kMainColor,
                                  size: 14.0,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, PageRoutes.chatPageUser);
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.phone,
                                  color: kMainColor,
                                  size: 14.0,
                                ),
                                onPressed: () {
                                  /*...........*/
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  isPicked
                      ? BottomBar(
                          text: "Mark as Delivered",
                          onTap: () => Navigator.popAndPushNamed(
                              context, PageRoutes.deliverySuccessful))
                      : isAccepted
                          ? BottomBar(
                              text: "Mark as Picked",
                              onTap: () {
                                setState(() {
                                  isPicked = true;
                                });
                              })
                          : BottomBar(
                              text: "Accept Delivery",
                              onTap: () {
                                setState(() {
                                  isAccepted = true;
                                });
                              }),
                ],
              )
            ],
          ),
          isOpen ? OrderInfoContainer(itemName) : SizedBox.shrink(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapStyleController?.dispose();
    super.dispose();
  }
}
