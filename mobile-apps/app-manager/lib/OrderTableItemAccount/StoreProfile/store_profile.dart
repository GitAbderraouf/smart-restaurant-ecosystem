import 'package:flutter/material.dart';
import 'package:hungerz_store/Components/bottom_bar.dart';
import 'package:hungerz_store/Components/textfield.dart';

import 'package:hungerz_store/Routes/routes.dart';
import 'package:hungerz_store/Themes/colors.dart';

class ProfilePage extends StatelessWidget {
  static const String id = 'register_page';
  final String? phoneNumber;

  ProfilePage({this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            size: 30,
            color: Theme.of(context).secondaryHeaderColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Edit Profile",
          style: TextStyle(fontSize: 16.7, fontWeight: FontWeight.bold),
        ),
      ),

      //this column contains 3 textFields and a bottom bar
      body: RegisterForm(phoneNumber),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final String? phoneNumber;

  RegisterForm(this.phoneNumber);

  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  TimeOfDay? openingTime;
  TimeOfDay? closingTime;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(bottom: 70),
          children: <Widget>[
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      "FEATURE IMAGE",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.67,
                          color: kHintColor),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        height: 99.0,
                        width: 99.0,
                        child: Image.asset('images/Layer 1.png'),
                      ),
                      SizedBox(width: 24.0),
                      Icon(
                        Icons.camera_alt,
                        color: kMainColor,
                        size: 25.0,
                      ),
                      SizedBox(width: 14.3),
                      Text("Upload Photo",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: kMainColor)),
                    ],
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    "PROFILE INFO",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.67,
                        color: kHintColor),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                //name textField
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SmallTextFormField(
                      "RESTAURANT NAME",
                      "Enter Restaurant Name",
                      null,
                      "Food Junction"),
                ),
                //category textField
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SmallTextFormField(
                      "CATEGORY",
                      "Select Category",
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.black,
                      ),
                      "Fast Food, Italian, Chinese"),
                ),
                //phone textField
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SmallTextFormField(
                    "PHONE NUMBER",
                    "Enter Phone Number",
                    null,
                    '+1 987 654 3210',
                  ),
                ),
                //email textField
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: SmallTextFormField(
                    "EMAIL ADDRESS",
                    'Enter Email Address',
                    null,
                    'storename@email.com',
                  ),
                ),
              ],
            ),
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    "RESTAURANT ADDRESS",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.67,
                        color: kHintColor),
                  ),
                ),
                //address textField
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, PageRoutes.locationPage),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Column(
                        children: [
                          TextFormField(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(color: Colors.black, fontSize: 14),
                            initialValue:
                                " 1124, Veggy Garden, City Food Park, United States",
                            decoration: InputDecoration(
                                prefix: GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                      context, PageRoutes.locationPage),
                                  child: Icon(
                                    Icons.location_on,
                                    color: kMainColor,
                                    size: 17,
                                  ),
                                ),
                                isDense: true,
                                prefixStyle: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                        color: Colors.black, fontSize: 12),
                                border: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                hintText: "Set Restaurant",
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        color: Colors.grey, fontSize: 14)),
                          ),
                          SizedBox(
                            height: 15,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    "STORE TIMINGS",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.67,
                        color: kHintColor),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: SmallTextFormField(
                          "OPENING TIME",
                          "Set Time",
                          null,
                          openingTime?.format(context) ?? "Set Time",
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Expanded(
                        child: SmallTextFormField(
                          "CLOSING TIME",
                          "Set Time",
                          null,
                          closingTime?.format(context) ?? "Set Time",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Text(
                    "ORDER COLOR SETTINGS",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.67,
                        color: kHintColor),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "COLOR",
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(fontSize: 12),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.green,
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text(
                                    "Green",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: 15),
                                  )
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              )
                            ],
                          )),
                          SizedBox(
                            width: 30.0,
                          ),
                          Expanded(
                            child: SmallTextFormField(
                              "SET TIMING",
                              "Set Time",
                              Icon(
                                Icons.alarm,
                                color: kMainColor,
                                size: 15,
                              ),
                              '3:00 min',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.yellow,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text(
                                      "Yellow",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )),
                          SizedBox(
                            width: 30.0,
                          ),
                          Expanded(
                            child: SmallTextFormField(
                              // label: "SET TIMING",
                              null,
                              "Set Time",
                              Icon(
                                Icons.alarm,
                                color: kMainColor,
                                size: 15,
                              ),
                              '5:30 min',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                    ),
                                    SizedBox(
                                      width: 20,
                                    ),
                                    Text(
                                      "Red",
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )),
                          SizedBox(
                            width: 30.0,
                          ),
                          Expanded(
                            child: SmallTextFormField(
                              // label: "SET TIMING",
                              null,
                              "Set Time",
                              Icon(
                                Icons.alarm,
                                color: kMainColor,
                                size: 15,
                              ),
                              '8:30 min',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
            //continue button bar
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomBar(
              text: "Update Info",
              onTap: () {
                Navigator.pushNamed(context, PageRoutes.accountPage);
              }),
        ),
      ],
    );
  }
}
