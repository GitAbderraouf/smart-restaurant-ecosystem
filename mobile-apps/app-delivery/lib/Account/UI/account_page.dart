import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hungerz_delivery/Themes/colors.dart';
import 'package:hungerz_delivery/OrderMapBloc/order_map_bloc.dart';
import 'package:hungerz_delivery/OrderMapBloc/order_map_state.dart';
import 'package:hungerz_delivery/Routes/routes.dart';

class Account extends StatefulWidget {
  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String? number;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kMainColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
      child: ListView(
        children: <Widget>[
          Container(
            child: UserDetails(),
              height: 220.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kMainColor, kMainColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
          ),
          Divider(
              color: kCardBackgroundColor,
              thickness: 1.0,
          ),
          BuildListTile(
              icon: Icons.home_rounded,
              text: "Home",
              onTap: () => Navigator.popAndPushNamed(context, PageRoutes.accountPage),
            ),
            BuildListTile(
              icon: Icons.delivery_dining,
              text: "New Deliveries",
              onTap: () => Navigator.popAndPushNamed(context, PageRoutes.newDeliveryTasksPage),
            ),
          BuildListTile(
              icon: Icons.analytics_rounded,
              text: "Insight",
              onTap: () => Navigator.popAndPushNamed(context, PageRoutes.insightPage),
          ),
          BuildListTile(
              icon: Icons.account_balance_wallet_rounded,
              text: "Wallet",
              onTap: () => Navigator.popAndPushNamed(context, PageRoutes.walletPage),
            ),
           
            Divider(
              color: kCardBackgroundColor,
              thickness: 1.0,
            ),
          LogoutTile(),
          ],
        ),
      ),
    );
  }
}

class BuildListTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const BuildListTile({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.transparent,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: kMainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            icon,
            color: kMainColor,
            size: 24.0,
          ),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: kMainTextColor,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: kIconColor,
          size: 16.0,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        hoverColor: kMainColor.withOpacity(0.05),
        splashColor: kMainColor.withOpacity(0.1),
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderMapBloc>(
      create: (context) => OrderMapBloc()..loadMap(),
      child: AccountBody(),
    );
  }
}

class AccountBody extends StatefulWidget {
  @override
  _AccountBodyState createState() => _AccountBodyState();
}

class _AccountBodyState extends State<AccountBody> {
  bool isoffline = false;
  Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? mapStyleController;
  bool _isMapStyleLoading = false;
  String mapStyle = '';

  @override
  void initState() {
    super.initState();
    // Comment out custom map style loading
    /*
    rootBundle.loadString('images/map_style.txt').then((string) {
      if (mounted) {
        setState(() {
      mapStyle = string;
          _isMapStyleLoading = false;
        });
      }
    }).catchError((error) {
       print("Error loading map style: $error. Using default style.");
       if (mounted) {
        setState(() {
          _isMapStyleLoading = false;
        });
      }
    });
    */
    // OrderMapBloc.loadMap() is called by BlocProvider
  }

  @override
  Widget build(BuildContext context) {
    // No need to check _isMapStyleLoading if we are not loading a style
    /*
    if (_isMapStyleLoading) {
      return Scaffold(
        appBar: _buildAppBar(context),
        drawer: Account(),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kMainColor),
          ),
        ),
      );
    }
    */

    return Scaffold(
      appBar: _buildAppBar(context),
      drawer: Account(),
      body: isoffline ? _buildOfflineView() : _buildOnlineView(),
      floatingActionButton: isoffline ? null : _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
        preferredSize: Size.fromHeight(80.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kMainColor, kMainColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kMainColor.withOpacity(0.3),
              blurRadius: 10.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: kWhiteColor),
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isoffline ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isoffline ? Colors.red : Colors.green).withOpacity(0.6),
                        blurRadius: 8.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  isoffline ? "Offline" : "Online",
                  style: TextStyle(
                    color: kWhiteColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: isoffline ? _buildGoOnlineButton() : _buildGoOfflineButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoOnlineButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.online_prediction, size: 18),
      label: Text(
        "Go Online",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: kWhiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            isoffline = false;
                          });
      },
    );
  }

  Widget _buildGoOfflineButton() {
    return ElevatedButton.icon(
      icon: Icon(Icons.offline_pin, size: 18),
      label: Text(
        "Go Offline",
        style: TextStyle(
          fontSize: 12,
                              fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: kWhiteColor,
                          shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onPressed: () {
                          setState(() {
                            isoffline = true;
                          });
      },
    );
  }

  Widget _buildOfflineView() {
    return Stack(
      children: <Widget>[
        _buildGoogleMap(const {}),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.all(20.0),
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
                              color: kWhiteColor,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20.0,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildStatCard("64", "Orders", Icons.shopping_bag_rounded),
                _buildStatCard("68 km", "Ride", Icons.directions_car_rounded),
                _buildStatCard("\$302.50", "Earnings", Icons.attach_money_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineView() {
    // Use BlocBuilder to get markers and update map
    return BlocBuilder<OrderMapBloc, OrderMapState>(
      builder: (context, state) {
        // Animate camera to current location when available from bloc state
        if (state.markers.any((marker) => marker.markerId == MarkerId('currentLocation'))) {
          final currentLocationMarker = state.markers.firstWhere((marker) => marker.markerId == MarkerId('currentLocation'));
          _animateCameraToPosition(currentLocationMarker.position);
        }
        return _buildGoogleMap(state.markers); // Pass markers from state
      },
    );
    // Removed the Stack and Align widgets that contained the stat cards
  }

  Widget _buildGoogleMap(Set<Marker> markers) { // Accept markers as a parameter
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: LatLng(0, 0), // Generic initial position
        zoom: 2.0,            // Zoomed out initially
      ),
      markers: markers, // Use markers from Bloc state
      // style: mapStyle.isNotEmpty ? mapStyle : null, // Do not apply custom style
                    onMapCreated: (GoogleMapController controller) async {
        if (!_mapController.isCompleted) {
                      _mapController.complete(controller);
        }
                      mapStyleController = controller;
      },
    );
  }

  Future<void> _animateCameraToPosition(LatLng position) async {
    if (!_mapController.isCompleted) return;
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 15.0),
    ));
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kMainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: kMainColor,
            size: 24,
          ),
        ),
        SizedBox(height: 8.0),
                            Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kMainTextColor,
          ),
        ),
        SizedBox(height: 4.0),
                            Text(
          label,
          style: TextStyle(
            fontSize: 14,
                                      fontWeight: FontWeight.w500,
            color: kTextColor,
                  ),
                ),
              ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
              backgroundColor: kMainColor,
      foregroundColor: kWhiteColor,
      onPressed: () => Navigator.pushNamed(context, PageRoutes.newDeliveryTasksPage),
      icon: Icon(Icons.list_alt_rounded),
      label: Text(
        "Orders",
        style: TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
            ),
    );
  }
}

class LogoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(
            Icons.logout_rounded,
            color: Colors.red,
            size: 24.0,
          ),
        ),
        title: Text(
          "Logout",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: Colors.red,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.red.withOpacity(0.7),
          size: 16.0,
        ),
      onTap: () {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      "Logging Out",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kMainTextColor,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(color: kTextColor),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: kTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: kWhiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Logout",
                      style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        Phoenix.rebirth(context);
                    },
                  ),
                ],
              );
            },
          );
      },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
    );
  }
}

class UserDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.0),
        child: Row(
          children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kWhiteColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10.0,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 35.0,
              backgroundColor: kWhiteColor,
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: kMainColor,
              ),
            ),
          ),
          SizedBox(width: 16.0),
          Expanded(
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, PageRoutes.editProfile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'George Anderson',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kWhiteColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kWhiteColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: kWhiteColor, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 12,
                            color: kWhiteColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),
          ],
      ),
    );
  }
}