import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/Auth/MobileNumber/UI/mobile_input.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart';
import 'package:hungerz/Auth/login_navigator.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/theme_cubit.dart';

//first page that takes phone number as input for verification
class PhoneNumber extends StatefulWidget {
  static const String id = 'phone_number';

  const PhoneNumber({super.key});

  @override
  _PhoneNumberState createState() => _PhoneNumberState();
}

class _PhoneNumberState extends State<PhoneNumber> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          //used for scrolling when keyboard pops up
          child: Container(
            color: Theme.of(context).cardColor,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Spacer(),
                Expanded(
                  flex: 3,
                  child: FadedScaleAnimation(
                    fadeDuration: Duration(milliseconds: 300),
                    child: Image.asset(
                      BlocProvider.of<ThemeCubit>(context).isDark
                          ? "images/logo_dark.png"
                          : "images/logo_light.png",
                    ),
                  ),
                ),
                Spacer(),
                Expanded(
                  flex: 3,
                  child: Image.asset(
                    "images/signin hero.png", //footer image
                  ),
                ),
                MobileInput(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 32.0,
                    color: Theme.of(context).cardColor,
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.or!,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 15, color: Colors.blueGrey[800]),
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      Navigator.pushNamed(context, LoginRoutes.socialLogin),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    color: Color(0xff3a559f),
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.23,
                        ),
                        Image.asset(
                          'images/ic_login_facebook.png',
                          height: 19.0,
                          width: 19.7,
                        ),
                        SizedBox(
                          width: 34.0,
                        ),
                        Text(AppLocalizations.of(context)!.continueWith!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: kWhiteColor)),
                        Text(AppLocalizations.of(context)!.facebook!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.bold)),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    context.read<AuthCubit>().signInWithGoogle();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    color: kWhiteColor,
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.23,
                        ),
                        Image.asset('images/ic_login_google.png',
                            height: 19.0, width: 19.7),
                        SizedBox(
                          width: 34.0,
                        ),
                        Text(
                          AppLocalizations.of(context)!.continueWith!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: kMainTextColor),
                        ),
                        Text(AppLocalizations.of(context)!.google!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: kMainTextColor)),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, LoginRoutes.socialLogin);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 50.0,
                    color: Color(0xff000000),
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.23,
                        ),
                        Image.asset('images/ic_login_apple.png',
                            height: 19.0, width: 19.7),
                        SizedBox(
                          width: 34.0,
                        ),
                        Text(AppLocalizations.of(context)!.continueWith!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: kWhiteColor)),
                        Text(AppLocalizations.of(context)!.apple!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.bold)),
                        Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
