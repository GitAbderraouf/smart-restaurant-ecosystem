import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Routes/routes.dart';
import 'package:hungerz/Themes/colors.dart';

class OrderPlaced extends StatelessWidget {
  const OrderPlaced({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Column(
          children: <Widget>[
            Spacer(),
            Expanded(
              flex: 3,
              child: FadedScaleAnimation(
                fadeDuration: Duration(milliseconds: 800),
                child: Image.asset(
                  'images/order_placed.png',
                ),
              ),
            ),
            Spacer(),
            Text(
              AppLocalizations.of(context)!.placed!,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 23.3),
            ),
            Text(
              AppLocalizations.of(context)!.thanks!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: kDisabledColor, fontSize: 18),
            ),
            Spacer(
                // flex: 2,
                ),
            BottomBar(
              text: AppLocalizations.of(context)!.orderText,
              onTap: () => Navigator.pushNamed(context, PageRoutes.orderPage),
            )
          ],
        ),
      ),
    );
  }
}
