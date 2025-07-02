import 'package:flutter/material.dart';
import 'package:hungerz_delivery/Auth/login_navigator.dart';
import 'package:hungerz_delivery/Components/bottom_bar.dart';
import 'package:hungerz_delivery/Components/entry_field.dart';

//register page for registration of a new user
class RegisterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          "Register",
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 16.7),
        ),
      ),

      //this column contains 3 textFields and a bottom bar
      body: RegisterForm(),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // RegisterBloc _registerBloc;

  @override
  void initState() {
    super.initState();
    // _registerBloc = BlocProvider.of<RegisterBloc>(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        ListView(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          children: <Widget>[
            Divider(
              color: Theme.of(context).cardColor,
              thickness: 8.0,
            ),
            //name textField
            EntryField(
              textCapitalization: TextCapitalization.words,
              // controller: _nameController,
              label: "FULL NAME",
              image: 'images/icons/ic_name.png',
              initialValue: 'George Anderson',
            ),
            //email textField
            EntryField(
              textCapitalization: TextCapitalization.none,
              //controller: _emailController,
              label: "EMAIL ADDRESS",
              image: 'images/icons/ic_mail.png',
              keyboardType: TextInputType.emailAddress,
              initialValue: 'deliveryman@mail.com',
            ),

            //phone textField
            EntryField(
              label: "MOBILE NUMBER",
              image: 'images/icons/ic_phone.png',
              keyboardType: TextInputType.number,
              initialValue: '+1 987 654 3210',
            ),

            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                "We\'ll send verification code on above given number.",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontSize: 12.8),
              ),
            ),
            SizedBox(
              height: 40,
            ),
          ],
        ),

        //continue button bar
        BottomBar(
            text: "Continue",
            onTap: () {
              Navigator.pushNamed(context, LoginRoutes.verification);
            })
      ],
    );
  }
}
