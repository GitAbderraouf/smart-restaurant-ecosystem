import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Components/textfield.dart';

import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Themes/colors.dart';

class RateNow extends StatefulWidget {
  const RateNow({super.key});

  @override
  _RateNowState createState() => _RateNowState();
}

class _RateNowState extends State<RateNow> {
  final TextEditingController _controller = TextEditingController();
  double? rating;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 15.0),
          child: AppBar(
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
            centerTitle: true,
            title: Text(AppLocalizations.of(context)!.rate!,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .copyWith(color: kMainTextColor)),
          ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Stack(
          children: [
            ListView(
              children: [
                Text(
                  AppLocalizations.of(context)!.how!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  AppLocalizations.of(context)!.withR!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: FadedScaleAnimation(
                    fadeDuration: Duration(milliseconds: 800),
                    child: Image.asset(
                      'images/Restaurants/Layer 1.png',
                      height: 83.3,
                      width: 83.3,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.store!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium!
                      .copyWith(fontWeight: FontWeight.bold, fontSize: 15.0),
                ),
                SizedBox(
                  height: 8.0,
                ),
                Text(
                  AppLocalizations.of(context)!.type!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 10.0, color: Color(0xff888888)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 44.0),
                  child: Center(
                    child: RatingBar.builder(
                      minRating: 1,
                      itemCount: 5,
                      glowColor: kTransparentColor,
                      unratedColor: Color(0xffe6e6e6),
                      onRatingUpdate: (value) {
                        rating = value;
                      },
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: kMainColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.addReview!.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 11.0,
                          color: Color(0xff838383),
                          letterSpacing: 0.5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: EntryField(
                    null,
                    AppLocalizations.of(context)!.writeReview,
                  ),
                ),
                SizedBox(
                  height: 80,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomBar(
                  onTap: () => Navigator.pop(context),
                  text: AppLocalizations.of(context)!.feedback),
            )
          ],
        ),
      ),
    );
  }
}
