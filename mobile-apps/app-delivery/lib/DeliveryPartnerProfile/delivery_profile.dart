import 'package:flutter/material.dart';
import 'package:hungerz_delivery/Components/bottom_bar.dart';
import 'package:hungerz_delivery/Components/entry_field.dart';
import 'package:hungerz_delivery/Routes/routes.dart';
import 'package:hungerz_delivery/Themes/colors.dart';

class ProfilePage extends StatelessWidget {
  final String? phoneNumber;

  ProfilePage({this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "Edit Profile",
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .copyWith(fontWeight: FontWeight.w500),
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
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Divider(
                color: Theme.of(context).cardColor,
                thickness: 8.0,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0,vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "FEATURE IMAGE",
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontWeight: FontWeight.w500,
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
                          //color: Theme.of(context).cardColor,
                          child: Image.asset('images/profile.jpg'),
                        ),
                        SizedBox(width: 24.0),
                        Icon(
                          Icons.camera_alt,
                          color: kMainColor,
                          size: 19.0,
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
                    padding: EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
                    child: Text(
                      "PROFILE INFO",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.67,
                          color: kHintColor),
                    ),
                  ),
                  //name textField
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: EntryField(
                      textCapitalization: TextCapitalization.words,
                      label: "FULL NAME",
                      initialValue: 'George Anderson',
                    ),
                  ),
                  //category textField
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: EntryField(
                      textCapitalization: TextCapitalization.words,
                      label: "GENDER",
                      initialValue: 'MALE',
                      readOnly: true,
                      suffixIcon: Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                  //phone textField
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: EntryField(
                      label: "MOBILE NUMBER",
                      initialValue: '+1 987 654 3210',
                      readOnly: true,
                    ),
                  ),
                  //email textField
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: EntryField(
                      textCapitalization: TextCapitalization.none,
                      label: "EMAIL ADDRESS",
                      initialValue: 'deliveryman@email.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  SizedBox(height: 10.0,),
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
                    padding: const EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
                    child: Text(
                      "DOCUMENTATION",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.67,
                          color: kHintColor),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListTile(
                      leading: Image.asset(
                        'images/icons/id1.png',
                        height: 16.0,
                        color: kMainColor,
                      ),
                      title: Text(
                        "GOVERNMENT ID",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                            fontSize: 10.0, color: Color(0xff838383)),
                      ),
                      subtitle: Text(
                        'myvoterid.jpg',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Text(
                        "UPLOAD",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(
                            color: Color(0xff76d13a),
                            letterSpacing: 0.67,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ListTile(
                      leading: Image.asset('images/icons/id2.png',
                          height: 16.0, color: Color(0xffb7b7b7)),
                      title: Text(
                        "LICENSE",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(
                            fontSize: 10.0, color: Color(0xff838383)),
                      ),
                      subtitle: Text(
                        'Not Uploaded yet',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(color: Color(0xff8f8f8f)),
                      ),
                      trailing: Text(
                        "UPLOAD",
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge!
                            .copyWith(
                            color: Color(0xfffbaf03),
                            letterSpacing: 0.67,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  Container(
                    height: 80.0,
                    color: Theme.of(context).cardColor,
                  ),
                ],
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomBar(
              text: "Update Info",
              onTap: () {
                Navigator.popAndPushNamed(context, PageRoutes.accountPage);
              }),
        )
      ],
    );
  }
}
