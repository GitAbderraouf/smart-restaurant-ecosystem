import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Auth/login_navigator.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Components/textfield.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/Locale/locales.dart';

//register page for registration of a new user
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
          AppLocalizations.of(context)!.register!,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 20),
        ),
      ),

      //this column contains 3 textFields and a bottom bar
      body: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: RegisterForm(),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

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
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Divider(
                  color: Theme.of(context).cardColor,
                  thickness: 8.0,
                ),
                SizedBox(
                  height: 25,
                ),
                inputField(
                    AppLocalizations.of(context)!.fullName!.toUpperCase(),
                    'chway za3im rghaya',
                    'images/icons/ic_name.png'),
                //name textField
                //email textField
                inputField(
                  //controller: _emailController,
                  AppLocalizations.of(context)!.emailAddress!.toUpperCase(),
                  'chawayza3imrghaya@mail.com',
                  'images/icons/ic_mail.png',
                ),

                //phone textField
                inputField(
                  AppLocalizations.of(context)!.mobileNumber!.toUpperCase(),
                  '+1 987 654 3210',
                  'images/icons/ic_phone.png',
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 80),
                  child: Text(
                    AppLocalizations.of(context)!.verificationText!,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 12.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        //continue button bar
        Align(
          alignment: Alignment.bottomCenter,
          child: BottomBar(
              text: AppLocalizations.of(context)!.continueText,
              onTap: () {
                Navigator.pushNamed(context, LoginRoutes.verification);
              }),
        )
      ],
    );
  }

  Container inputField(String title, String hint, String img) {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 20,
                child: Image(
                  image: AssetImage(
                    img,
                  ),
                  color: kMainColor,
                ),
              ),
              SizedBox(
                width: 13,
              ),
              Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12))
            ],
          ),
          Container(
            padding: EdgeInsets.only(left: 33),
            child: Column(
              children: [
                SmallTextFormField(null, hint),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
