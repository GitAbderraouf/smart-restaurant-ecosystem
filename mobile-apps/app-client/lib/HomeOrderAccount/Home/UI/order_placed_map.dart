import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hungerz/HomeOrderAccount/Home/UI/slide_up_panel.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/OrderMapBloc/order_map_bloc.dart';
import 'package:hungerz/OrderMapBloc/order_map_state.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/Themes/style.dart';
import 'package:hungerz/map_utils.dart';

class OrderMapPage extends StatelessWidget {
  const OrderMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: OrderMap(),
    );
  }
}

class OrderMap extends StatefulWidget {
  const OrderMap({super.key});

  @override
  _OrderMapState createState() => _OrderMapState();
}

class _OrderMapState extends State<OrderMap> {
  bool sliderOpen = false;
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    rootBundle.loadString('images/map_style.txt').then((string) {
      mapStyle = string;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120.0),
        child: AppBar(
          titleSpacing: 0.0,
          title: null,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(0.0),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 16.3),
                  child: FadedScaleAnimation(
                    fadeDuration: Duration(milliseconds: 800),
                    child: Image.asset(
                      'images/Restaurants/Layer 1.png',
                      height: 42.3,
                      width: 33.7,
                    ),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.store!,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          letterSpacing: 0.07, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '20 June, 11:35am',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontSize: 11.7,
                          letterSpacing: 0.06,
                          color: Color(0xffc1c1c1)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        FadedScaleAnimation(
                          fadeDuration: Duration(milliseconds: 800),
                          child: Text(
                            AppLocalizations.of(context)!.pickup!,
                            style: orderMapAppBarTextStyle.copyWith(
                                color: kMainColor),
                          ),
                        ),
                        SizedBox(height: 7.0),
                        Text(
                          '\$ 21.00 | ${AppLocalizations.of(context)!.paypal}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(
                                  fontSize: 11.7, color: Color(0xffc1c1c1)),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                BlocBuilder<OrderMapBloc, OrderMapState>(
                    builder: (context, state) {
                  print('polyyyy${state.polylines}');
                  return GoogleMap(
                    polylines: state.polylines,
                    mapType: MapType.normal,
                    initialCameraPosition: kGooglePlex,
                    markers: _markers,
                    style: mapStyle,
                    onMapCreated: (GoogleMapController controller) async {
                      _mapController.complete(controller);
                      mapStyleController = controller;
                      // mapStyleController!.setMapStyle(mapStyle);
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
                sliderOpen
                    ? SizedBox.shrink()
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: ListTile(
                          tileColor: Colors.white,
                          leading: FadedScaleAnimation(
                            fadeDuration: Duration(milliseconds: 800),
                            child: CircleAvatar(
                              radius: 22.0,
                              backgroundImage: AssetImage('images/profile.jpg'),
                            ),
                          ),
                          title: Text(
                            'George Anderson',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          subtitle: Text(
                            'Delivery Partner',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(
                                    fontSize: 11.7,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xffc2c2c2)),
                          ),
                          trailing: FittedBox(
                            fit: BoxFit.fill,
                            child: Row(
                              children: <Widget>[
                                IconButton(
                                  icon: Icon(Icons.message, color: kMainColor),
                                  onPressed: () {
                                    // Navigator.pushNamed(context, PageRoutes.chatPage);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.phone, color: kMainColor),
                                  onPressed: () {
                                    /*.......*/
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                sliderOpen
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: SlideUpPanel())
                    : SizedBox.shrink(),
              ],
            ),
          ),
          Container(
            height: 60.0,
            color: Theme.of(context).cardColor,
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '3 items',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      sliderOpen = !sliderOpen;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    height: 35,
                    width: 125,
                    decoration: BoxDecoration(
                        color: Color(0xffFFEEC8),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: kMainColor)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          sliderOpen ? "Close" : "View Order",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: kMainColor, fontSize: 15),
                        ),
                        Icon(
                          sliderOpen
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          color: kMainColor,
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
