import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Components/custom_appbar.dart';
import 'package:hungerz/Components/entry_field.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Maps/Components/address_type_button.dart';
import 'package:hungerz/OrderMapBloc/order_map_bloc.dart';
import 'package:hungerz/OrderMapBloc/order_map_state.dart';
import 'package:hungerz/Routes/routes.dart';
import 'package:hungerz/map_utils.dart';

TextEditingController _addressController = TextEditingController();

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: SetLocation(),
    );
  }
}

class SetLocation extends StatefulWidget {
  const SetLocation({super.key});

  @override
  _SetLocationState createState() => _SetLocationState();
}

class _SetLocationState extends State<SetLocation> {
  bool isCard = false;
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  // Set<Marker> _markers = {};

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
//          extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(126.0),
        child: CustomAppBar(
          // titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          titleWidget: Text(
            AppLocalizations.of(context)!.setLocation!,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          onTap: null,
          hint: AppLocalizations.of(context)!.enterLocation,
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                Size.fromHeight(126).height -
                MediaQuery.of(context).padding.top,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
                  height: 8.0,
                ),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      BlocBuilder<OrderMapBloc, OrderMapState>(
                          builder: (context, state) {
                        print('polyyyy${state.polylines}');
                        return GoogleMap(
                          // polylines: state.polylines,
                          mapType: MapType.normal,
                          initialCameraPosition: kGooglePlex,
                          // markers: _markers,
                          style: mapStyle,
                          onMapCreated: (GoogleMapController controller) async {
                            _mapController.complete(controller);
                            mapStyleController = controller;
                            // mapStyleController!.setMapStyle(mapStyle);
                          },
                        );
                      }),
                      Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 36.0),
                            child: FadedScaleAnimation(
                              fadeDuration: Duration(milliseconds: 800),
                              child: Image.asset(
                                'images/map_pin.png',
                                height: 36,
                              ),
                            ),
                          )),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: FadedScaleAnimation(
                            fadeDuration: Duration(milliseconds: 800),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.my_location,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  color: Theme.of(context).cardColor,
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    children: <Widget>[
                      FadedScaleAnimation(
                        fadeDuration: Duration(milliseconds: 800),
                        child: Image.asset(
                          'images/map_pin.png',
                          scale: 2.5,
                        ),
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Expanded(
                        child: Text(
                          '1024,Central Residency Park,Paris, France',
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                isCard ? SaveAddressCard() : Container(),
                BottomBar(
                    text: AppLocalizations.of(context)!.continueText,
                    onTap: () {
                      if (isCard == false) {
                        setState(() {
                          isCard = true;
                        });
                      } else {
                        Navigator.popAndPushNamed(
                            context, PageRoutes.homeOrderAccountPage);
                      }
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AddressType {
  Home,
  Office,
  Other,
}
AddressType selectedAddress = AddressType.Other;

class SaveAddressCard extends StatefulWidget {
  const SaveAddressCard({super.key});

  @override
  _SaveAddressCardState createState() => _SaveAddressCardState();
}

class _SaveAddressCardState extends State<SaveAddressCard> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: EntryField(
                controller: _addressController,
                label: AppLocalizations.of(context)!.addressLabel,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                AppLocalizations.of(context)!.saveAddress!.toUpperCase(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  AddressTypeButton(
                    label: AppLocalizations.of(context)!.homeText,
                    image: 'images/address/ic_homeblk.png',
                    onPressed: () {
                      setState(() {
                        selectedAddress = AddressType.Home;
                      });
                    },
                    isSelected: selectedAddress == AddressType.Home,
                  ),
                  AddressTypeButton(
                    label: AppLocalizations.of(context)!.office,
                    image: 'images/address/ic_officeblk.png',
                    onPressed: () {
                      setState(() {
                        selectedAddress = AddressType.Office;
                      });
                    },
                    isSelected: selectedAddress == AddressType.Office,
                  ),
                  AddressTypeButton(
                    label: AppLocalizations.of(context)!.other,
                    image: 'images/address/ic_otherblk.png',
                    onPressed: () {
                      setState(() {
                        selectedAddress = AddressType.Other;
                      });
                    },
                    isSelected: selectedAddress == AddressType.Other,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
