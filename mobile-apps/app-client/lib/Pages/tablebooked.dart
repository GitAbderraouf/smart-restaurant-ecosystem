import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/Components/bottom_bar.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/HomeOrderAccount/home_order_account.dart';

class TableBooked extends StatelessWidget {
  const TableBooked({super.key});

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
                  'images/table booked.png',
                ),
              ),
            ),
            Text(
              AppLocalizations.of(context)!.booked!,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .copyWith(fontSize: 23.3),
            ),
            Text(
              AppLocalizations.of(context)!.thankstb!,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: kDisabledColor),
            ),
            Spacer(),
            BottomBar(
              text: AppLocalizations.of(context)!.orderTextt,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeOrderAccount(index:1),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
