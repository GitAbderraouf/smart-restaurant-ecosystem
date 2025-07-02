import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Routes/routes.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/Themes/style.dart';

class Address {
  final String icon;
  final String? addressType;
  final String address;

  Address(this.icon, this.addressType, this.address);
}

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          titleSpacing: 0,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              size: 30,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            AppLocalizations.of(context)!.saved!,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        body: SavedAddresses());
  }
}

class SavedAddresses extends StatefulWidget {
  const SavedAddresses({super.key});

  @override
  _SavedAddressesState createState() => _SavedAddressesState();
}

class _SavedAddressesState extends State<SavedAddresses> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Address> listOfAddressTypes = [
      Address(
          'images/address/ic_homeadd.png',
          AppLocalizations.of(context)!.homeText,
          'baba hassen,\nKertala'),
      Address(
          'images/address/ic_office.png',
          AppLocalizations.of(context)!.office,
          'baba hassen,\nKertala'),
      Address(
          'images/address/ic_other.png',
          AppLocalizations.of(context)!.other,
          'baba hassen,\nKertala'),
    ];
    return FadedSlideAnimation(
      beginOffset: Offset(0.0, 0.3),
      endOffset: Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
              child: ListView.builder(
                  itemCount: 3,
                  itemBuilder: (BuildContext context, int index) {
                    return Column(
                      children: <Widget>[
                        SizedBox(
                          height: 6.7,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 20.0, horizontal: 6.0),
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundColor: Theme.of(context).cardColor,
                              child: FadedScaleAnimation(
                                fadeDuration: Duration(milliseconds: 800),
                                child: Image.asset(
                                  listOfAddressTypes[index].icon,
                                  scale: 2.7,
                                ),
                              ),
                            ),
                            title: Padding(
                              padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                              child: Text(
                                listOfAddressTypes[index].addressType!,
                                style: listTitleTextStyle,
                              ),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                listOfAddressTypes[index].address,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(fontSize: 11.7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  })),
          BottomBar(
            color: Theme.of(context).scaffoldBackgroundColor,
            text: '+ ${AppLocalizations.of(context)!.addNew!}',
            textColor: kMainColor,
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.locationPage);
            },
          ),
        ],
      ),
    );
  }
}
