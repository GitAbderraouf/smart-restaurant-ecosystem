import 'package:flutter/material.dart';
import 'package:hungerz_delivery/Components/bottom_bar.dart';
import 'package:hungerz_delivery/Routes/routes.dart';
import 'package:hungerz_delivery/Themes/colors.dart';

class DeliverySuccessful extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Spacer(),
          Expanded(
            flex: 3,
            child: Image.asset(
              'images/delivery done.png',
              // height: 236.7,
              // width: 210.7,
            ),
          ),
          Text(
            "Delivered Successfully!", // AppLocalizations.of(context)!.delivered!,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 20, color: Theme.of(context).secondaryHeaderColor, letterSpacing: 0.1),
          ),
          Text(
            "\nThank you for deliver safely & on time.", // AppLocalizations.of(context)!.thankYou!,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Theme.of(context).secondaryHeaderColor,fontWeight: FontWeight.normal),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 31.0, right: 31.0),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "You drived", // AppLocalizations.of(context)!.youDrived!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Color(0xff818181)),
                    ),
                    SizedBox(height: 5.0,),
                    Text(
                      '18 min (6.5 km)',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 5.0,),
                    Text(
                      "View Order Info", // AppLocalizations.of(context)!.viewOrderInfo!,
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: kMainColor,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.08),
                    ),
                  ],
                ),
                Spacer(
                  flex: 1,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Your Earnings", // AppLocalizations.of(context)!.yourEarnings!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Color(0xff818181)),
                    ),
                    SizedBox(height: 5.0,),
                    Text(
                      '\$ 4.50',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 5.0,),
                    Text(
                      "View Earnings", // AppLocalizations.of(context)!.viewEarnings!,
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: kMainColor,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.08),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Spacer(
            flex: 1,
          ),
          BottomBar(
            text: "Back to Home", // AppLocalizations.of(context)!.backToHome,
            onTap: () =>
                Navigator.popAndPushNamed(context, PageRoutes.accountPage),
          )
        ],
      ),
    );
  }
}
