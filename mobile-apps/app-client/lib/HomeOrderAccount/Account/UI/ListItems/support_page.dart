import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Components/textfield.dart';
import 'package:hungerz/Themes/colors.dart';

import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/theme_cubit.dart';

class SupportPage extends StatelessWidget {
  static const String id = 'support_page';
  final String? number;

  const SupportPage({super.key, this.number});

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
        title: Text(AppLocalizations.of(context)!.support!,
            style: Theme.of(context).textTheme.bodyLarge),
      ),
      body: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height + 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      color: Theme.of(context).cardColor,
                      child: FadedScaleAnimation(
                        fadeDuration: Duration(milliseconds: 800),
                        child: Image(
                          image: AssetImage(
                              BlocProvider.of<ThemeCubit>(context).isDark
                                  ? "images/logo_dark.png"
                                  : "images/logo_light.png"),
                          height: 130.0,
                          width: 99.7,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 24.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(left: 8.0, top: 16.0),
                            child: Text(
                              AppLocalizations.of(context)!.orWrite!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          SizedBox(height: 10.0),
                          Padding(
                            padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
                            child: Text(
                              AppLocalizations.of(context)!.yourWords!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Column(
                              children: [
                                inputField(
                                  AppLocalizations.of(context)!.mobileNumber!,
                                  '+1 987 654 3210',
                                  'images/icons/ic_phone.png',
                                ),
                                inputField(
                                  AppLocalizations.of(context)!.message!,
                                  AppLocalizations.of(context)!.enterMessage,
                                  'images/icons/ic_mail.png',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    BottomBar(
                      text: AppLocalizations.of(context)!.submit,
                      onTap: () {
                        /*............*/
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Container inputField(String title, String? hint, String img) {
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
